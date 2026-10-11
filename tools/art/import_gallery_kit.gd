extends SceneTree

const SOURCE := "res://art/generated/gallery_kit_v1.png"
const MODULES := [
	["galeria_muro_baixo", Rect2(0, 0, 0.64, 0.42), Vector2i(192, 80)],
	["galeria_muro_lateral", Rect2(0.65, 0, 0.35, 0.42), Vector2i(96, 160)],
	["galeria_arco_partido", Rect2(0, 0.43, 0.59, 0.57), Vector2i(192, 192)],
	["galeria_nicho", Rect2(0.60, 0.43, 0.40, 0.57), Vector2i(128, 160)],
]

func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null or source.is_empty() or source.detect_alpha() == Image.ALPHA_NONE:
		push_error("Missing transparent gallery source atlas")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	for module: Array in MODULES:
		var rect: Rect2 = module[1]
		var image := source.get_region(Rect2i(Vector2i(rect.position * Vector2(source.get_size())), Vector2i(rect.size * Vector2(source.get_size()))))
		var bounds := image.get_used_rect()
		if bounds.size == Vector2i.ZERO:
			push_error("Empty gallery module: " + String(module[0]))
			quit(1)
			return
		image = image.get_region(bounds)
		var target: Vector2i = module[2]
		var ratio := minf(float(target.x - 4) / image.get_width(), float(target.y - 4) / image.get_height())
		image.resize(maxi(1, roundi(image.get_width() * ratio)), maxi(1, roundi(image.get_height() * ratio)), Image.INTERPOLATE_NEAREST)
		var canvas := Image.create_empty(target.x, target.y, false, Image.FORMAT_RGBA8)
		canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i((target.x - image.get_width()) / 2, target.y - image.get_height() - 2))
		assert(canvas.save_png(ProjectSettings.globalize_path("res://assets/sprites/props/" + String(module[0]) + ".png")) == OK)
	print("GALLERY_KIT_IMPORTED: four modules, original alpha preserved, nearest-neighbor sampling")
	quit(0)
