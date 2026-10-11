extends RefCounted

const WALL := "props/galeria_muro_baixo"
const SIDE := "props/galeria_muro_lateral"
const ARCH := "props/galeria_arco_partido"
const NICHE := "props/galeria_nicho"
const FOOTPRINTS := {
	WALL: Rect2(-86, -20, 172, 20), SIDE: Rect2(-20, -115, 40, 110),
	ARCH: Rect2(-75, -24, 150, 24), NICHE: Rect2(-42, -24, 84, 24),
}
const NAMES := ["patio", "claustro", "arquivo_arruinado"]

static func compose(layout: Dictionary, number: int) -> void:
	var variant := posmod(number - 1, NAMES.size())
	layout["composition"] = NAMES[variant]
	layout["rooms"] = [] as Array[Dictionary]
	var route := layout["route"] as Array
	var entry: Vector2 = layout["entry"]
	# A low wall on either side frames arrival without closing the portal clearing.
	for side: float in [-1.0, 1.0]:
		_add(layout, entry + Vector2(150, side * 280), WALL)
	for index in [1, 2]:
		var center: Vector2 = route[index]
		var extent := Vector2(720 if variant == 0 else 620, 560 if variant == 1 else 520)
		var room := Rect2(center - extent * 0.5, extent)
		(layout["rooms"] as Array[Dictionary]).append({"rect": room, "kind": NAMES[(variant + index - 1) % NAMES.size()]})
		# Interrupted north/south walls leave broad exits and flanking combat pockets.
		for side: float in [-1.0, 1.0]:
			for offset: float in [-220.0, 0.0, 220.0]:
				if offset == 0 and side > 0:
					continue
				_add(layout, center + Vector2(offset, side * extent.y * 0.5), WALL)
		if variant == 1:
			_add(layout, center + Vector2(-370, -220), SIDE)
			_add(layout, center + Vector2(370, 340), SIDE)
		var landmark := NICHE if (variant + index) % 2 == 0 else ARCH
		_add(layout, center + Vector2(0, extent.y * 0.5 - 20), landmark)
		if variant == 2:
			_add(layout, center + Vector2(220, -205), "props/shelf")
			_add(layout, center + Vector2(-220, -205), "props/shelf")
			_add(layout, center + Vector2(210, 215), "props/crates")
		(layout["landmarks"] as Array[Dictionary]).append({"center": center + Vector2(0, extent.y * 0.5 - 20), "sprite": landmark})
		(layout["lights"] as Array[Vector2]).append(center + Vector2(0, -210))
	var branch: Array = layout.get("side_route", [])
	if branch.size() == 2:
		# Stone lips frame the optional passage outside its protected walkable strip.
		for side: float in [-1.0, 1.0]:
			for offset: float in [-150.0, -300.0]:
				_add(layout, (branch[0] as Vector2) + Vector2(side * 210, offset), SIDE)
		_add(layout, (branch[1] as Vector2) + Vector2(0, -220), NICHE)
	_add(layout, (layout["stairs"] as Rect2).get_center() + Vector2(-180, -280), NICHE)

static func decorate_arena(layout: Dictionary) -> void:
	layout["composition"] = "camara_de_enxerto"
	var center: Vector2 = layout["arena_center"]
	var radius := float(layout["arena_radius"])
	# External architectural markers have no gameplay collision outside the arena.
	for offset: Vector2 in [Vector2(-radius - 40, -80), Vector2(radius + 40, -80)]:
		(layout["props"] as Array[Dictionary]).append({"sprite": NICHE, "base": center + offset})
	(layout["props"] as Array[Dictionary]).append({"sprite": ARCH, "base": center + Vector2(0, -radius - 90)})

static func _add(layout: Dictionary, base: Vector2, sprite: String) -> void:
	var footprint: Rect2 = FOOTPRINTS.get(sprite, Rect2(-26, -20, 52, 20))
	var solid := Rect2(base + footprint.position, footprint.size)
	var branch: Array = layout.get("side_route", [])
	if branch.size() == 2:
		for corner: Vector2 in [solid.position, solid.end, Vector2(solid.position.x, solid.end.y), Vector2(solid.end.x, solid.position.y), solid.get_center()]:
			if Geometry2D.get_closest_point_to_segment(corner, branch[0], branch[1]).distance_to(corner) < 150:
				return
	if not Rect2(Vector2(40, 80), (layout["size"] as Vector2) - Vector2(80, 120)).encloses(solid):
		return
	var route := layout["route"] as Array
	for index in range(route.size() - 1):
		var a: Vector2 = route[index]
		var b: Vector2 = route[index + 1]
		# Test the entire footprint, not only its anchor, against the protected spine.
		for corner: Vector2 in [solid.position, solid.end, Vector2(solid.position.x, solid.end.y), Vector2(solid.end.x, solid.position.y), solid.get_center()]:
			if Geometry2D.get_closest_point_to_segment(corner, a, b).distance_to(corner) < 190:
				return
	for other: Rect2 in layout["obstacles"]:
		if other.grow(24).intersects(solid):
			return
	var footprints: Array[Rect2] = []
	if sprite == ARCH:
		footprints.append(Rect2(-75, -24, 34, 24))
		footprints.append(Rect2(41, -24, 34, 24))
	else:
		footprints.append(footprint)
	for part in footprints:
		(layout["obstacles"] as Array[Rect2]).append(Rect2(base + part.position, part.size))
	(layout["props"] as Array[Dictionary]).append({"sprite": sprite, "base": base, "solid": footprint, "solids": footprints})
