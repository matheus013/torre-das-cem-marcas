extends SceneTree

const ROOT := "res://assets/sprites/"
const CELL := 240
const COLUMNS := 4
const PAGE_SIZE := 16


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "/tmp/aresta-sprite-review-20261005"
	DirAccess.make_dir_recursive_absolute(output)
	var report: Array[Dictionary] = []
	var groups := DirAccess.get_directories_at(ROOT)
	groups.sort()
	for group in groups:
		var paths: Array[String] = []
		_collect_paths(ROOT + group, paths)
		paths.sort()
		var images: Array[Image] = []
		for path in paths:
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			if image == null:
				push_error("Unreadable sprite: " + path)
				quit(1)
				return
			image.convert(Image.FORMAT_RGBA8)
			images.append(image)
			var entry := inspect(image)
			entry["path"] = path
			entry["page"] = "%s-%02d.png" % [group, images.size() / PAGE_SIZE + (0 if images.size() % PAGE_SIZE == 0 else 1)]
			entry["cell"] = (images.size() - 1) % PAGE_SIZE + 1
			report.append(entry)
		for start in range(0, images.size(), PAGE_SIZE):
			var page := Image.create_empty(COLUMNS * CELL, COLUMNS * CELL, false, Image.FORMAT_RGBA8)
			for y in range(page.get_height()):
				for x in range(page.get_width()):
					page.set_pixel(x, y, Color("343b42") if (x / 16 + y / 16) % 2 == 0 else Color("555d66"))
			for index in range(start, mini(start + PAGE_SIZE, images.size())):
				var thumb := images[index].duplicate() as Image
				var scale := minf(4.0, 200.0 / float(maxi(thumb.get_width(), thumb.get_height())))
				thumb.resize(maxi(1, int(thumb.get_width() * scale)), maxi(1, int(thumb.get_height() * scale)), Image.INTERPOLATE_NEAREST)
				var cell := index - start
				var origin := Vector2i((cell % COLUMNS) * CELL, (cell / COLUMNS) * CELL)
				origin += (Vector2i(CELL, CELL) - thumb.get_size()) / 2
				page.blend_rect(thumb, Rect2i(Vector2i.ZERO, thumb.get_size()), origin)
			page.save_png(output.path_join("%s-%02d.png" % [group, start / PAGE_SIZE + 1]))
	var file := FileAccess.open(output.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("SPRITE_AUDIT: %d files, report %s" % [report.size(), output])
	quit(0)


func _collect_paths(folder: String, paths: Array[String]) -> void:
	for filename in DirAccess.get_files_at(folder):
		if filename.ends_with(".png"):
			paths.append(folder.path_join(filename))
	for child in DirAccess.get_directories_at(folder):
		_collect_paths(folder.path_join(child), paths)


static func inspect(image: Image) -> Dictionary:
	var opaque := 0
	var partial := 0
	var white := 0
	var edge_pixels := 0
	var colors := {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			opaque += 1
			if color.a < 1.0:
				partial += 1
			if color.v > 0.86 and color.s < 0.14:
				white += 1
			if x == 0 or y == 0 or x == image.get_width() - 1 or y == image.get_height() - 1:
				edge_pixels += 1
			colors[color.to_rgba32()] = true
	var bounds := image.get_used_rect()
	return {
		"width": image.get_width(), "height": image.get_height(),
		"content_width": bounds.size.x, "content_height": bounds.size.y,
		"opaque_pixels": opaque, "partial_alpha_pixels": partial,
		"near_white_pixels": white, "edge_pixels": edge_pixels,
		"colors": colors.size(), "pixel_hash": image.get_data().hex_encode().sha256_text(),
	}
