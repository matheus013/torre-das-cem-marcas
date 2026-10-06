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
		if FileAccess.file_exists("res://art/" + String(entry["source"])):
			entries.append(entry)
	for entry: Dictionary in entries:
		var source := Image.load_from_file(ProjectSettings.globalize_path("res://art/" + String(entry["source"])))
		if source == null or source.get_width() < columns or source.get_height() < rows:
			push_error("Invalid animation sheet: " + String(entry["id"]))
			quit(1)
			return
		source.convert(Image.FORMAT_RGBA8)
		var frames: Array[Image] = Slicer.frames(source)
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
		for index in range(frames.size()):
			var frame := frames[index]
			frame.resize(maxi(1, roundi(frame.get_width() * ratio)), maxi(1, roundi(frame.get_height() * ratio)), Image.INTERPOLATE_NEAREST)
			frame = frame.get_region(frame.get_used_rect())
			var origin := Vector2i((index % columns) * cell, (index / columns) * cell)
			origin += Vector2i((cell - frame.get_width()) / 2, int(config["foot_baseline"]) + 1 - frame.get_height())
			atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), origin)
		var id := String(entry["id"])
		var group := String(entry["group"])
		var output := "res://assets/sprites/" + group + "/animations/" + id + "_walk.png"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
		if atlas.save_png(ProjectSettings.globalize_path(output)) != OK:
			quit(1)
			return
		var portrait := atlas.get_region(Rect2i(0, 0, cell, cell))
		portrait = portrait.get_region(portrait.get_used_rect())
		if portrait.save_png(ProjectSettings.globalize_path("res://assets/sprites/" + group + "/" + id + ".png")) != OK:
			quit(1)
			return
		print("ACTOR_ANIMATION: %s/%s, %d frames" % [group, id, frames.size()])
	quit(0)
