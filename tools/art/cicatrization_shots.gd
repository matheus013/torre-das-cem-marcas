extends SceneTree

class Preview:
	extends "res://src/prototype/village/village_exploration.gd"
	func _run_test_hooks(_delta: float) -> void:
		pass

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveSlot.path = "user://cicatrization_preview_unused.json"
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var preview := Preview.new()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.set_physics_process(false)
	preview._character_panel.hide()
	preview._camera.position_smoothing_enabled = false
	var output := ProjectSettings.globalize_path("res://art/shots/cicatrization")
	DirAccess.make_dir_recursive_absolute(output)
	var sim: WorldSimulation = preview._sim
	sim.narrative.accept()
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(640, 720)]:
		root.size = dimensions
		for context: String in ["unseen", "warning", "closed"]:
			sim.narrative.cicatrization_state = "unseen"
			sim.narrative.cicatrization_remaining = 0
			sim.start_floor(2)
			sim.enemies.clear()
			sim.player(1)["zone"] = &"tower"
			sim.player(1)["position"] = sim.cicatrization_marker()
			if context != "unseen":
				assert(sim.narrative_action(1, "observe_cicatrization"))
			if context == "closed":
				for tick in range(21):
					sim._step_cicatrization(0.25)
				assert(sim.narrative.cicatrization_state == "closed")
			preview._view = sim.view_snapshot()
			preview._update_display(0)
			preview._sync_floor()
			preview._camera.position = sim.player(1)["position"]
			preview._update_camera_limits()
			preview._layout_interface()
			preview._update_interface()
			preview.queue_redraw()
			for frame in range(8):
				await process_frame
			RenderingServer.force_draw()
			var screenshot := root.get_texture().get_image()
			assert(not screenshot.is_empty() and screenshot.get_size() == dimensions)
			assert(screenshot.save_png("%s/%s-%dx%d.png" % [output, context, dimensions.x, dimensions.y]) == OK)
	print("CICATRIZATION_SHOTS_OK: nine captures, unstable seam, warning and closed passage at three widths")
	quit(0)
