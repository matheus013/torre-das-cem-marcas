extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var output := "/tmp/aresta-settings-qa"
	DirAccess.make_dir_recursive_absolute(output)
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.gui_embed_subwindows = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var title := (load("res://src/game/title_screen.tscn") as PackedScene).instantiate()
		viewport.add_child(title)
		title.call("_toggle_join")
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output + "/title-%dx%d.png" % [dimensions.x, dimensions.y])
		title.call("_open_settings")
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output + "/options-%dx%d.png" % [dimensions.x, dimensions.y])
		var tabs := title.find_child("Tabs", true, false) as TabContainer
		tabs.current_tab = 1
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output + "/controls-%dx%d.png" % [dimensions.x, dimensions.y])
		if dimensions == Vector2i(1280, 720):
			title.queue_free()
			await process_frame
			var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
			viewport.add_child(village)
			(village.get("_character_panel") as Control).hide()
			await physics_frame
			await physics_frame
			village.call("_open_settings")
			await process_frame
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(output + "/village-options-1280x720.png")
			(village.get_node("SettingsDialog") as Window).hide()
		viewport.queue_free()
		await process_frame
	print("SETTINGS_PREVIEW_OK: " + output)
	quit(0)
