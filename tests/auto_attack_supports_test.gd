extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Auto := preload("res://src/gameplay/equipment/auto_attack_supports.gd")
const Menu := preload("res://src/prototype/village/player_menu.gd")


func _init() -> void:
	_run.call_deferred()
	create_timer(20.0).timeout.connect(func() -> void: _fail("Auto support test timed out"))


func _world(character := &"eloa") -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(9127)
	sim.add_player(1, character)
	return sim


func _prepare(sim: WorldSimulation) -> void:
	sim.enter_tower(1)
	sim.enemies.clear()
	var state := sim.player(1)
	state["position"] = Vector2(600, 400)
	state["target"] = state["position"]
	state["health"] = 20.0
	state["breath"] = 10.0
	state["attack_timer"] = 0.0
	for position in [Vector2(680, 400), Vector2(740, 400), Vector2(800, 400)]:
		var enemy := sim.create_enemy({"id":"auto_probe", "health":10000, "damage":0, "rank_id":"maduro", "allow_affixes":false}, position, sim.enemies.size() + 1)
		enemy["health"] = 10000.0
		enemy["shield_hits"] = 0
		enemy["race_trait"] = ""
		sim.enemies.append(enemy)


func _run() -> void:
	var sim := _world()
	var baseline := sim.weapon_attack_model(1)
	if not sim.attach_support(1, Auto.SLOT, "drenagem_vital") or not sim.attach_support(1, Auto.SLOT, "sifao_de_folego"):
		return _fail("Life and breath recovery could not be attached")
	if sim.attach_support(1, Auto.SLOT, "potencia_bruta") or sim.attach_support(1, Auto.SLOT, "drenagem_vital"):
		return _fail("Auto slot accepted a third or duplicate support")
	var resolved := sim.weapon_attack_model(1)
	if not is_equal_approx(float(resolved["damage"]), float(baseline["damage"]) * 0.9 * 0.85):
		return _fail("Support damage tradeoffs did not affect the weapon")
	_prepare(sim)
	if sim.detach_support(1, Auto.SLOT, "drenagem_vital") or sim.attach_support(1, Auto.SLOT, "potencia_bruta"):
		return _fail("Auto supports changed inside the Tower")
	sim._step_player(1, 0.0)
	if float(sim.player(1)["health"]) <= 20.0 or float(sim.player(1)["breath"]) != 12.0:
		return _fail("Automatic hit did not recover health and breath")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(sim.save_data(1)))
	var restored := _world()
	if not restored.load_data(saved, 1) or restored._gem_state(1)["auto_supports"] != sim._gem_state(1)["auto_supports"]:
		return _fail("Auto supports did not survive JSON reload")
	var legacy := saved.duplicate(true)
	for key: String in legacy["character_gems"]:
		legacy["character_gems"][key].erase("auto_supports")
	if not restored.load_data(legacy, 1) or not (restored._gem_state(1)["auto_supports"] as Array).is_empty():
		return _fail("Older save did not migrate to empty auto supports")
	var moved := _world()
	if not moved.attach_support(1, 0, "sifao_de_folego") or not moved.attach_support(1, Auto.SLOT, "sifao_de_folego") or moved._gem_state(1)["supports"][0].has("sifao_de_folego"):
		return _fail("Transfer duplicated support ownership")
	if not moved.attach_support(1, 0, "sifao_de_folego") or moved._gem_state(1)["auto_supports"].has("sifao_de_folego"):
		return _fail("Transfer back to an active skill duplicated ownership")
	var switched := _world()
	if not switched.attach_support(1, Auto.SLOT, "projeteis_gemeos"):
		return _fail("Weapon-switch fixture could not attach support")
	var melee_id := switched._add_equipment_instance(&"eloa", String(Simulation.STARTER_WEAPONS[&"cira"]))
	switched._equip(&"eloa", melee_id)
	if int(switched.weapon_attack_model(1).get("projectile_count", 0)) != 0 or bool(switched.menu_model(1)["auto_attack_supports"]["supports"][0]["active"]):
		return _fail("Incompatible support remained active after switching weapons")
	var focus_id := switched._add_equipment_instance(&"eloa", String(Simulation.STARTER_WEAPONS[&"eloa"]))
	switched._equip(&"eloa", focus_id)
	if int(switched.weapon_attack_model(1).get("projectile_count", 0)) != 1:
		return _fail("Stored support did not reactivate with compatible weapon")
	for id in ["projeteis_gemeos", "ricochete_de_junta", "perfuracao_refeita", "retorno_vetorial", "bifurcacao_residual", "explosao_de_contato"]:
		var ranged := _world()
		if not ranged.attach_support(1, Auto.SLOT, id):
			return _fail("Projectile support rejected: " + id)
		_prepare(ranged)
		ranged._step_player(1, 0.0)
		if float(ranged.enemies[0]["health"]) >= 10000.0:
			return _fail("Supported projectile did not deal damage: " + id)
		if id == "ricochete_de_junta" and float(ranged.enemies[2]["health"]) >= 10000.0:
			return _fail("Ricochet did not reach additional enemies")
	for character in [&"sena", &"cira", &"rui"]:
		var melee := _world(character)
		if melee.attach_support(1, Auto.SLOT, "projeteis_gemeos") or melee.attach_support(1, Auto.SLOT, "ricochete_de_junta") or not melee.attach_support(1, Auto.SLOT, "precisao_lapidada"):
			return _fail("Melee weapon compatibility incorrect")
		if character != &"cira":
			var before := melee.weapon_attack_model(1)
			if not melee.attach_support(1, Auto.SLOT, "area_expandida"):
				return _fail("Area support rejected on area weapon")
			var after := melee.weapon_attack_model(1)
			var field := "width" if character == &"sena" else "range"
			if not is_equal_approx(float(after[field]), float(before[field]) * 1.3):
				return _fail("Area support changed no geometry")
	var costly := _world()
	if not costly.attach_support(1, Auto.SLOT, "sobrecarga_instavel"):
		return _fail("Overload rejected")
	_prepare(costly)
	costly._step_player(1, 0.0)
	if float(costly.enemies[0]["health"]) != 10000.0 or float(costly.player(1)["breath"]) != 10.0:
		return _fail("Insufficient breath still fired the auto attack")
	costly.player(1)["breath"] = 30.0
	costly._step_player(1, 0.0)
	if float(costly.player(1)["breath"]) != 18.0 or not is_equal_approx(float(costly.player(1)["attack_timer"]), float(costly.weapon_attack_model(1)["interval"])):
		return _fail("Overload cost or attack cadence incorrect")
	var menu := Menu.new()
	var removed: Array = []
	menu.support_detach_requested.connect(func(slot: int, id: String) -> void: removed.assign([slot, id]))
	root.add_child(menu)
	await process_frame
	sim.leave_tower(1)
	menu.refresh(sim.menu_model(1))
	menu.open("skills")
	await process_frame
	for button: Node in menu.find_children("*", "Button", true, false):
		if String(button.get("text")).begins_with("Drenagem Vital"):
			button.emit_signal("pressed")
	if removed != [Auto.SLOT, "drenagem_vital"]:
		return _fail("Auto support removal emitted the wrong slot")
	if "--capture" in OS.get_cmdline_user_args():
		menu._scroll.scroll_vertical = 10000
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/aresta-auto-supports.png")
	var added: Array = []
	menu.support_attach_requested.connect(func(slot: int, id: String) -> void: added.assign([slot, id]))
	menu.refresh(moved.menu_model(1))
	await process_frame
	var dropdowns := menu.find_children("*", "OptionButton", true, false)
	var dropdown := dropdowns.back() as OptionButton
	if dropdown == null or dropdown.item_count < 2:
		return _fail("Auto support selector missing")
	dropdown.emit_signal("item_selected", 1)
	if added.size() != 2 or added[0] != Auto.SLOT:
		return _fail("Auto support selector emitted the wrong slot")
	menu.queue_free()
	await process_frame
	print("AUTO_SUPPORTS_OK: compatibility, capacity, real hits, geometry, cost, transfers, migration and menu")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
