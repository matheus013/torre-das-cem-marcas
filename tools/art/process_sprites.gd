extends SceneTree

## Converte imagens brutas (art/raw) em sprites limpos do jogo.
## Uso: godot --headless --path . --script tools/art/process_sprites.gd [-- chave ...]

const CONFIG_PATH := "res://art/process.json"
const PREVIEW_PATH := "res://art/preview.png"
const PREVIEW_SCALE := 4

var _palette: Array[Color] = []
var _outline_color := Color("1b1a1f")


func _init() -> void:
	var config := _read_json(ProjectSettings.globalize_path(CONFIG_PATH))
	if config.is_empty():
		push_error("art/process.json ausente ou inválido")
		quit(1)
		return
	for value: Variant in config.get("palette", []):
		_palette.append(Color(String(value)))
	_outline_color = Color(String(config.get("outline_color", "1b1a1f")))
	var filter := OS.get_cmdline_user_args()
	var previews: Array[Image] = []
	var failures := 0
	for raw_entry: Variant in config.get("sprites", []):
		var entry := raw_entry as Dictionary
		if not filter.is_empty() and String(entry.get("key", "")) not in filter:
			continue
		if String(entry.get("mode", "")) == "animation":
			var portrait := Image.load_from_file(ProjectSettings.globalize_path(String(entry["output"])))
			if portrait == null:
				failures += 1
			else:
				previews.append(portrait)
			continue
		if String(entry.get("mode", "")) == "split":
			var pieces := _split_entry(entry)
			var output_base := String(entry["output"]).trim_suffix(".png")
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_base.get_base_dir()))
			for index in range(pieces.size()):
				var piece_path := "%s_%d.png" % [output_base, index + 1]
				pieces[index].save_png(ProjectSettings.globalize_path(piece_path))
				print("ok   %s  %dx%d" % [piece_path, pieces[index].get_width(), pieces[index].get_height()])
				previews.append(pieces[index])
			continue
		var image := _process_entry(entry)
		if image == null:
			failures += 1
			continue
		var output := String(entry["output"])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
		image.save_png(ProjectSettings.globalize_path(output))
		print("ok   %s  %dx%d" % [output, image.get_width(), image.get_height()])
		previews.append(image)
	if not previews.is_empty():
		_save_preview(previews)
	quit(1 if failures > 0 else 0)


func _process_entry(entry: Dictionary) -> Image:
	var source := ProjectSettings.globalize_path("res://art/" + String(entry["source"]))
	var raw := Image.load_from_file(source)
	if raw == null:
		push_error("não foi possível ler %s" % source)
		return null
	raw.convert(Image.FORMAT_RGBA8)
	var mode := String(entry.get("mode", "sprite"))
	var block := int(entry.get("block", 8))
	var image := _downsample(raw, block, mode == "sprite")
	if mode == "sprite":
		_remove_border_background(image)
		if bool(entry.get("remove_all_background", false)):
			_remove_all_background(image)
		if not bool(entry.get("keep_all", false)):
			_keep_main_body(image)
		image = _crop_to_content(image)
	if entry.has("contrast"):
		_reduce_contrast(image, float(entry["contrast"]), Color(String(entry.get("tint", "00000000"))))
	if entry.has("grade_saturation") or entry.has("grade_value"):
		_grade(image, float(entry.get("grade_saturation", 1.0)), float(entry.get("grade_value", 1.0)), float(entry.get("grade_hue", 0.0)))
	if bool(entry.get("palette", true)) and not _palette.is_empty():
		_snap_palette(image, float(entry.get("saturation", 1.0)), float(entry.get("value", 1.0)))
	if mode == "sprite" and bool(entry.get("outline", true)):
		image = _add_outline(image)
	var max_height := int(entry.get("max_height", 0))
	if max_height > 0 and image.get_height() > max_height:
		var ratio := float(max_height) / float(image.get_height())
		image.resize(maxi(1, int(round(image.get_width() * ratio))), max_height, Image.INTERPOLATE_NEAREST)
	return image


## Separa uma folha com vários objetos em sprites independentes, do maior para o menor.
func _split_entry(entry: Dictionary) -> Array[Image]:
	var raw := Image.load_from_file(ProjectSettings.globalize_path("res://art/" + String(entry["source"])))
	raw.convert(Image.FORMAT_RGBA8)
	var image := _downsample(raw, int(entry.get("block", 8)), true)
	_remove_border_background(image)
	var minimum := int(entry.get("min_pixels", 40))
	var limit := int(entry.get("max_pieces", 6))
	var components := _components(image)
	components.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return (left["pixels"] as Array).size() > (right["pixels"] as Array).size()
	)
	var result: Array[Image] = []
	for component in components:
		if result.size() >= limit or (component["pixels"] as Array).size() < minimum:
			break
		var bounds := component["bounds"] as Rect2i
		var piece := Image.create_empty(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
		for point: Vector2i in component["pixels"]:
			piece.set_pixelv(point - bounds.position, image.get_pixelv(point))
		if bool(entry.get("palette", true)) and not _palette.is_empty():
			_snap_palette(piece, 1.0, 1.0)
		result.append(_add_outline(piece))
	return result


func _downsample(raw: Image, block: int, transparent_allowed: bool) -> Image:
	var width := raw.get_width() / block
	var height := raw.get_height() / block
	var result := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for by in range(height):
		for bx in range(width):
			var counts := {}
			var opaque := 0
			for y in range(by * block, (by + 1) * block):
				for x in range(bx * block, (bx + 1) * block):
					var color := raw.get_pixel(x, y)
					if color.a < 0.5 and transparent_allowed:
						continue
					opaque += 1
					var key := Color(snappedf(color.r, 1.0 / 32.0), snappedf(color.g, 1.0 / 32.0), snappedf(color.b, 1.0 / 32.0), 1.0)
					counts[key] = int(counts.get(key, 0)) + 1
			if opaque * 2 < block * block:
				result.set_pixel(bx, by, Color(0, 0, 0, 0))
				continue
			var best := Color(0, 0, 0, 0)
			var best_count := -1
			for key: Variant in counts:
				if int(counts[key]) > best_count:
					best_count = int(counts[key])
					best = key as Color
			result.set_pixel(bx, by, best)
	return result


func _is_background(color: Color) -> bool:
	return color.a < 0.5 or (color.v > 0.86 and color.s < 0.14)


func _remove_border_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := {}
	var stack: Array[Vector2i] = []
	for x in range(width):
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, height - 1))
	for y in range(height):
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(width - 1, y))
	while not stack.is_empty():
		var point: Vector2i = stack.pop_back()
		if visited.has(point) or point.x < 0 or point.y < 0 or point.x >= width or point.y >= height:
			continue
		visited[point] = true
		if not _is_background(image.get_pixelv(point)):
			continue
		image.set_pixelv(point, Color(0, 0, 0, 0))
		stack.append(point + Vector2i.LEFT)
		stack.append(point + Vector2i.RIGHT)
		stack.append(point + Vector2i.UP)
		stack.append(point + Vector2i.DOWN)


func _remove_all_background(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if _is_background(image.get_pixel(x, y)):
				image.set_pixel(x, y, Color(0, 0, 0, 0))


func _components(image: Image) -> Array[Dictionary]:
	var width := image.get_width()
	var height := image.get_height()
	var labels := {}
	var components: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			var start := Vector2i(x, y)
			if labels.has(start) or image.get_pixelv(start).a < 0.5:
				continue
			var label := components.size()
			var pixels: Array[Vector2i] = []
			var bounds := Rect2i(start, Vector2i.ONE)
			var stack: Array[Vector2i] = [start]
			labels[start] = label
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				pixels.append(point)
				bounds = bounds.expand(point).expand(point + Vector2i.ONE)
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var next := point + Vector2i(dx, dy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						if labels.has(next) or image.get_pixelv(next).a < 0.5:
							continue
						labels[next] = label
						stack.append(next)
			components.append({"pixels": pixels, "bounds": bounds})
	return components


func _keep_main_body(image: Image) -> void:
	var components := _components(image)
	if components.size() <= 1:
		return
	var main_index := 0
	for index in range(components.size()):
		if (components[index]["pixels"] as Array).size() > (components[main_index]["pixels"] as Array).size():
			main_index = index
	var main_bounds := (components[main_index]["bounds"] as Rect2i).grow(1)
	for index in range(components.size()):
		if index == main_index:
			continue
		var bounds := components[index]["bounds"] as Rect2i
		var center := bounds.position + bounds.size / 2
		if main_bounds.has_point(center) and (components[index]["pixels"] as Array).size() >= 2:
			continue
		for point: Vector2i in components[index]["pixels"]:
			image.set_pixelv(point, Color(0, 0, 0, 0))


func _crop_to_content(image: Image) -> Image:
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return image
	return image.get_region(used)


func _snap_palette(image: Image, saturation: float, value: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var adjusted := Color.from_hsv(color.h, clampf(color.s * saturation, 0.0, 1.0), clampf(color.v * value, 0.0, 1.0))
			var best := _palette[0]
			var best_distance := INF
			for candidate in _palette:
				var dr := (adjusted.r - candidate.r) * 0.30
				var dg := (adjusted.g - candidate.g) * 0.59
				var db := (adjusted.b - candidate.b) * 0.11
				var distance := dr * dr + dg * dg + db * db + pow((adjusted.h - candidate.h) * adjusted.s * candidate.s * 0.15, 2.0)
				if distance < best_distance:
					best_distance = distance
					best = candidate
			image.set_pixel(x, y, best)


## Aproxima cada pixel da cor média (e de um tom opcional) para tiles de chão discretos.
func _reduce_contrast(image: Image, amount: float, tint: Color) -> void:
	var total := Color(0, 0, 0, 0)
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a >= 0.5:
				total += color
				count += 1
	if count == 0:
		return
	var mean := total / float(count)
	if tint.a > 0.0:
		mean = mean.lerp(Color(tint, 1.0), tint.a)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a >= 0.5:
				image.set_pixel(x, y, Color(color.lerp(mean, amount), 1.0))


func _grade(image: Image, saturation: float, value: float, hue_shift: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a >= 0.5:
				image.set_pixel(x, y, Color.from_hsv(fposmod(color.h + hue_shift, 1.0), clampf(color.s * saturation, 0.0, 1.0), clampf(color.v * value, 0.0, 1.0)))


func _add_outline(image: Image) -> Image:
	var padded := Image.create_empty(image.get_width() + 2, image.get_height() + 2, false, Image.FORMAT_RGBA8)
	padded.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ONE)
	var result := padded.duplicate() as Image
	for y in range(padded.get_height()):
		for x in range(padded.get_width()):
			if padded.get_pixel(x, y).a >= 0.5:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor := Vector2i(x, y) + offset
				if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= padded.get_width() or neighbor.y >= padded.get_height():
					continue
				if padded.get_pixelv(neighbor).a >= 0.5:
					result.set_pixel(x, y, _outline_color)
					break
	return result


func _save_preview(images: Array[Image]) -> void:
	var cell := 0
	for image in images:
		cell = maxi(cell, maxi(image.get_width(), image.get_height()))
	var columns := mini(images.size(), 6)
	var rows := int(ceil(float(images.size()) / float(columns)))
	var sheet := Image.create_empty(columns * (cell + 4), rows * (cell + 4), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("8f8a80"))
	for index in range(images.size()):
		var image := images[index]
		var origin := Vector2i((index % columns) * (cell + 4) + 2, (index / columns) * (cell + 4) + 2)
		origin += Vector2i((cell - image.get_width()) / 2, cell - image.get_height())
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), origin)
	sheet.resize(sheet.get_width() * PREVIEW_SCALE, sheet.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW_PATH))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}
