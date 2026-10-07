extends SceneTree

const Slicer := preload("res://tools/art/animation_sheet_slicer.gd")


func _init() -> void:
	var config := JSON.parse_string(FileAccess.get_file_as_string("res://art/animations.json")) as Dictionary
	var cell := int(config["frame_size"])
	var columns := int(config["columns"])
	var rows := (config["directions"] as Array).size()
	var entries: Array = (config["characters"] as Array).duplicate(true)
	for entry: Dictionary in entries:
		entry["group"] = "characters"
	var actor_config := JSON.parse_string(FileAccess.get_file_as_string("res://art/actor-animations.json")) as Dictionary
	for entry: Dictionary in actor_config.get("actors", []):
		if not FileAccess.file_exists("res://art/" + String(entry["source"])):
			push_error("Missing actor source: " + String(entry["source"]))
			quit(1)
			return
		entries.append(entry)
	for entry: Dictionary in entries:
		var source := Image.load_from_file(ProjectSettings.globalize_path("res://art/" + String(entry["source"])))
		if source == null or source.get_width() < columns or source.get_height() < rows:
			push_error("Invalid animation sheet: " + String(entry["id"]))
			quit(1)
			return
		source.convert(Image.FORMAT_RGBA8)
		var source_columns := int(entry.get("source_columns", columns))
		if source_columns not in [columns, columns + 1]:
			push_error("Unsupported animation layout: " + String(entry["id"]))
			quit(1)
			return
		var has_idle := source_columns == columns + 1
		var frames: Array[Image] = Slicer.frames(source, source_columns, rows)
		var max_height := 0
		var max_width := 0
		for index in range(frames.size()):
			var bounds := frames[index].get_used_rect()
			if bounds.size == Vector2i.ZERO:
				push_error("Empty animation frame: " + String(entry["id"]))
				quit(1)
				return
			frames[index] = frames[index].get_region(bounds)
			max_height = maxi(max_height, bounds.size.y)
			max_width = maxi(max_width, bounds.size.x)
		# One scale for the entire sheet preserves proportions across all poses.
		var ratio := minf(float(config["content_height"]) / max_height, float(cell - 8) / max_width)
		var atlas := Image.create_empty(cell * columns, cell * rows, false, Image.FORMAT_RGBA8)
		var idle_atlas := Image.create_empty(cell, cell * rows, false, Image.FORMAT_RGBA8)
		for index in range(frames.size()):
			var frame := frames[index]
			frame.resize(maxi(1, roundi(frame.get_width() * ratio)), maxi(1, roundi(frame.get_height() * ratio)), Image.INTERPOLATE_NEAREST)
			frame = frame.get_region(frame.get_used_rect())
			var source_column := index % source_columns
			var is_idle := has_idle and source_column == 0
			var column := maxi(0, source_column - 1) if has_idle else source_column
			var origin := Vector2i(column * cell, (index / source_columns) * cell)
			origin += Vector2i((cell - frame.get_width()) / 2, int(config["foot_baseline"]) + 1 - frame.get_height())
			if is_idle:
				idle_atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), origin)
			else:
				atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), origin)
		var id := String(entry["id"])
		var group := String(entry["group"])
		var output := "res://assets/sprites/" + group + "/animations/" + id + "_walk.png"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
		if atlas.save_png(ProjectSettings.globalize_path(output)) != OK:
			quit(1)
			return
		if has_idle and idle_atlas.save_png(ProjectSettings.globalize_path(output.replace("_walk.png", "_idle.png"))) != OK:
			quit(1)
			return
		var portrait := (idle_atlas if has_idle else atlas).get_region(Rect2i(0, 0, cell, cell))
		portrait = portrait.get_region(portrait.get_used_rect())
		if portrait.save_png(ProjectSettings.globalize_path("res://assets/sprites/" + group + "/" + id + ".png")) != OK:
			quit(1)
			return
		print("ACTOR_ANIMATION: %s/%s, %d frames" % [group, id, frames.size()])
	quit(0)
