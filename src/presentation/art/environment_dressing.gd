extends RefCounted

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
const World := preload("res://src/gameplay/world/world_layout.gd")
const Tower := preload("res://src/gameplay/world/tower_content.gd")
const CELL := 240.0
const PARTICLE_BUDGET := 28
const PROFILES := {
	"galerias": ["tiles/floor_arquivo", "deco/rock_4", "deco/rock_5", Color("b8bbb1")],
	"bosque": ["tiles/grass", "deco/bush_b_2", "deco/flower_6", Color("bbcaa0")],
	"manto": ["tiles/floor_bosque", "deco/bush_b_3", "deco/rock_5", Color("bdb79f")],
	"bacias": ["tiles/floor_tower", "deco/rock_4", "deco/rock_6", Color("a4c7c8")],
	"ermo": ["tiles/floor_tower", "deco/rock_3", "deco/rock_5", Color("b4aaa3")],
	"arquivo": ["tiles/floor_tower", "deco/rock_4", "deco/rock_6", Color("cdc6a2")],
	"planicie": ["tiles/floor_bosque", "deco/bush_b_3", "deco/rock_6", Color("c2bbad")],
	"eixos": ["tiles/floor_tower", "deco/rock_4", "deco/rock_5", Color("acbcb8")],
	"campos": ["tiles/grass", "deco/flower_5", "deco/bush_b_2", Color("bfcaa8")],
	"obra": ["tiles/floor_tower", "deco/rock_3", "deco/rock_6", Color("c8bbaa")],
}
static var _plans: Dictionary = {}

# Presentation-only details never add invisible obstacles or alter the simulation RNG.
static func plan(zone: StringName, floor: Dictionary) -> Dictionary:
	var key := "%s:%d" % [zone, int(floor.get("floor", 0)) if zone == &"tower" else 0]
	if _plans.has(key):
		return _plans[key]
	var result := {"patches": [] as Array[Dictionary], "details": [] as Array[Dictionary], "rugs": [] as Array[Rect2], "beams": [] as Array[PackedVector2Array], "ambient": Color("c5ceb3")}
	var random := RandomNumberGenerator.new()
	random.seed = 4081 + int(floor.get("floor", 0)) * 137
	match zone:
		&"tower":
			if floor.is_empty():
				return result
			_tower(result, floor, random)
		&"village":
			_village(result, random)
		&"house":
			var room := World.HOUSE_ROOM
			result["rugs"].append(Rect2(560, 375, 180, 180))
			result["rugs"].append(Rect2(400, 295, 100, 115))
			# Light cast by the existing north-wall window, not a combat telegraph.
			result["beams"].append(PackedVector2Array([room.position + Vector2(206, 0), room.position + Vector2(254, 0), room.position + Vector2(330, 185), room.position + Vector2(175, 185)]))
		&"boss_room":
			for x in [240, 560, 880]:
				_patch(result, "tiles/floor_arquivo", Rect2(x, 245, 150, 230), Color("a5ada4"), random, false)
	_plans[key] = result
	return result

static func _tower(result: Dictionary, floor: Dictionary, random: RandomNumberGenerator) -> void:
	var biome := String(floor["biome"])
	var profile: Array = PROFILES.get(biome, PROFILES["galerias"])
	result["ambient"] = profile[3]
	var size: Vector2 = floor["size"]
	var tile := String(Tower.biome(biome)["tile"])
	var arena := floor.has("arena_center")
	for room: Dictionary in floor.get("rooms", []):
		var rect: Rect2 = room["rect"]
		_patch(result, tile, rect, Color(1.16, 1.2, 1.15, 0.15), random, false)
		# Worn stone borders identify rooms without painting a hazard outline.
		for y: float in [rect.position.y + 35, rect.end.y - 35]:
			_patch(result, "tiles/floor_arquivo", Rect2(rect.position.x + 35, y, rect.size.x - 70, 14), Color(0.9, 0.96, 0.9, 0.5), random, false)
		for x: float in [rect.position.x + 35, rect.end.x - 49]:
			_patch(result, "tiles/floor_arquivo", Rect2(x, rect.position.y + 35, 14, rect.size.y - 70), Color(0.9, 0.96, 0.9, 0.5), random, false)
	for x in range(1, int(size.x / CELL)):
		for y in range(1, int(size.y / CELL)):
			var center := Vector2(x, y) * CELL + Vector2(random.randf_range(-65, 65), random.randf_range(-55, 55))
			if arena and center.distance_to(floor["arena_center"]) > float(floor["arena_radius"]) - 130.0:
				continue
			var extent := Vector2(random.randf_range(90, 175), random.randf_range(55, 120))
			_patch(result, tile, Rect2(center - extent * 0.5, extent), Color(0.7, 0.77, 0.73, 0.22), random)
			if (x + y) % 3 == 0:
				_patch(result, String(profile[0]), Rect2(center + Vector2(30, 20), extent * 0.65), Color(0.8, 0.86, 0.8, 0.38), random)
			for detail in range(3):
				result["details"].append({"sprite": profile[1 + detail % 2], "base": center + Vector2(random.randf_range(-65, 65), random.randf_range(-45, 45))})
	if not arena:
		var route := floor["route"] as Array
		for segment in range(route.size() - 1):
			var start: Vector2 = route[segment]
			var end: Vector2 = route[segment + 1]
			var count := maxi(1, int(start.distance_to(end) / 140.0))
			for index in range(count + 1):
				var center := start.lerp(end, float(index) / count)
				_patch(result, tile, Rect2(center - Vector2(64, 40), Vector2(128, 80)), Color(1.18, 1.2, 1.15, 0.2), random)
		# Arrival and destination have a recognizable, worn threshold.
		for center: Vector2 in [floor["entry"], (floor["stairs"] as Rect2).get_center()]:
			_patch(result, tile, Rect2(center - Vector2(150, 100), Vector2(300, 200)), Color(1.12, 1.16, 1.1, 0.2), random)
	else:
		var center: Vector2 = floor["arena_center"]
		for offset: Vector2 in [Vector2(-110, -70), Vector2(30, -70), Vector2(-110, 50), Vector2(30, 50)]:
			_patch(result, String(profile[0]), Rect2(center + offset, Vector2(80, 80)), Color(0.8, 0.86, 0.8, 0.4), random)

static func _village(result: Dictionary, random: RandomNumberGenerator) -> void:
	for piece: Dictionary in World.VILLAGE_PIECES:
		if not String(piece["sprite"]).begins_with("buildings/"):
			continue
		var base: Vector2 = piece["base"]
		# Doorsteps connect each house to the street; flowers frame the sides only.
		_patch(result, "tiles/floor_tower", Rect2(base + Vector2(-42, -2), Vector2(84, 42)), Color(0.8, 0.88, 0.76, 0.5), random)
		for side: float in [-1.0, 1.0]:
			var center := base + Vector2(side * 110, -12)
			_patch(result, "tiles/grass", Rect2(center - Vector2(45, 20), Vector2(90, 40)), Color("849d77"), random)
			for index in range(4):
				result["details"].append({"sprite": "deco/flower_%d" % (4 + index % 3), "base": center + Vector2(index * 16 - 24, index % 2 * 10)})
	for x in range(1470, 1890, 100):
		_patch(result, "tiles/floor_tower", Rect2(x, 1290, 72, 190), Color(0.8, 0.88, 0.76, 0.4), random, false)

static func _patch(result: Dictionary, tile: String, rect: Rect2, tint: Color, random: RandomNumberGenerator, chipped := true) -> void:
	var cut := random.randf_range(8, 18) if chipped else 0.0
	var p := rect.position.round()
	var e := rect.end.round()
	_polygon(result, tile, PackedVector2Array([p + Vector2(cut, 0), Vector2(e.x - cut, p.y), Vector2(e.x, p.y + cut), e - Vector2(0, cut), e - Vector2(cut, 0), Vector2(p.x + cut, e.y), Vector2(p.x, e.y - cut), p + Vector2(0, cut)]), tint)

static func _polygon(result: Dictionary, tile: String, points: PackedVector2Array, tint: Color) -> void:
	var texture := Sprites.texture(tile)
	var mesh := ArrayMesh.new()
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := Geometry2D.triangulate_polygon(points)
	for index in indices:
		vertices.append(points[index])
		uvs.append(points[index] / texture.get_size())
		colors.append(tint)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	result["patches"].append({"mesh": mesh, "texture": texture, "tint": tint, "bounds": bounds})

static func draw_ground(canvas: Node2D, data: Dictionary, visible: Rect2) -> void:
	for patch: Dictionary in data["patches"]:
		if visible.intersects(patch["bounds"]):
			canvas.draw_mesh(patch["mesh"], patch["texture"])
	for detail: Dictionary in data["details"]:
		var base: Vector2 = detail["base"]
		if not visible.grow(64).has_point(base):
			continue
		var texture := Sprites.texture(detail["sprite"])
		canvas.draw_texture(texture, (base - Vector2(texture.get_width() * 0.5, texture.get_height())).round(), Color(0.8, 0.85, 0.8))
	for rug: Rect2 in data["rugs"]:
		canvas.draw_rect(rug, Color("744556"))
		canvas.draw_rect(rug.grow(-5), Color("b9a88b"), false, 3)
		canvas.draw_rect(rug.grow(-12), Color("497779"), false, 5)
		for x in range(int(rug.position.x) + 8, int(rug.end.x) - 8, 8):
			canvas.draw_line(Vector2(x, rug.position.y - 3), Vector2(x, rug.position.y + 2), Color("b9a88b"), 2)
			canvas.draw_line(Vector2(x, rug.end.y - 2), Vector2(x, rug.end.y + 3), Color("b9a88b"), 2)
	for beam: PackedVector2Array in data["beams"]:
		canvas.draw_colored_polygon(beam, Color(0.95, 0.96, 0.78, 0.16))

static func draw_ambient(canvas: Node2D, data: Dictionary, visible: Rect2, elapsed: float, zone: StringName) -> void:
	if zone == &"house":
		visible = visible.intersection(World.HOUSE_ROOM)
	if not visible.has_area():
		return
	var tint: Color = data["ambient"]
	# Small, subdued motes; fixed budget, no hazard colors or screen-sized fog.
	var count := 0
	for x in range(floori(visible.position.x / CELL), ceili(visible.end.x / CELL)):
		for y in range(floori(visible.position.y / CELL), ceili(visible.end.y / CELL)):
			if count >= PARTICLE_BUDGET:
				return
			var phase := float(x * 13 + y * 7)
			var offset := Vector2(fposmod(phase * 17 + elapsed * 9, CELL), fposmod(phase * 29 - elapsed * 4, CELL))
			var point := Vector2(x, y) * CELL + offset
			if not visible.has_point(point):
				continue
			count += 1
			canvas.draw_rect(Rect2(point.round(), Vector2(2, 2)), Color(tint, 0.12 + 0.1 * sin(elapsed * 0.8 + phase)))
