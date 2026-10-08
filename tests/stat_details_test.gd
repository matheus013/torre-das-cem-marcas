extends SceneTree

## Decisão 589: atributos mostram o bônus do equipamento entre parênteses; status detalhados
## separam base, equipamento, total e efetivo; modificadores de maestria e suportes mostram uma
## prévia do que mudam na gema, com números já escalados pela personagem.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Menu := preload("res://src/prototype/village/player_menu.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(5890)
	sim.add_player(1, &"eloa")
	var build := sim.character_build(1)
	build.base_stats[&"intelligence"] = 60.0
	build.base_stats[&"fortune"] = 40.0
	var crown := sim._add_equipment_instance(&"eloa", "lendario_coroa_de_brasa", "regular", 1)
	(sim._gear(1)["inventory"] as ItemInventory).get_item(crown).affixes.clear()
	sim.equip_item(1, crown)
	var model := sim.menu_model(1)
	# Coroa de Brasa dá Inteligência 10 (nível 1, fabricação regular).
	if int(model["stats"]["intelligence"]) != 60 or int(model["stat_bonus"]["intelligence"]) < 10:
		return _fail("Stats must show points and the equipment bonus apart: %s / %s" % [model["stats"], model["stat_bonus"]])
	var details := model["detailed_stats"] as Dictionary
	var intelligence := (details["attributes"] as Array).filter(func(row: Dictionary) -> bool: return row["stat"] == "intelligence")[0] as Dictionary
	if not is_equal_approx(float(intelligence["base"]) + float(intelligence["equipment"]), float(intelligence["total"])) or float(intelligence["base"]) != 60.0:
		return _fail("Detailed attributes must split base, equipment and total")
	var fire := (details["damage"] as Array).filter(func(row: Array) -> bool: return row[0] == "Fogo")[0] as Array
	if String(fire[1]) != "+40%":
		return _fail("Damage bonuses must include item passives (Coroa de Brasa fire +40%%), got %s" % fire[1])

	# Prévias: nível 5 do Elo Residual oferece modificadores; cada um diz o que muda.
	for level in range(1, 5):
		sim.gain_gem_experience(1, "elo_residual", sim.gem_experience_required(level))
	var skill := (sim.menu_model(1)["skills"] as Array)[0] as Dictionary
	var previews := (skill["pending_choices"] as Array).map(func(choice: Dictionary) -> String: return String(choice["preview"]))
	if previews.any(func(text: String) -> bool: return text.contains("sem mudanca")):
		return _fail("Every mastery option must preview a change: %s" % [previews])
	var power_choice := (skill["pending_choices"] as Array).filter(func(choice: Dictionary) -> bool: return (choice["modifiers"] as Dictionary).has("power_multiplier"))
	if power_choice.is_empty() or not String(power_choice[0]["preview"]).begins_with("Dano %d -> %d (+20%%)" % [roundi(float(skill["power"])), roundi(float(skill["power"]) * 1.2)]):
		return _fail("Damage preview must use the scaled damage: %s (dano %.0f)" % [power_choice[0]["preview"] if not power_choice.is_empty() else "-", float(skill["power"])])
	var supports := skill["available_supports"] as Array
	if supports.is_empty() or supports.any(func(support: Dictionary) -> bool: return String(support.get("preview", "")).is_empty()):
		return _fail("Every compatible support must carry a preview")

	# Menu: parênteses no atributo e painel detalhado abrindo pelo botão.
	var menu := Menu.new()
	root.add_child(menu)
	await process_frame
	menu.refresh(sim.menu_model(1))
	menu.open("character")
	await process_frame
	var labels := menu.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
	if not labels.any(func(text: String) -> bool: return text.begins_with("INTELIGENCIA") and text.contains("(+")):
		return _fail("Attribute row must show the equipment bonus in parentheses")
	(menu.find_child("DetailedStatsToggle", true, false) as Button).pressed.emit()
	await process_frame
	if menu.find_child("DetailedAttributes", true, false) == null:
		return _fail("Detailed stats must open from the toggle")
	print("STAT_DETAILS_OK: equipment bonus in parentheses, detailed base/equipment/total/effective, damage bonuses and change previews")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
