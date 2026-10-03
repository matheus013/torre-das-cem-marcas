class_name FloorLayout
extends RefCounted

## Mapa determinístico de um andar a partir do número e da semente do conteúdo. Host e clientes
## geram o mesmo resultado, então o layout não trafega pela rede.
## Andares comuns são grandes e abertos à exploração: matas de obstáculos, cristas que formam
## corredores, pontos de patrulha espalhados, entrada com portal de retorno e escada no extremo oposto.
## Andares de chefe são arenas circulares pequenas, cercadas por pilares.

const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")
const CELL := 260.0
const SAFE_RADIUS := 420.0
const PROP_FOOTPRINT := Rect2(-26.0, -16.0, 52.0, 28.0)
## Grade espacial dos obstáculos: a colisão só consulta as células vizinhas.
const GRID := 128.0

static var _cache: Dictionary = {}


static func generate(number: int) -> Dictionary:
	if _cache.has(number):
		return _cache[number] as Dictionary
	var definition := TowerContentScript.floor_def(number)
	var biome := TowerContentScript.biome(String(definition.get("biome", "galerias")))
	var layout := _boss_arena(definition, biome) if String(definition.get("kind", "")) == "boss" else _explore(definition, biome)
	layout["floor"] = number
	layout["grid"] = _build_grid(layout["obstacles"] as Array[Rect2])
	layout["kind"] = String(definition.get("kind", "explore"))
	layout["biome"] = String(definition.get("biome", "galerias"))
	_cache[number] = layout
	return layout


static func _random(definition: Dictionary) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = int(definition.get("seed", 1))
	return random


static func _explore(definition: Dictionary, biome: Dictionary) -> Dictionary:
	var random := _random(definition)
	var raw_size := definition.get("size", [3200, 2400]) as Array
	var size := Vector2(float(raw_size[0]), float(raw_size[1]))
	var entry := Vector2(220.0, size.y * random.randf_range(0.35, 0.65))
	var stairs_center := Vector2(size.x - 220.0, size.y * random.randf_range(0.2, 0.8))
	var layout := {
		"size": size, "entry": entry,
		"return_portal": Rect2(entry + Vector2(-150.0, -60.0), Vector2(70.0, 120.0)),
		"stairs": Rect2(stairs_center - Vector2(45.0, 45.0), Vector2(90.0, 90.0)),
		"obstacles": [] as Array[Rect2], "props": [] as Array[Dictionary], "spawn_points": [] as Array[Vector2],
		"lights": [] as Array[Vector2],
	}
	var sprites := biome.get("props", ["props/rocks"]) as Array
	var keep_clear: Array[Vector2] = [entry, stairs_center]
	# Cristas: fileiras de obstáculos que criam corredores e esconderijos.
	for _ridge in range(int(size.x * size.y / 900000.0)):
		var start := Vector2(random.randf_range(500.0, size.x - 500.0), random.randf_range(300.0, size.y - 300.0))
		var direction := Vector2.RIGHT.rotated(random.randf() * TAU)
		for step in range(random.randi_range(4, 8)):
			_place_prop(layout, start + direction * 70.0 * float(step), String(sprites[random.randi_range(0, sprites.size() - 1)]), keep_clear)
	# Matas soltas por célula.
	var columns := int(size.x / CELL)
	var rows := int(size.y / CELL)
	for column in range(columns):
		for row in range(rows):
			var center := Vector2((float(column) + 0.5) * CELL, (float(row) + 0.5) * CELL) + Vector2(random.randf_range(-80.0, 80.0), random.randf_range(-80.0, 80.0))
			var roll := random.randf()
			if roll < 0.32:
				for _piece in range(random.randi_range(1, 3)):
					_place_prop(layout, center + Vector2(random.randf_range(-60.0, 60.0), random.randf_range(-40.0, 40.0)), String(sprites[random.randi_range(0, sprites.size() - 1)]), keep_clear)
			elif roll < 0.62 and center.distance_to(entry) > 600.0 and _free(layout, center, 50.0):
				(layout["spawn_points"] as Array[Vector2]).append(center)
	for prop: Dictionary in layout["props"]:
		if random.randf() < 0.12:
			(layout["lights"] as Array[Vector2]).append(prop["base"] as Vector2)
	return layout


static func _boss_arena(definition: Dictionary, biome: Dictionary) -> Dictionary:
	var raw_size := definition.get("size", [1400, 1100]) as Array
	var size := Vector2(float(raw_size[0]), float(raw_size[1]))
	var radius := float(definition.get("arena_radius", 430.0))
	var center := Vector2(size.x * 0.5, size.y * 0.5 + 20.0)
	var layout := {
		"size": size, "arena_center": center, "arena_radius": radius,
		"entry": center + Vector2(0.0, radius - 80.0),
		"return_portal": Rect2(center + Vector2(-45.0, radius - 40.0), Vector2(90.0, 50.0)),
		"stairs": Rect2(center + Vector2(-45.0, -radius + 20.0), Vector2(90.0, 70.0)),
		"boss_spawn": center + Vector2(0.0, -radius * 0.35),
		"obstacles": [] as Array[Rect2], "props": [] as Array[Dictionary], "spawn_points": [] as Array[Vector2],
		"lights": [] as Array[Vector2],
	}
	var sprites := biome.get("props", ["props/pillar"]) as Array
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var base := center + Vector2(cos(angle), sin(angle)) * (radius + 60.0)
		(layout["props"] as Array[Dictionary]).append({"sprite": String(sprites[index % sprites.size()]), "base": base})
		if index % 4 == 0:
			(layout["lights"] as Array[Vector2]).append(base)
	for index in range(6):
		var angle := TAU * float(index) / 6.0 + 0.3
		(layout["spawn_points"] as Array[Vector2]).append(center + Vector2(cos(angle), sin(angle)) * radius * 0.7)
	return layout


static func _place_prop(layout: Dictionary, base: Vector2, sprite: String, keep_clear: Array[Vector2]) -> void:
	var size := layout["size"] as Vector2
	if base.x < 80.0 or base.y < 120.0 or base.x > size.x - 80.0 or base.y > size.y - 40.0:
		return
	for spot in keep_clear:
		if base.distance_to(spot) < SAFE_RADIUS:
			return
	var solid := Rect2(base + PROP_FOOTPRINT.position, PROP_FOOTPRINT.size)
	for other: Rect2 in layout["obstacles"]:
		if other.grow(6.0).intersects(solid):
			return
	(layout["obstacles"] as Array[Rect2]).append(solid)
	(layout["props"] as Array[Dictionary]).append({"sprite": sprite, "base": base})


static func _free(layout: Dictionary, position: Vector2, margin: float) -> bool:
	for obstacle: Rect2 in layout["obstacles"]:
		if obstacle.grow(margin).has_point(position):
			return false
	return true


static func _build_grid(obstacles: Array[Rect2]) -> Dictionary:
	var grid := {}
	for obstacle in obstacles:
		var first := Vector2i(floori(obstacle.position.x / GRID), floori(obstacle.position.y / GRID))
		var last := Vector2i(floori(obstacle.end.x / GRID), floori(obstacle.end.y / GRID))
		for x in range(first.x, last.x + 1):
			for y in range(first.y, last.y + 1):
				var key := Vector2i(x, y)
				if not grid.has(key):
					grid[key] = []
				(grid[key] as Array).append(obstacle)
	return grid


## Verdadeiro se um corpo de raio `radius` cabe em `position` (limites, arena e obstáculos).
static func can_stand(layout: Dictionary, position: Vector2, radius: float) -> bool:
	var size := layout["size"] as Vector2
	if position.x < radius or position.y < radius or position.x > size.x - radius or position.y > size.y - radius:
		return false
	if layout.has("arena_center") and position.distance_to(layout["arena_center"] as Vector2) > float(layout["arena_radius"]) - radius:
		return false
	var grid := layout.get("grid", {}) as Dictionary
	var cell := Vector2i(floori(position.x / GRID), floori(position.y / GRID))
	for x in range(cell.x - 1, cell.x + 2):
		for y in range(cell.y - 1, cell.y + 2):
			for obstacle: Rect2 in grid.get(Vector2i(x, y), []) as Array:
				if obstacle.grow(radius).has_point(position):
					return false
	return true
