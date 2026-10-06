extends SceneTree


func _init() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/environment-remodel.json"))
	var issues: Array = []
	for entry: Dictionary in catalog.assets:
		var image := Image.load_from_file("res://art/" + String(entry.source))
		if image == null:
			issues.append({"id": entry.id, "error": "missing"})
			continue
		if not entry.transparent:
			continue
		image.convert(Image.FORMAT_RGBA8)
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				image.set_pixel(x, y, Color(color, 1.0) if color.a >= 0.7 else Color.TRANSPARENT)
		var bounds := image.get_used_rect()
		if bounds.size == Vector2i.ZERO or bounds.position.x == 0 or bounds.position.y == 0 or bounds.end.x == image.get_width() or bounds.end.y == image.get_height():
			issues.append({"id": entry.id, "error": "empty_or_clipped", "bounds": str(bounds)})
	print("ENVIRONMENT_SOURCE_AUDIT: ", JSON.stringify(issues))
	quit(0 if issues.is_empty() else 1)
