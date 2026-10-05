extends SceneTree


func _init() -> void:
	var config := JSON.parse_string(FileAccess.get_file_as_string("res://art/animations.json")) as Dictionary
	var cell := int(config["frame_size"])
	var columns := int(config["columns"])
	var rows := (config["directions"] as Array).size()
	for entry: Dictionary in config["characters"]:
		var source := Image.load_from_file(ProjectSettings.globalize_path("res://art/" + String(entry["source"])))
		if source == null or source.get_width() < columns or source.get_height() < rows:
			push_error("Invalid animation sheet: " + String(entry["id"]))
			quit(1)
			return
		source.convert(Image.FORMAT_RGBA8)
		var frames: Array[Image] = []
		var max_height := 0
		var max_width := 0
		for row in range(rows):
			for column in range(columns):
				var start := Vector2i(roundi(float(column) * source.get_width() / columns), roundi(float(row) * source.get_height() / rows))
				var end := Vector2i(roundi(float(column + 1) * source.get_width() / columns), roundi(float(row + 1) * source.get_height() / rows))
				var frame := source.get_region(Rect2i(start, end - start))
				for y in range(frame.get_height()):
					for x in range(frame.get_width()):
						var color := frame.get_pixel(x, y)
						frame.set_pixel(x, y, Color(color, 1.0) if color.a >= 0.7 else Color.TRANSPARENT)
				var bounds := frame.get_used_rect()
				if bounds.size == Vector2i.ZERO:
					push_error("Empty animation frame")
					quit(1)
					return
				frame = frame.get_region(bounds)
				frames.append(frame)
				max_height = maxi(max_height, frame.get_height())
				max_width = maxi(max_width, frame.get_width())
		# One scale for the entire sheet preserves proportions across all poses.
		var ratio := minf(float(config["content_height"]) / max_height, float(cell - 8) / max_width)
		var atlas := Image.create_empty(cell * columns, cell * rows, false, Image.FORMAT_RGBA8)
		for index in range(frames.size()):
			var frame := frames[index]
			frame.resize(maxi(1, roundi(frame.get_width() * ratio)), maxi(1, roundi(frame.get_height() * ratio)), Image.INTERPOLATE_NEAREST)
			var origin := Vector2i((index % columns) * cell, (index / columns) * cell)
			origin += Vector2i((cell - frame.get_width()) / 2, int(config["foot_baseline"]) + 1 - frame.get_height())
			atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), origin)
		var id := String(entry["id"])
		var output := "res://assets/sprites/characters/animations/" + id + "_walk.png"
		if atlas.save_png(ProjectSettings.globalize_path(output)) != OK:
			quit(1)
			return
		var portrait := atlas.get_region(Rect2i(0, 0, cell, cell))
		portrait = portrait.get_region(portrait.get_used_rect())
		if portrait.save_png(ProjectSettings.globalize_path("res://assets/sprites/characters/" + id + ".png")) != OK:
			quit(1)
			return
		print("CHARACTER_ANIMATION: %s, %d frames" % [id, frames.size()])
	quit(0)
