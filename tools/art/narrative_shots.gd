extends SceneTree

class Preview:
	extends "res://src/prototype/village/village_exploration.gd"
	func _run_test_hooks(_delta: float) -> void:
		pass

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var preview := Preview.new()
	preview.name = "VillageExploration"
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.set_physics_process(false)
	preview._camera.position_smoothing_enabled = false
	preview._character_panel.visible = false
	var output := ProjectSettings.globalize_path("res://art/shots/narrative")
	DirAccess.make_dir_recursive_absolute(output)
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(640, 720)]:
		root.size = dimensions
		await process_frame
		preview._layout_interface()
		for context: String in ["alda", "available", "active", "report_ready", "completed", "dalia", "rumor"]:
			var stage := "available" if context in ["alda", "dalia", "rumor"] else context
			preview._sim.narrative.stage = stage
			preview._sim.narrative.opening_known = context != "alda"
			preview._sim.narrative.return_outcome = "retreat" if stage in ["report_ready", "completed"] else ""
			var npc_id := "alda_serrin" if context == "alda" else "dalia_ferral" if context in ["dalia", "rumor"] else "nara_quiral"
			var npc: Dictionary = preview._sim.village_life.call("find", npc_id)
			preview._sim.player(1)["position"] = npc["position"]
			preview._sim.player(1)["zone"] = &"village"
			preview._view = preview._sim.view_snapshot()
			preview._update_display(0)
			preview._camera.position = npc["position"]
			preview._update_camera_limits()
			preview._update_interface()
			preview._service_menu.call("close")
			preview._narrative_menu.call("close")
			if context == "dalia":
				preview._service_menu.call("open", npc, preview._local(), preview._view["warehouse"], preview._conversation_model(npc_id))
			else:
				preview._narrative_menu.call("open", preview._conversation_model(npc_id), true)
			preview.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if image.is_empty() or image.get_size() != dimensions:
				push_error("Narrative screenshot missing or incorrectly sized")
				return quit(1)
			image.save_png("%s/%s-%dx%d.png" % [output, context, dimensions.x, dimensions.y])
		preview._narrative_menu.call("close")
		preview._service_menu.call("close")
		preview._sim.narrative.stage = "active"
		preview._sim.enter_tower(1)
		preview._sim.enemies.clear()
		preview._sim.player(1)["position"] = preview._sim.narrative_marker() + Vector2(0, 70)
		preview._view = preview._sim.view_snapshot()
		preview._update_display(0)
		preview._sync_floor()
		preview._camera.position = preview._sim.player(1)["position"]
		preview._update_camera_limits()
		preview._update_interface()
		preview.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/evidence-%dx%d.png" % [output, dimensions.x, dimensions.y])
	print("NARRATIVE_SHOTS_OK: 24 captures at 720p, 1080p and narrow window")
	quit(0)
