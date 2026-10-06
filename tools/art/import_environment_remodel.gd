extends SceneTree


func _init() -> void:
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://art/environment-remodel.json")) as Dictionary
	var count := 0
	for entry: Dictionary in catalog["assets"]:
		var path := "res://art/" + String(entry["source"])
		if not FileAccess.file_exists(path):
			continue
		var image := Image.load_from_file(path)
		image.convert(Image.FORMAT_RGBA8)
		var width := int(entry["width"])
		var height := int(entry["height"])
		if bool(entry["transparent"]):
			for y in range(image.get_height()):
				for x in range(image.get_width()):
					var color := image.get_pixel(x, y)
					image.set_pixel(x, y, Color(color, 1.0) if color.a >= 0.7 else Color.TRANSPARENT)
			var bounds := image.get_used_rect()
			if bounds.size == Vector2i.ZERO or bounds.position.x == 0 or bounds.position.y == 0 or bounds.end.x == image.get_width() or bounds.end.y == image.get_height():
				push_error("Empty or clipped environment source: " + String(entry["id"]))
				quit(1)
				return
			image = image.get_region(bounds)
			var ratio := minf(float(width - 2) / image.get_width(), float(height - 2) / image.get_height())
			image.resize(maxi(1, roundi(image.get_width() * ratio)), maxi(1, roundi(image.get_height() * ratio)), Image.INTERPOLATE_NEAREST)
			var canvas := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
			canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i((width - image.get_width()) / 2, height - image.get_height() - 1))
			image = canvas
		else:
			image.resize(width, height, Image.INTERPOLATE_NEAREST)
			# Match opposite edge texels; the repeated pattern still needs visual QA.
			for y in range(height):
				var color := image.get_pixel(0, y).lerp(image.get_pixel(width - 1, y), 0.5)
				color.a = 1.0
				image.set_pixel(0, y, color)
				image.set_pixel(width - 1, y, color)
			for x in range(width):
				var color := image.get_pixel(x, 0).lerp(image.get_pixel(x, height - 1), 0.5)
				color.a = 1.0
				image.set_pixel(x, 0, color)
				image.set_pixel(x, height - 1, color)
		if image.save_png(ProjectSettings.globalize_path("res://" + String(entry["output"]))) != OK:
			quit(1)
			return
		count += 1
		print("ENVIRONMENT_V2: " + String(entry["output"]))
	print("ENVIRONMENT_IMPORTED: ", count, "/", catalog["assets"].size())
	quit(0)
