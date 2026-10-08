extends SceneTree

## Regressão (2026-10-08): equipamento recolhido virava peça na mochila e também entrava na carga da
## expedição; na volta, essa cópia chegava ao armazém da vila como equipamento fantasma. Agora só
## materiais vão para carga e armazém, e saves antigos perdem os contadores de equipamento.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(5867)
	sim.add_player(1, &"eloa")
	sim.enter_tower(1)
	sim.enemies.clear()
	var state := sim.player(1)
	var inventory := sim._gear(1)["inventory"] as ItemInventory
	var before := inventory.items.size()
	sim.drop_item(&"tower", state["position"] as Vector2, "lanca_de_duas_rotas", 1, "regular")
	sim.drop_item(&"tower", state["position"] as Vector2, "pedra_regenerativa", 2)
	for _frame in range(5):
		sim.step(1.0 / 30.0)
	var carried := state["carried_loot"] as Dictionary
	if inventory.items.size() != before + 1 or carried.has("lanca_de_duas_rotas") or int(carried.get("pedra_regenerativa", 0)) != 2:
		return _fail("Equipment must go only to the backpack and materials to the load: %s" % [carried])
	sim.leave_tower(1)
	if sim.banked_loot.has("lanca_de_duas_rotas") or int(sim.banked_loot.get("pedra_regenerativa", 0)) != 2:
		return _fail("The village storage must receive only materials: %s" % [sim.banked_loot])
	var data := sim.save_data(1)
	(data["banked_loot"] as Dictionary)["lanca_de_duas_rotas"] = 3
	(data["carried_loot"] as Dictionary)["manoplas_de_placa_viva"] = 1
	var restored := Simulation.new()
	restored.setup(5867)
	restored.add_player(1, &"eloa")
	if not restored.load_data(data, 1) or restored.banked_loot.has("lanca_de_duas_rotas") or (restored.player(1)["carried_loot"] as Dictionary).has("manoplas_de_placa_viva") or int(restored.banked_loot.get("pedra_regenerativa", 0)) != 2:
		return _fail("Old saves must drop phantom equipment from storage and load: %s" % [restored.banked_loot])
	print("WAREHOUSE_EQUIPMENT_OK: equipment only in the backpack; storage and load keep materials")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
