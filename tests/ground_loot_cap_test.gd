extends SceneTree

## Regressão de 2026-10-12: um save com mais de 6 mil itens no chão (3 mil abates no mesmo andar)
## derrubava o FPS (35 ms só para montar a visão do quadro). Itens no chão têm limite por andar e
## total; passando, some o de menor raridade e mais antigo, primeiro de outros andares; materiais
## iguais se juntam numa pilha próxima; saves antigos são cortados ao carregar.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _world() -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(6111)
	sim.add_player(1, &"cira")
	sim.enter_tower(1)
	sim.start_floor(10)
	sim.ground_items.clear()
	return sim


func _run() -> void:
	# Materiais iguais perto viram uma pilha só.
	var stack := _world()
	for drop in range(20):
		stack.drop_item(&"tower", Vector2(600.0, 600.0) + Vector2(drop * 5.0, 0.0), "pedra_regenerativa", 1)
	if stack.ground_items.size() != 1 or int(stack.ground_items[0]["quantity"]) != 20:
		return _fail("Nearby materials of the same kind must merge into one stack")

	# Limite por andar: o raro sobrevive a centenas de comuns; nunca passa do teto.
	var floor_cap := _world()
	floor_cap.drop_item(&"tower", Vector2(300.0, 300.0), "anel_de_area", 1)
	for drop in range(Simulation.MAX_GROUND_ITEMS_PER_FLOOR + 200):
		floor_cap.drop_item(&"tower", Vector2(400.0 + (drop % 40) * 30.0, 400.0 + (drop / 40) * 30.0), "protecao_de_trabalho", 1)
	if floor_cap.ground_items.size() > Simulation.MAX_GROUND_ITEMS_PER_FLOOR:
		return _fail("Ground items must stay under the per-floor cap: %d" % floor_cap.ground_items.size())
	if not floor_cap.ground_items.any(func(item: Dictionary) -> bool: return String(item["item_id"]) == "anel_de_area"):
		return _fail("The cap must drop common pieces before a rare one")

	# Limite total: andares deixados para trás perdem itens antes do atual.
	var total := _world()
	for floor_number in [3, 4, 5]:
		total.current_floor = floor_number
		for drop in range(Simulation.MAX_GROUND_ITEMS_PER_FLOOR):
			total.drop_item(&"tower", Vector2(300.0 + (drop % 40) * 30.0, 300.0 + (drop / 40) * 30.0), "protecao_de_trabalho", 1)
	if total.ground_items.size() > Simulation.MAX_GROUND_ITEMS_TOTAL:
		return _fail("Ground items must stay under the total cap")
	if total.ground_items.filter(func(item: Dictionary) -> bool: return int(item["floor"]) == 5).size() != Simulation.MAX_GROUND_ITEMS_PER_FLOOR:
		return _fail("The current floor must keep its items while older floors give way")

	# Saves antigos: milhares de itens são cortados ao carregar, ficando os do andar atual e os raros.
	var source := _world()
	var saved := source.save_data(1)
	var crowded: Array = []
	for index in range(3000):
		crowded.append({"zone": "tower", "floor": 10, "position": [400.0 + (index % 50) * 20.0, 400.0 + (index / 50) * 20.0], "item_id": "protecao_de_trabalho", "quantity": 1, "quality": "regular"})
	crowded.append({"zone": "tower", "floor": 10, "position": [300.0, 300.0], "item_id": "anel_de_area", "quantity": 1, "quality": "regular"})
	for index in range(800):
		crowded.append({"zone": "tower", "floor": 2, "position": [400.0, 400.0 + index], "item_id": "protecao_de_trabalho", "quantity": 1, "quality": "regular"})
	saved["ground_items"] = crowded
	var restored := Simulation.new()
	restored.setup(6111)
	restored.add_player(1, &"cira")
	if not restored.load_data(saved, 1):
		return _fail("The crowded save must load")
	var here := restored.ground_items.filter(func(item: Dictionary) -> bool: return int(item["floor"]) == 10)
	if restored.ground_items.size() > Simulation.MAX_GROUND_ITEMS_TOTAL or here.size() != Simulation.MAX_GROUND_ITEMS_PER_FLOOR or not here.any(func(item: Dictionary) -> bool: return String(item["item_id"]) == "anel_de_area"):
		return _fail("Old saves must be trimmed on load, keeping the current floor and rare pieces: %d total, %d here" % [restored.ground_items.size(), here.size()])
	# Raio de coleta: o que está a 120 px é recolhido sozinho.
	var reach := _world()
	var spot := reach.player(1)["position"] as Vector2
	reach.drop_item(&"tower", spot + Vector2(120.0, 0.0), "pedra_regenerativa", 3)
	reach._collect_ground_items(1)
	if not reach.ground_items.is_empty():
		return _fail("Items inside the collection radius must be picked up")
	# Barrado pelo filtro: vira prata na hora; no co-op fica se um aliado ainda aceita.
	var sell := _world()
	sell._gear(1)["loot_filter"] = "epic"
	var silver := int(sell._gear(1)["silver"])
	sell.drop_item(&"tower", (sell.player(1)["position"] as Vector2) + Vector2(60.0, 0.0), "protecao_de_trabalho", 1, "regular")
	sell._collect_ground_items(1)
	if not sell.ground_items.is_empty() or int(sell._gear(1)["silver"]) <= silver:
		return _fail("Filtered equipment in reach must turn into silver instead of piling up")
	var duo := _world()
	duo.add_player(2, &"eloa")
	duo.enter_tower(2)
	duo._gear(1)["loot_filter"] = "epic"
	duo.player(2)["position"] = Vector2(3000.0, 2000.0)
	duo.drop_item(&"tower", (duo.player(1)["position"] as Vector2) + Vector2(60.0, 0.0), "protecao_de_trabalho", 1, "regular")
	duo._collect_ground_items(1)
	if duo.ground_items.size() != 1:
		return _fail("Filtered items must stay for an ally whose filter accepts them")
	print("GROUND_LOOT_CAP_OK: collection radius, filtered loot sold,  material stacks, per-floor and total caps by rarity and age, old saves trimmed on load")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
