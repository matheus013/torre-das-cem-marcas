extends SceneTree

class Preview:
	extends "res://src/prototype/village/village_exploration.gd"
	func _run_test_hooks(_delta: float) -> void:
		pass

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveSlot.path = "user://fissure_preview_unused.json"
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var preview := Preview.new()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.set_physics_process(false)
	preview._character_panel.hide()
	preview._camera.position_smoothing_enabled = false
	var output := ProjectSettings.globalize_path("res://art/shots/fissure")
	DirAccess.make_dir_recursive_absolute(output)
	var sim: WorldSimulation = preview._sim
	sim.narrative.accept()
	sim.narrative.opening_known = true
	sim.narrative.rescue_state = "rescued"
	sim.narrative.rescue_progress = 1
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(640, 720)]:
		root.size = dimensions
		for context: String in ["fork", "guarded", "returned"]:
			preview._narrative_menu.close()
			if sim.player(1)["zone"] == &"tower":
				sim.leave_tower(1)
			sim.narrative.stage = "active"
			sim.narrative.return_outcome = ""
			sim.narrative.route_choice = ""
			sim.narrative.fissure_found = false
			sim.enter_tower(1)
			sim.enemies.clear()
			var markers := sim.narrative_route_markers()
			sim.player(1)["position"] = markers[1]["position"]
			if context != "fork":
				assert(sim.narrative_action(1, "enter_fissure"))
				sim.player(1)["position"] = sim.narrative_route_markers()[0]["position"] + Vector2(0, 70)
			if context == "returned":
				sim.enemies.clear()
				assert(sim.narrative_action(1, "inspect_fissure"))
				sim.leave_tower(1)
				sim.player(1)["position"] = sim.village_life.call("find", "nara_quiral")["position"]
			preview._view = sim.view_snapshot()
			preview._update_display(0)
			preview._sync_floor()
			preview._camera.position = sim.player(1)["position"]
			preview._update_camera_limits()
			preview._layout_interface()
			preview._update_interface()
			if context == "returned":
				preview._narrative_menu.open(preview._conversation_model("nara_quiral"), true)
			preview.queue_redraw()
			for frame in range(8):
				await process_frame
			RenderingServer.force_draw()
			var screenshot := root.get_texture().get_image()
			assert(not screenshot.is_empty() and screenshot.get_size() == dimensions)
			assert(screenshot.save_png("%s/%s-%dx%d.png" % [output, context, dimensions.x, dimensions.y]) == OK)
	print("FISSURE_SHOTS_OK: nine captures, optional fork, guards and Nara reaction at three widths")
	quit(0)
