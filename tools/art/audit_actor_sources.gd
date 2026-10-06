extends SceneTree

const Slicer := preload("res://tools/art/animation_sheet_slicer.gd")


func _init() -> void:
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://art/actor-animations.json")) as Dictionary
	var problems: Array = []
	for actor: Dictionary in catalog["actors"]:
		var source := Image.load_from_file("res://art/" + String(actor["source"]))
		source.convert(Image.FORMAT_RGBA8)
		var edges: Array = []
		var frames := Slicer.frames(source)
		for index in range(frames.size()):
			var frame := frames[index]
			var bounds := frame.get_used_rect()
			if bounds.size == Vector2i.ZERO or bounds.position.x <= 1 or bounds.position.y <= 1 or bounds.end.x >= frame.get_width() - 1 or bounds.end.y >= frame.get_height() - 1:
				edges.append([index / 4, index % 4])
		if not edges.is_empty():
			problems.append({"id": actor["id"], "frames": edges})
	print("ACTOR_SOURCE_AUDIT: ", JSON.stringify(problems))
	quit(1 if not problems.is_empty() else 0)
