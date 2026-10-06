extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/environment-remodel.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/shots"))
	for group in ["buildings", "props", "deco", "tiles"]:
		var entries: Array = catalog.assets.filter(func(a): return a.group == group)
		var tile: bool = group == "tiles"
		var columns := 4 if tile else 6
		var cell := Vector2i(400, 424) if tile else Vector2i(220, 190)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(columns * cell.x, ceili(float(entries.size()) / columns) * cell.y)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var layer := Node2D.new()
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		viewport.add_child(layer)
		var background := ColorRect.new()
		background.color = Color("343b42")
		background.size = Vector2(viewport.size)
		layer.add_child(background)
		for index in range(entries.size()):
			var entry: Dictionary = entries[index]
			var origin := Vector2(index % columns * cell.x, index / columns * cell.y)
			var label := Label.new()
			label.text = String(entry.id).replace("_", " ")
			label.position = origin + Vector2(6, 4)
			label.size = Vector2(cell.x - 12, 32)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size", 12)
			layer.add_child(label)
			var texture := load("res://" + String(entry.output)) as Texture2D
			assert(texture != null, entry.id)
			if tile:
				for y in range(3):
					for x in range(3):
						var sprite := Sprite2D.new()
						sprite.centered = false
						sprite.texture = texture
						sprite.position = origin + Vector2(8 + x * 128, 36 + y * 128)
						layer.add_child(sprite)
			else:
				var sprite := Sprite2D.new()
				var ratio := minf(1.5, minf(float(cell.x - 16) / texture.get_width(), float(cell.y - 40) / texture.get_height()))
				sprite.texture = texture
				sprite.scale = Vector2.ONE * ratio
				sprite.position = origin + Vector2(cell.x / 2.0, 36 + (cell.y - 40) / 2.0)
				layer.add_child(sprite)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		assert(not image.is_empty())
		assert(image.save_png(ProjectSettings.globalize_path("res://art/shots/environment_" + group + ".png")) == OK)
		viewport.queue_free()
		await process_frame
		print("ENVIRONMENT_RENDER_OK: ", group, " ", entries.size())
	quit(0)
