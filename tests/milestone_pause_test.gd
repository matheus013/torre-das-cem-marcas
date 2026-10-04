extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _reach(sim: WorldSimulation, peer: int, level: int) -> void:
	var build := sim.character_build(peer)
	while build.level < level and not build.has_pending_milestone():
		sim.add_experience(peer, sim.experience_required(build.level))


func _pick(sim: WorldSimulation, peer: int) -> void:
	var choices := sim.menu_model(peer)["milestone_choices"] as Array
	sim.choose_milestone(peer, StringName(String(choices[0]["id"])))


func _pad(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	root.push_input(event)


func _run() -> void:
	if "--compact" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i.ZERO
		root.size = Vector2i(640, 720)
	var sim := Simulation.new()
	sim.setup(8302)
	sim.add_player(1, &"eloa")
	sim.add_player(2, &"sena", "milestone_test_profile")
	sim.enter_tower(1)
	sim.enter_tower(2)
	_reach(sim, 1, 9)
	if sim.is_milestone_paused():
		return _fail("Ordinary levels must not pause")
	_reach(sim, 1, 10)
	_reach(sim, 2, 10)
	if sim.pending_milestone_peers() != [1, 2]:
		return _fail("Both pending players must participate in the global pause")
	var before := sim.view_snapshot()
	var target: Vector2 = sim.player(1)["target"]
	sim.set_move_target(1, Vector2(600, 500))
	if sim.use_skill(1, 0, Vector2(600, 500)):
		return _fail("Skills must not execute while paused")
	sim.use_quick_item(1)
	for index in range(30):
		sim.step(0.1)
	if before != sim.view_snapshot() or sim.player(1)["target"] != target:
		return _fail("Pause must freeze movement, damage, cooldowns, floor and consumables")
	sim.choose_milestone(1, &"invalid_choice")
	if not sim.is_milestone_paused():
		return _fail("Invalid choices must not resume combat")
	_pick(sim, 1)
	if sim.pending_milestone_peers() != [2]:
		return _fail("Combat must wait for the remaining player")
	var restored := Simulation.new()
	restored.setup(8302)
	restored.add_player(1, &"eloa")
	if not restored.load_data(sim.save_data(1), 1):
		return _fail("Pending milestones must survive save/reload")
	# Players are session state; the persistent build must still need its choice.
	restored.add_player(2, &"sena")
	if not restored.is_milestone_paused():
		return _fail("Rejoining a pending saved build must pause")
	sim.disconnect_player(2)
	if sim.is_milestone_paused():
		return _fail("Disconnected players must not deadlock the pause")
	if not sim.reconnect_player("milestone_test_profile", 3):
		return _fail("Reserved profile must reconnect")
	if not sim.is_milestone_paused():
		return _fail("A pending choice must return when the character rejoins")
	_pick(sim, 3)
	if sim.is_milestone_paused():
		return _fail("Last confirmed choice must resume")
	var clock_before := sim.view_snapshot()
	sim.step(0.1)
	if clock_before == sim.view_snapshot():
		return _fail("Simulation must advance after confirmation")
	# Excess XP queues subsequent milestones rather than resuming prematurely.
	sim.add_experience(1, 1000000)
	if sim.character_build(1).level != 20 or not sim.is_milestone_paused():
		return _fail("Buffered experience must stop at the next milestone")
	_pick(sim, 1)
	if sim.character_build(1).level != 30 or not sim.is_milestone_paused():
		return _fail("Sequential milestone choices must keep combat paused")
	while sim.is_milestone_paused():
		_pick(sim, 1)
	if sim.character_build(1).level != 100 or sim.character_build(1).selected_milestones.size() != 10:
		return _fail("All milestones through level 100 must be selectable and resume")
	var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	var local_sim: WorldSimulation = village.get("_sim")
	_reach(local_sim, 1, 10)
	await physics_frame
	await process_frame
	var modal := village.get("_milestone_choice") as Control
	if not modal.visible or not root.gui_get_focus_owner() is Button:
		return _fail("Milestone screen must open automatically with gamepad/keyboard focus")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	village.call("_unhandled_input", cancel)
	if not modal.visible:
		return _fail("Cancel must not dismiss a mandatory choice")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/aresta-milestone-compact.png" if "--compact" in OS.get_cmdline_user_args() else "/tmp/aresta-milestone.png")
	var previous_focus := root.gui_get_focus_owner()
	_pad(JOY_BUTTON_DPAD_DOWN, true)
	await process_frame
	_pad(JOY_BUTTON_DPAD_DOWN, false)
	if root.gui_get_focus_owner() == previous_focus or not root.gui_get_focus_owner() is Button:
		return _fail("Directional gamepad navigation must reach another choice")
	_pad(JOY_BUTTON_A, true)
	await process_frame
	_pad(JOY_BUTTON_A, false)
	await physics_frame
	await process_frame
	if modal.visible or local_sim.is_milestone_paused():
		return _fail("Confirmation must apply the choice and close the screen")
	var remote := Simulation.new()
	remote.setup(8303)
	remote.add_player(1, &"eloa")
	remote.add_player(2, &"sena")
	_reach(remote, 2, 10)
	# A client has no local simulator; the replicated snapshot must drive waiting/resume.
	village.set("_sim", null)
	village.set("_view", remote.view_snapshot())
	village.call("_update_milestone_choice")
	if not modal.visible or not bool(village.call("_input_blocked")):
		return _fail("A replicated teammate choice must show waiting and block combat input")
	_pick(remote, 2)
	village.set("_view", remote.view_snapshot())
	village.call("_update_milestone_choice")
	if modal.visible:
		return _fail("A replicated last confirmation must dismiss the waiting screen")
	village.set("_sim", local_sim)
	village.queue_free()
	await process_frame
	print("MILESTONE_PAUSE_OK: authoritative pause, co-op, disconnect, save, queued XP and focused choice screen")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
