extends SceneTree

const Slicer := preload("res://tools/art/animation_sheet_slicer.gd")


func _init() -> void:
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://art/actor-animations.json")) as Dictionary
	var players := JSON.parse_string(FileAccess.get_file_as_string("res://art/animations.json")) as Dictionary
	var problems: Array = []
	var actors: Array = (catalog["actors"] as Array).duplicate()
	actors.append_array(players["characters"])
	for actor: Dictionary in actors:
		var source := Image.load_from_file("res://art/" + String(actor["source"]))
		if source == null:
			problems.append({"id": actor["id"], "error": "missing source"})
			continue
		source.convert(Image.FORMAT_RGBA8)
		var edges: Array = []
		var columns := int(actor.get("source_columns", 4))
		var frames := Slicer.frames(source, columns)
		for index in range(frames.size()):
			var frame := frames[index]
			var bounds := frame.get_used_rect()
			if bounds.size == Vector2i.ZERO or bounds.position.x <= 1 or bounds.position.y <= 1 or bounds.end.x >= frame.get_width() - 1 or bounds.end.y >= frame.get_height() - 1:
				edges.append({"row": index / columns, "column": index % columns, "bounds": str(bounds), "cell": str(frame.get_size())})
		if not edges.is_empty():
			problems.append({"id": actor["id"], "frames": edges})
	print("ACTOR_SOURCE_AUDIT: ", JSON.stringify(problems))
	quit(1 if not problems.is_empty() else 0)
