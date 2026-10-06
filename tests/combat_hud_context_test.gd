extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Hud := preload("res://src/prototype/village/combat_hud.gd")
const Settings := preload("res://src/core/app/game_settings.gd")
const ORIGIN := Vector2(600, 400)


func _init() -> void:
	_run.call_deferred()
	create_timer(30.0).timeout.connect(func() -> void: _fail("HUD context test did not complete"))


func _fixture(sim: WorldSimulation) -> void:
	for index in range(4):
		var peer := index + 1
		if not sim.players.has(peer):
			sim.add_player(peer, [&"eloa", &"sena", &"cira", &"rui"][index])
			sim.unlock_all_gems(peer, true)
		sim.enter_tower(peer)
		sim.player(peer)["position"] = ORIGIN + Vector2(0, index * 60)
		sim.player(peer)["target"] = sim.player(peer)["position"]
	var state := sim.player(1)
	state["health"] = 20.0
	state["breath"] = 5.0
	state["barrier"] = 80.0
	state["barrier_timer"] = 4.0
	state["invulnerable"] = 1.8
	state["wounds"] = 2
	(state["charges"] as Array)[2] = 0
	(state["cooldowns"] as Array)[2] = 3.5
	sim.player(2)["connected"] = false
	sim.player(2)["reconnect_timer"] = 13.0
	sim.player(3)["downed"] = true
	sim.player(3)["health"] = 0.0
	sim.player(3)["downed_timer"] = 12.0
	sim.player(3)["stabilize_progress"] = 1.35
	sim.player(4)["barrier"] = 14.0
	sim.persistent_effects.clear()
	sim.persistent_effects.append({"mechanic":"sanctuary", "position":ORIGIN, "radius":100.0, "duration":6.0, "healing":14.0, "stability":0.25})
	sim.hazard_zones.clear()
	sim.hazard_zones.append({"position":ORIGIN, "radius":75.0, "remaining":3.0, "slow":0.3, "damage":0.0})
	sim.enemies.clear()
	var enemy := sim.create_enemy({"id":"raspador_de_junta", "name":"Raspador de Junta", "health":200.0, "damage":0.0, "rank_id":"maduro", "allow_affixes":false}, ORIGIN + Vector2(160, 0), 1)
	enemy["slow_timer"] = 2.0
	enemy["slow_amount"] = 0.3
	enemy["vulnerable_timer"] = 1.5
	enemy["vulnerable_amount"] = 0.08
	sim.enemies.append(enemy)


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(9155)
	_fixture(sim)
	var snapshot := sim.view_snapshot()
	var local := snapshot["players"][1] as Dictionary
	if float(local["barrier_timer"]) != 4.0 or (local["status_effects"] as Array).size() != 6:
		return _fail("Effects or shield duration missing from authoritative snapshot")
	if float(snapshot["enemies"][0]["slow"]) != 0.3 or float(snapshot["enemies"][0]["vulnerable"]) != 0.08:
		return _fail("Target conditions differ from damage pipeline")
	for slot in range(4):
		if float(local["skill_costs"][slot]) != float(sim.resolve_slot(1, slot).get("breath_cost", 0.0)):
			return _fail("HUD cost differs from cast requirement")
	sim.player(1)["position"] = ORIGIN + Vector2(250, 0)
	var outside := sim.player_status_effects(1)
	if outside.size() != 3:
		return _fail("Zone effects persisted outside their radius")
	sim.player(1)["barrier"] = 0.0
	sim.player(1)["invulnerable"] = 0.0
	sim.player(1)["wounds"] = 0
	if not sim.player_status_effects(1).is_empty():
		return _fail("Expired protections or cleared wounds remained visible")
	var hud := Hud.new()
	root.add_child(hud)
	hud.size = Vector2(1280, 720)
	hud.breath = 5.0
	hud.health = 20.0
	hud.set_skill_charges([1, 1, 0, 1] as Array[int], [1, 1, 1, 2] as Array[int])
	hud.set_context(local, snapshot["players"], 1, true, snapshot["enemies"][0], {"number":1, "stairs_open":false})
	if hud.skill_state(0) != "ready" or hud.skill_state(1) != "breath" or hud.skill_state(2) != "cooldown" or hud.party.size() != 3:
		return _fail("Resource, charge or party state is incorrect")
	if hud.warning_text() != "VIDA CRITICA":
		return _fail("Low health warning is missing")
	hud.skill_costs = [0, 0, 0, 0]
	hud.skill_charges[3] = 1
	hud.cooldowns[3] = 4.0
	if hud.skill_state(3) != "ready":
		return _fail("Available extra charge was obscured by recharge")
	hud.downed = true
	if hud.skill_state(0) != "blocked":
		return _fail("Downed player sees ready skill")
	if not hud.warning_text().begins_with("CAIDO"):
		return _fail("Local downed status is missing")
	hud.set_context(local, snapshot["players"], 1, false, {}, {"number":1, "stairs_open":true})
	if not hud.selected_target.is_empty() or hud._notice != "ESCADA LIBERADA":
		return _fail("Aim toggle or stair notification failed")
	hud.announce("FOLEGO INSUFICIENTE", "breath")
	hud.call("_process", 1.0)
	var remaining := hud._notice_seconds
	hud.announce("FOLEGO INSUFICIENTE", "breath")
	if hud._notice_seconds != remaining:
		return _fail("Repeated notice restarted the timer")
	hud.call("_process", 3.0)
	if hud._notice_seconds != 0.0:
		return _fail("Notice never expires")
	hud.size = Vector2(640, 720)
	for index in range(6):
		if not Rect2(Vector2.ZERO, hud.size).encloses(hud.effect_rect(index)):
			return _fail("Effect icons leave narrow viewport")
	hud.clear_context()
	if hud._floor_number != -1 or hud._stairs_open:
		return _fail("Leaving combat retained floor notification state")
	hud.queue_free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await _capture()
	print("COMBAT_HUD_CONTEXT_OK: skill resources, effects, barrier, party, targeting and throttled notices")
	quit(0)


func _capture() -> void:
	var old_aim := Settings.auto_aim
	Settings.auto_aim = true
	var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	village.set_physics_process(false)
	(village.get("_character_panel") as Control).hide()
	var sim := village.get("_sim") as WorldSimulation
	_fixture(sim)
	village.set("_view", sim.view_snapshot())
	village.set("_display", {})
	village.call("_sync_floor")
	var camera := village.get("_camera") as Camera2D
	camera.position = ORIGIN
	camera.reset_smoothing()
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 720), Vector2i(1920, 1080)]:
		root.size = dimensions
		await process_frame
		village.call("_layout_interface")
		village.call("_update_interface")
		village.call("_apply_events", [{"type":"status", "peer":1, "text":"Folego insuficiente."}])
		village.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/aresta-hud-context-%dx%d.png" % [dimensions.x, dimensions.y])
	Settings.auto_aim = false
	village.call("_update_interface")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/aresta-hud-context-manual.png")
	var view := village.get("_view") as Dictionary
	(view["floor"] as Dictionary)["stairs_open"] = true
	village.call("_update_interface")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/aresta-hud-context-stairs.png")
	var local := (view["players"] as Dictionary)[1] as Dictionary
	local["downed"] = true
	local["health"] = 0.0
	local["downed_timer"] = 14.0
	local["stabilize_progress"] = 0.25
	village.call("_update_interface")
	village.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/aresta-hud-context-downed.png")
	Settings.auto_aim = old_aim
	village.queue_free()
	await process_frame


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
