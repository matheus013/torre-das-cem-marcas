extends SceneTree

## Decisão 593: bestiário por personagem. Abates revelam, por níveis, identidade, atributos,
## comportamento e defesas, saque com chances e o registro de campo; o grupo na arena aprende junto;
## o progresso fica no save. Também: botão Vender tudo (fora equipados, lendários e armas únicas).

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const MenuScene := preload("res://src/prototype/village/player_menu.gd")
const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")


func _init() -> void:
	_run.call_deferred()


func _entry(sim: WorldSimulation, peer_id: int, enemy_id: String) -> Dictionary:
	for entry: Dictionary in sim.bestiary_model(peer_id)["entries"] as Array:
		if String(entry["id"]) == enemy_id:
			return entry
	return {}


func _kill(sim: WorldSimulation, definition: Dictionary, times: int) -> void:
	var origin := sim.player(1)["position"] as Vector2
	for index in range(times):
		var enemy := sim.create_enemy(definition, origin + Vector2(60.0, 0.0), index)
		enemy["shield_hits"] = 0
		sim.enemies.append(enemy)
		sim.damage_enemy(1, sim.enemies.size() - 1, 1.0e15, {})


func _titles(entry: Dictionary) -> Array:
	return (entry["sections"] as Array).map(func(section: Dictionary) -> String: return String(section["title"]))


func _rows(entry: Dictionary, title: String) -> Array:
	for section: Dictionary in entry["sections"] as Array:
		if String(section["title"]) == title:
			return section["rows"] as Array
	return []


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(5864)
	sim.add_player(1, &"eloa")
	sim.add_player(2, &"sena")
	sim.enter_tower(1)
	sim.enter_tower(2)
	var model := sim.bestiary_model(1)
	if int(model["total"]) < 40 or int(model["discovered"]) != 0:
		return _fail("Bestiary must list every tower monster, none discovered: %d / %d" % [int(model["discovered"]), int(model["total"])])
	var common_id := ""
	for entry: Dictionary in model["entries"] as Array:
		if String(entry["class"]) == "common" and common_id.is_empty():
			common_id = String(entry["id"])
	var unknown := _entry(sim, 1, common_id)
	if String(unknown["name"]) != "???" or not (unknown["sections"] as Array).is_empty() or int(unknown["next"]) != 1:
		return _fail("Unknown monsters must be hidden: %s" % [unknown])
	var definition := sim.content("enemies").filter(func(item: Dictionary) -> bool: return String(item["id"]) == common_id)[0] as Dictionary

	# Comum: 1, 5, 15, 30 e 60 abates revelam uma seção cada.
	var expected := {1: ["Identidade"], 5: ["Identidade", "Atributos"], 15: ["Identidade", "Atributos", "Comportamento e defesas"],
		30: ["Identidade", "Atributos", "Comportamento e defesas", "Saque"], 60: ["Identidade", "Atributos", "Comportamento e defesas", "Saque", "Registro de campo"]}
	var done := 0
	for target: int in [1, 5, 15, 30, 60]:
		_kill(sim, definition, target - done)
		done = target
		var entry := _entry(sim, 1, common_id)
		if int(entry["kills"]) != target or _titles(entry) != expected[target]:
			return _fail("At %d kills the sections must be %s, got %s" % [target, expected[target], _titles(entry)])
	var known := _entry(sim, 1, common_id)
	if String(known["name"]) != String(definition["name"]) or int(known["level"]) != 5 or int(known["next"]) != -1:
		return _fail("Five levels must reveal the full entry: %s" % [known])
	var stats := _rows(known, "Atributos")
	if not String(stats[0][0]).begins_with("Vida base") or not String(stats[1][1]).contains(" a "):
		return _fail("Stats must show base and observed health: %s" % [stats])
	var loot := _rows(known, "Saque")
	if loot.filter(func(row: Array) -> bool: return String(row[1]).contains("%")).size() < 3:
		return _fail("Loot must list drops with chances: %s" % [loot])
	if not String(_rows(known, "Comportamento e defesas")[0][1]).contains(":"):
		return _fail("Behaviour must describe the monster mechanic")
	if _rows(known, "Registro de campo").is_empty():
		return _fail("Field record must exist at the last level")
	# O grupo inteiro na arena aprende com o abate; outra personagem tem o próprio livro.
	if int(_entry(sim, 2, common_id)["kills"]) != 60:
		return _fail("Allies in the arena must learn from each kill")

	# Chefe: 3 abates revelam as habilidades e as fases.
	var boss: Dictionary = TowerContentScript.collection("bosses")[0]
	var boss_definition := sim.content("enemies").filter(func(item: Dictionary) -> bool: return String(item["id"]) == String(boss["id"]))
	var boss_enemy := (boss_definition[0] as Dictionary).duplicate(true) if not boss_definition.is_empty() else {"id": String(boss["id"])}
	boss_enemy["encounter_class"] = "boss"
	_kill(sim, boss_enemy, 3)
	var boss_entry := _entry(sim, 1, String(boss["id"]))
	var behaviour := _rows(boss_entry, "Comportamento e defesas")
	if int(boss_entry["level"]) != 3 or behaviour.filter(func(row: Array) -> bool: return String(row[0]) == "Habilidade").size() != (boss["abilities"] as Array).size():
		return _fail("Boss knowledge at 3 kills must list every ability: %s" % [boss_entry])

	# Save: o livro volta igual.
	var restored := Simulation.new()
	restored.setup(5864)
	restored.add_player(1, &"eloa")
	if not restored.load_data(sim.save_data(1), 1) or int(_entry(restored, 1, common_id)["kills"]) != 60 or int(_entry(restored, 1, common_id)["level"]) != 5:
		return _fail("Bestiary must survive save and load")

	# Menu: aba com lista e ficha do monstro selecionado.
	var menu := MenuScene.new()
	root.add_child(menu)
	menu.call("refresh", sim.menu_model(1))
	menu.set("_bestiary_selected", common_id)
	menu.call("open", "bestiary")
	await process_frame
	var name_label := menu.find_child("BeastName", true, false) as Label
	if name_label == null or name_label.text != String(definition["name"]) or menu.find_child("Beast_" + common_id, true, false) == null:
		return _fail("Bestiary tab must list monsters and show the selected entry")
	menu.queue_free()

	# Vender tudo: fica o equipado, o lendário e a arma única.
	var shop := Simulation.new()
	shop.setup(5865)
	shop.add_player(1, &"eloa")
	var gear := shop._gear(1)
	var inventory := gear["inventory"] as ItemInventory
	var before := inventory.items.size()
	var keep := [shop._add_equipment_instance(&"eloa", "lendario_coroa_de_brasa"), shop._add_equipment_instance(&"eloa", "unica_agulha_lastro")]
	for item_id in ["filamentos_de_forja", "lanca_de_duas_rotas", "manoplas_de_placa_viva"]:
		shop._add_equipment_instance(&"eloa", item_id)
	var preview := shop.sell_all_preview(1)
	var silver := int(gear["silver"])
	var earned := shop.sell_all(1)
	if earned != int(preview["price"]) or int(gear["silver"]) != silver + earned or int(preview["count"]) < 3:
		return _fail("Sell all must pay the previewed price: %s, earned %d" % [preview, earned])
	for instance_id: StringName in keep:
		if inventory.get_item(instance_id) == null:
			return _fail("Sell all must keep legendaries and unique weapons")
	if inventory.items.size() != before - int(preview["count"]) + 5 or int(shop.sell_all_preview(1)["count"]) != 0:
		return _fail("Sell all left sellable pieces behind")
	var sell_menu := MenuScene.new()
	root.add_child(sell_menu)
	sell_menu.call("refresh", shop.menu_model(1))
	sell_menu.call("open", "inventory")
	await process_frame
	var button := sell_menu.find_child("SellAll", true, false) as Button
	if button == null or not button.disabled:
		return _fail("Sell all button must exist and be disabled with nothing to sell")
	sell_menu.queue_free()
	await process_frame
	print("BESTIARY_OK: 5 knowledge levels by kills, boss abilities, party learning, save; sell all keeps equipped/legendary/unique")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
