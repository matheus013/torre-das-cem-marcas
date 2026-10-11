extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Menu := preload("res://src/prototype/village/player_menu.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var sim := Simulation.new()
	sim.setup(7342)
	sim.add_player(1, &"eloa")
	var id := sim._add_equipment_instance(&"eloa", "protecao_de_trabalho", "regular", 20)
	var gear := sim._gear(1)
	var item := (gear["inventory"] as ItemInventory).get_item(id)
	item.affixes.clear()
	item.definition.stat_modifiers = {&"health": 80, &"defense": 40, &"attack_speed": 20, &"wisdom": 20}
	sim.player(1)["wounds"] = 2
	var original := sim.save_data(1)
	var random_state := sim._affix_random.state
	var comparison := sim.equipment_comparison(1, id)
	if not comparison.get("can_equip", false) or comparison["rows"].is_empty() or sim.save_data(1) != original or sim._affix_random.state != random_state:
		return _fail("Preview changed state/RNG or lacks real stats")
	if not sim.equipment_comparison(999, id).is_empty() or not sim.equipment_comparison(1, &"unknown").is_empty():
		return _fail("Invalid player/item has a comparison")
	sim.equip_item(1, id)
	var after := sim.derived_stats(1)
	var attack := sim.weapon_attack_model(1)
	for row: Dictionary in comparison["rows"]:
		var actual := 0.0
		if String(row["id"]).begins_with("weapon_"):
			actual = float(attack[String(row["id"]).trim_prefix("weapon_")])
		else:
			actual = sim.max_health(1) if row["id"] == "max_health" else float(after[row["id"]])
		if row["unit"] == "%":
			actual *= 100
		if not is_equal_approx(actual, float(row["after"])):
			return _fail("Preview differs from equipped effect: " + String(row["id"]))
	# Rings preview the same empty/weakest destination as the actual equip action.
	var equipped := gear["equipment"] as EquipmentLoadout
	for index in range(2):
		var ring_id := sim._add_equipment_instance(&"eloa", "anel_de_folego", "regular", 1)
		sim.equip_item(1, ring_id)
	var ring_id := sim._add_equipment_instance(&"eloa", "anel_de_precisao", "regular", 1)
	var ring_preview := sim.equipment_comparison(1, ring_id)
	var replaced: String = ring_preview["replaces_id"]
	sim.equip_item(1, ring_id)
	if equipped.get_equipped(EquipmentItemDefinition.Slot.RING, ring_preview["slot_index"]).instance_id != ring_id or not (gear["inventory"] as ItemInventory).items.has(StringName(replaced)):
		return _fail("Ring replaced a different item than preview")
	var offhand_id := sim._add_equipment_instance(&"eloa", "escudo_de_escora", "regular")
	sim.equip_item(1, offhand_id)
	var weapon_id := sim._add_equipment_instance(&"eloa", "bastao_modular_de_campo", "regular")
	var weapon := (gear["inventory"] as ItemInventory).get_item(weapon_id)
	weapon.definition.two_handed = true
	if sim.equipment_comparison(1, weapon_id).get("can_equip", true):
		return _fail("Two-handed conflict advertised as equipable")
	sim.unequip_item(1, EquipmentItemDefinition.Slot.OFFHAND, 0)
	if not sim.attach_support(1, 4, "projeteis_gemeos"):
		return _fail("Support fixture failed")
	var weapon_preview := sim.equipment_comparison(1, weapon_id)
	if (weapon_preview.get("inactive_supports", []) as Array).size() != 1:
		return _fail("Missing incompatible auto support warning")
	var unique_id := sim._add_equipment_instance(&"eloa", "unica_saraivada_de_flechas", "regular")
	if (sim.equipment_comparison(1, unique_id).get("gained_passives", []) as Array).is_empty():
		return _fail("Missing item passive gain")
	var relic_id := sim._add_equipment_instance(&"eloa", "reliquia_lastro_partido", "regular")
	var relic_preview := sim.equipment_comparison(1, relic_id)
	sim.equip_item(1, relic_id)
	var found_move := false
	for row: Dictionary in relic_preview["rows"]:
		if row["id"] == "movement_speed_multiplier":
			found_move = true
			if not is_equal_approx(float(row["after"]), float(sim.derived_stats(1)["movement_speed_multiplier"]) * 100):
				return _fail("Preview ignored fixed item passive modifier")
	if not found_move:
		return _fail("Passive modifier fixture lacks movement row")
	var menu := Menu.new()
	root.add_child(menu)
	await process_frame
	menu.refresh(sim.menu_model(1))
	menu.open("inventory")
	await process_frame
	var cell := menu.find_child("Item_%s" % weapon_id, true, false) as Control
	cell.grab_focus()
	await process_frame
	var text := menu.find_child("EquipmentComparison", true, false) as RichTextLabel
	if not text.text.contains("Substitui:") or not text.text.contains("ficara inativo"):
		return _fail("Controller focus does not show comparison")
	print("EQUIPMENT_COMPARISON_OK: mutation-free preview, exact equipped values, wounds, ring destination, conflicts, passives, auto supports and focus")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
