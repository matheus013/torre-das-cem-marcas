extends SceneTree

const ICONS := ["cometa_de_vidro", "bolha_corrosiva", "esfera_de_gelo", "raio_prismatico", "ceifa_ampla", "ruptura_sismica", "elo_residual", "muralha_refeita"]
const FIELDS := ["flame_field", "acid_pool", "gravity_field", "root_field"]
const SUPPORT := ["holy_field", "living_field", "steel_blade", "ice_crystal"]
const FIELD_BANDS := [Vector2i(0, 291), Vector2i(296, 589), Vector2i(592, 891), Vector2i(896, 1187)]
const SUPPORT_BANDS := [Vector2i(0, 288), Vector2i(292, 598), Vector2i(603, 784), Vector2i(790, 1024)]
const RAW := "res://art/raw/skills-v2/"


func _init() -> void:
	var icons := Image.load_from_file(RAW + "icons.png")
	var fields := Image.load_from_file(RAW + "fields.png")
	var support := Image.load_from_file(RAW + "support.png")
	for image: Image in [icons, fields, support]:
		if image == null or image.is_empty():
			push_error("Missing skill source sheet")
			quit(1)
			return
		print("SOURCE ", image.get_size(), " corner alpha=", image.get_pixel(0, 0).a)
		if image.get_pixel(0, 0).a > 0.05:
			push_error("Source background must be transparent")
			quit(1)
			return
	for index in ICONS.size():
		var cell := _cell(icons, index % 4, index / 4, 4, 2)
		var visible := cell.get_used_rect()
		cell = cell.get_region(visible)
		var size := Vector2(cell.get_size())
		cell.resize(maxi(1, roundi(size.x * 56.0 / maxf(size.x, size.y))), maxi(1, roundi(size.y * 56.0 / maxf(size.x, size.y))), Image.INTERPOLATE_LANCZOS)
		var output := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		output.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), (Vector2i(64, 64) - cell.get_size()) / 2)
		output.save_png("res://assets/sprites/icons/" + String(ICONS[index]) + ".png")
	_import_rows(fields, FIELDS, FIELD_BANDS)
	_import_rows(support, SUPPORT, SUPPORT_BANDS)
	print("SKILL_ASSETS_IMPORTED: 8 icons, 8 four-frame strips")
	quit(0)


func _cell(source: Image, column: int, row: int, columns: int, rows: int) -> Image:
	var start := Vector2i(column * source.get_width() / columns, row * source.get_height() / rows)
	var end := Vector2i((column + 1) * source.get_width() / columns, (row + 1) * source.get_height() / rows)
	return source.get_region(Rect2i(start, end - start))


func _import_rows(source: Image, names: Array, bands: Array) -> void:
	for row in names.size():
		var output := Image.create(256, 64, false, Image.FORMAT_RGBA8)
		# One shared scale per row preserves frame geometry and avoids animation jitter.
		var band := bands[row] as Vector2i
		var size := Vector2i(source.get_width() / 4, band.y - band.x)
		var scale := 56.0 / maxf(size.x, size.y)
		for column in 4:
			var cell := source.get_region(Rect2i(column * source.get_width() / 4, band.x, size.x, size.y))
			cell.convert(Image.FORMAT_RGBA8)
			cell.resize(maxi(1, roundi(size.x * scale)), maxi(1, roundi(size.y * scale)), Image.INTERPOLATE_LANCZOS)
			output.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(column * 64, 0) + (Vector2i(64, 64) - cell.get_size()) / 2)
		output.save_png("res://assets/sprites/vfx/anim/sk_" + String(names[row]) + ".png")
