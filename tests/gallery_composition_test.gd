extends SceneTree

const Floor := preload("res://src/gameplay/world/floor_layout.gd")
const Gallery := preload("res://src/gameplay/world/gallery_composition.gd")
const Sprites := preload("res://src/presentation/art/sprite_library.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for sprite: String in Gallery.FOOTPRINTS:
		var texture := Sprites.texture(sprite)
		if texture == null:
			return _fail("Missing gallery asset: " + sprite)
		var image := texture.get_image()
		var bounds := image.get_used_rect()
		if bounds.size == Vector2i.ZERO or bounds.position.x <= 0 or bounds.position.y <= 0 or bounds.end.x >= image.get_width() or bounds.end.y >= image.get_height():
			return _fail("Empty or clipped gallery sprite: " + sprite)
	var variants := {}
	for number in [1, 2, 3, 5, 6]:
		var floor := Floor.generate(number)
		variants[floor.get("composition", "")] = true
		if (floor.get("rooms", []) as Array).size() != 2:
			return _fail("Gallery lacks two readable rooms")
		var architecture := 0
		for piece: Dictionary in floor["props"]:
			if not String(piece["sprite"]).begins_with("props/galeria_"):
				continue
			architecture += 1
			if not piece.has("solids"):
				return _fail("Architecture has no shared collision footprints")
			for solid: Rect2 in piece["solids"]:
				if not (floor["obstacles"] as Array).has(Rect2((piece["base"] as Vector2) + solid.position, solid.size)):
					return _fail("Architecture collision differs from its footprint")
			if piece["sprite"] == Gallery.ARCH and not Floor.can_stand(floor, (piece["base"] as Vector2) - Vector2(0, 12), 14):
				return _fail("The visible arch opening is blocked")
		if architecture < 10:
			return _fail("Gallery architecture too sparse: %d" % architecture)
		var sprites: Array = (floor["props"] as Array).map(func(piece: Dictionary) -> String: return String(piece["sprite"]))
		if floor["composition"] == "claustro" and not sprites.has(Gallery.SIDE):
			return _fail("Cloister lost its lateral wall silhouette")
		if floor["composition"] == "arquivo_arruinado" and not sprites.has("props/shelf"):
			return _fail("Ruined archive lost its shelving")
		Floor._cache.erase(number)
		var regenerated := Floor.generate(number)
		if regenerated["props"] != floor["props"] or regenerated["obstacles"] != floor["obstacles"]:
			return _fail("Gallery composition is not deterministic")
	if variants.size() != 3:
		return _fail("Gallery variants are missing")
	for number in [4, 7]:
		if Floor.generate(number).get("composition", "") != "camara_de_enxerto":
			return _fail("Gallery arena lacks its architectural markers")
	if Floor.generate(11).has("rooms"):
		return _fail("Gallery architecture leaked into a different biome")
	print("GALLERY_COMPOSITION_OK: four generated sprites, three deterministic layouts, shared collision, two rooms and boss markers")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
