extends SceneTree


func _init() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/environment-remodel.json"))
	var pipeline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/process.json"))
	assert(catalog.assets.size() == 104)
	var counts := {"buildings": 0, "props": 0, "deco": 0, "tiles": 0}
	var hashes := {}
	for entry: Dictionary in catalog.assets:
		counts[entry.group] += 1
		assert(FileAccess.file_exists("res://art/" + String(entry.source)), entry.id)
		var texture := load("res://" + String(entry.output)) as Texture2D
		assert(texture != null, entry.id)
		var image := texture.get_image()
		assert(image.get_size() == Vector2i(entry.width, entry.height), entry.id)
		var hash := image.get_data().hex_encode().sha256_text()
		assert(not hashes.has(hash), "Duplicate sprite: " + String(entry.id))
		hashes[hash] = true
		var found := false
		for sprite: Dictionary in pipeline.sprites:
			if sprite.output == "res://" + String(entry.output):
				assert(sprite.mode == "remodel" and sprite.source == entry.source, entry.id)
				found = true
		assert(found, entry.id)
		if entry.transparent:
			assert(image.get_pixel(0, 0).a == 0.0, entry.id)
			var bounds := image.get_used_rect()
			assert(bounds.size != Vector2i.ZERO and bounds.position.x > 0 and bounds.position.y > 0, entry.id)
			assert(bounds.end.x < image.get_width() and bounds.end.y < image.get_height(), entry.id)
		else:
			for y in range(image.get_height()):
				assert(image.get_pixel(0, y) == image.get_pixel(image.get_width() - 1, y), entry.id)
				for x in range(image.get_width()):
					assert(image.get_pixel(x, y).a == 1.0, entry.id)
			for x in range(image.get_width()):
				assert(image.get_pixel(x, 0) == image.get_pixel(x, image.get_height() - 1), entry.id)
	assert(counts == {"buildings": 12, "props": 53, "deco": 26, "tiles": 13})
	print("ENVIRONMENT_REMODEL_OK: 104 distinct sprites; dimensions, alpha, repeat borders and pipeline")
	quit(0)
