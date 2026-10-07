extends SceneTree

const Catalog := preload("res://src/gameplay/content/beta_content_catalog.gd")
const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Resolver := preload("res://src/gameplay/skills/skill_effect_resolver.gd")
const Geometry := preload("res://src/gameplay/skills/skill_geometry.gd")
const ORIGIN := Vector2(600, 400)
const TARGET := Vector2(760, 400)


func _init() -> void:
	_run.call_deferred()


func _world(gem_id: String) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(9104)
	sim.add_player(1, &"rui")
	sim.unlock_all_gems(1, true)
	sim.set_gem_slot(1, 0, gem_id)
	sim.enter_tower(1)
	sim.enemies.clear()
	var positions: Array[Vector2] = [Vector2(650, 400), Vector2(700, 400), TARGET, Vector2(820, 420), Vector2(800, 440), Vector2(600, 500), Vector2(600, 300), Vector2(700, 500)]
	for index in range(positions.size()):
		var enemy := sim.create_enemy({"id": "skill_probe", "health": 100000, "damage": 0, "rank_id": "maduro", "allow_affixes": false}, positions[index], index + 1)
		enemy["health"] = 100000.0
		enemy["max_health"] = 100000.0
		enemy["shield_hits"] = 0
		enemy["race_trait"] = ""
		sim.enemies.append(enemy)
	var state := sim.player(1)
	state["position"] = ORIGIN
	state["target"] = ORIGIN
	state["health"] = 40.0
	state["breath"] = 100.0
	return sim


func _advance_effects(sim: WorldSimulation, seconds := 2.5) -> void:
	for index in range(int(seconds / 0.1)):
		sim.call("_run_scheduled", 0.1)
		sim.call("_update_persistent_effects", 0.1)
		sim.call("_step_poisons", 0.1)


func _hurt(sim: WorldSimulation) -> bool:
	for enemy in sim.enemies:
		if float(enemy["health"]) < 100000.0:
			return true
	return false


func _run() -> void:
	var catalog := Catalog.new()
	if not catalog.load_from():
		return _fail("Invalid catalog: %s" % [catalog.validation_errors()])
	var actives := catalog.collection("active_gems")
	var supports := catalog.collection("support_gems")
	var mechanic_count := 0
	var buff_count := 0
	var resolver := Resolver.new()
	var pairs := 0
	var signatures: Dictionary = {}
	if actives.size() != 46 or supports.size() != 40:
		return _fail("Expected 46 actives and 40 supports")
	for gem in actives:
		if not ResourceLoader.exists("res://assets/sprites/icons/%s.png" % gem["id"]):
			return _fail("Missing active icon: %s" % gem["id"])
		var fingerprint := gem.duplicate(true)
		for key in ["id", "name", "description", "evolutions"]:
			fingerprint.erase(key)
		var signature := JSON.stringify(fingerprint)
		if signatures.has(signature):
			return _fail("Identical active behavior: %s" % gem["id"])
		signatures[signature] = true
		var sim := _world(String(gem["id"]))
		if not sim.use_skill(1, 0, TARGET):
			return _fail("Active could not be cast: %s" % gem["id"])
		_advance_effects(sim)
		if not _hurt(sim) and float(sim.player(1)["barrier"]) <= 0.0 and float(sim.player(1)["health"]) <= 40.0 and sim.player(1)["position"] == ORIGIN:
			return _fail("Active produced no combat/movement/healing outcome: %s" % gem["id"])
		for support in supports:
			if resolver.supports(gem, support):
				var enhanced := resolver.resolve(gem, [support] as Array[Dictionary])
				if enhanced == gem:
					return _fail("Compatible support changed nothing: %s on %s" % [support["id"], gem["id"]])
				var supported := _world(String(gem["id"]))
				supported.execute_gem_effect(1, enhanced, TARGET)
				_advance_effects(supported)
				pairs += 1
		for level: String in gem["evolutions"]:
			for choice: Dictionary in gem["evolutions"][level]:
				var evolved := resolver.resolve(gem, [] as Array[Dictionary], [choice["modifiers"]] as Array[Dictionary])
				var evolved_world := _world(String(gem["id"]))
				evolved_world.execute_gem_effect(1, evolved, TARGET)
				_advance_effects(evolved_world)
	for support in supports:
		mechanic_count += int(String(support["category"]) == "mechanic")
		buff_count += int(String(support["category"]) == "buff")
		if not ResourceLoader.exists("res://assets/sprites/icons/%s.png" % support["id"]):
			return _fail("Missing support icon: %s" % support["id"])
		var used := false
		for gem in actives:
			used = used or resolver.supports(gem, support)
		if not used:
			return _fail("Unusable support: %s" % support["id"])
	if mechanic_count != 20 or buff_count != 20:
		return _fail("Support categories must each have 20 entries")
	if Geometry.in_cone(Vector2(-20, 0), Vector2.ZERO, Vector2.RIGHT, 100, 1.5) or not Geometry.in_cone(Vector2(50, 0), Vector2.ZERO, Vector2.RIGHT, 100, 1.5):
		return _fail("Cone must distinguish front/back")
	var mine := _world("mina_de_lastro")
	mine.execute_gem_effect(1, mine.gem_definition("mina_de_lastro"), TARGET)
	mine.call("_update_persistent_effects", 0.5)
	if _hurt(mine) or mine.persistent_effects.is_empty():
		return _fail("Mine must not explode before it is armed")
	mine.call("_update_persistent_effects", 0.6)
	if not _hurt(mine) or not mine.persistent_effects.is_empty():
		return _fail("Armed mine must explode once and be removed")
	var meteor := _world("cometa_de_vidro")
	meteor.execute_gem_effect(1, meteor.gem_definition("cometa_de_vidro"), TARGET)
	if _hurt(meteor):
		return _fail("Meteor must wait for its impact delay")
	meteor.call("_run_scheduled", 1.3)
	if not _hurt(meteor):
		return _fail("Delayed meteor must deal damage")
	var siphon := _world("agulha_lastro")
	siphon.player(1)["breath"] = 0.0
	for index in range(20):
		siphon.damage_enemy(1, 0, 1, {"breath_per_hit": 2.0})
	if float(siphon.player(1)["breath"]) != 8.0:
		return _fail("Breath on hit must share an eight-point budget")
	var hollow := _world("pulso_cicatriz")
	var hollow_effect := resolver.resolve(hollow.gem_definition("pulso_cicatriz"), [hollow.support_definition("anel_vazio")] as Array[Dictionary])
	hollow.execute_gem_effect(1, hollow_effect, TARGET)
	if float(hollow.enemies[0]["health"]) != 100000.0 or float(hollow.enemies[1]["health"]) >= 100000.0:
		return _fail("Hollow nova must spare the center and damage its ring")
	var sanctuary := _world("circulo_de_reparo")
	sanctuary.execute_gem_effect(1, sanctuary.gem_definition("circulo_de_reparo"), TARGET)
	sanctuary.player(1)["position"] = Vector2(1000, 700)
	sanctuary.call("_update_persistent_effects", 0.1)
	if float(sanctuary.player(1)["health"]) != 40:
		return _fail("Stationary sanctuary must not heal its owner outside its radius")
	var orbit := _world("laminas_orbitais")
	orbit.execute_gem_effect(1, orbit.gem_definition("laminas_orbitais"), TARGET)
	var orbit_before: Array = orbit.view_snapshot()["effects"][0]["points"]
	orbit.call("_update_persistent_effects", 0.1)
	if orbit_before == orbit.view_snapshot()["effects"][0]["points"]:
		return _fail("Orbit points must rotate in the authoritative snapshot")
	var chain := _world("elo_residual")
	chain.enemies.resize(2)
	chain.enemies[0]["health"] = 1.0
	chain.enemies[1]["health"] = 1.0
	chain.execute_gem_effect(1, {"mechanic": "chain", "power": 20, "range": 500, "chain_count": 1, "repeat_last_target": true}, TARGET)
	if chain.enemies.size() != 1 or float(chain.enemies[0]["health"]) != 1:
		return _fail("A repeated killed chain target must not redirect to another enemy")
	var saved := _world("laminas_orbitais")
	saved.leave_tower(1)
	saved.attach_support(1, 0, "sifao_de_folego")
	var restored := Simulation.new()
	restored.setup(9104)
	restored.add_player(1, &"rui")
	if not restored.load_data(saved.save_data(1), 1) or restored.resolve_slot(1, 0).get("gem_id") != "laminas_orbitais" or restored.resolve_slot(1, 0).get("breath_per_hit") != 2:
		return _fail("New gem and support must survive save/reload")
	if "--capture" in OS.get_cmdline_user_args():
		await _capture()
	print("EXPANDED_SKILLS_OK: 46 distinct actives, 20 mechanics, 20 buffs, %d compatible pairs, evolutions, timing, icons and save" % pairs)
	quit(0)


func _capture() -> void:
	var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	(village.get("_character_panel") as Control).hide()
	var sim: WorldSimulation = village.get("_sim")
	sim.unlock_all_gems(1)
	for slot in range(4):
		sim.set_gem_slot(1, slot, ["laminas_orbitais", "mina_de_lastro", "chuva_ferral", "ceifa_ampla"][slot])
	village.call("_open_player_menu", "skills")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/aresta-expanded-skills-menu.png")
	(village.get("_player_menu") as Control).call("close")
	village.call("_open_player_menu", "character")
	await process_frame
	var menu := village.get("_player_menu") as Control
	var content := menu.get("_content") as VBoxContainer
	(content.get_parent() as ScrollContainer).scroll_vertical = 500
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/aresta-weapon-character-menu.png")
	(village.get("_player_menu") as Control).call("close")
	sim.enter_tower(1)
	sim.enemies.clear()
	sim.player(1)["position"] = ORIGIN
	sim.player(1)["target"] = ORIGIN
	sim.player(1)["attack_timer"] = 999.0
	sim.use_skill(1, 0, TARGET)
	sim.use_skill(1, 1, TARGET)
	sim.use_skill(1, 2, TARGET)
	for index in range(8):
		await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/aresta-expanded-skills-arena.png")
	village.queue_free()
	await process_frame


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
