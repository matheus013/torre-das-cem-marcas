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
	# A readable spine connects entry, two clearings and stairs on every floor.
	var route: Array[Vector2] = [entry, Vector2(size.x * 0.34, size.y * 0.5), Vector2(size.x * 0.66, size.y * 0.5), stairs_center]
	layout["route"] = route
	layout["landmarks"] = [] as Array[Dictionary]
	var keep_clear: Array[Vector2] = [entry, stairs_center]
	for column in range(3):
		for row in range(2):
			var center := Vector2(size.x * (0.25 + float(column) * 0.25), size.y * (0.23 if row == 0 else 0.77))
			center += Vector2(random.randf_range(-50, 50), random.randf_range(-35, 35))
			var primary := String(sprites[(column + row) % sprites.size()])
			(layout["landmarks"] as Array[Dictionary]).append({"center": center, "sprite": primary})
			# Group related props, not alternating buildings in an arbitrary ridge.
			_place_prop(layout, center, primary, keep_clear)
			var companion := String(sprites[(column + row + 1) % sprites.size()])
			if not primary.contains("posto") and not primary.contains("torre") and not primary.contains("ruina") and not primary.contains("monumento"):
				for offset: Vector2 in [Vector2(-170, 0), Vector2(170, 0)]:
					_place_prop(layout, center + offset, primary, keep_clear)
			_place_prop(layout, center + Vector2(0, 180), companion, keep_clear)
			(layout["lights"] as Array[Vector2]).append(center)
	for column in range(1, int(size.x / CELL)):
		for row in range(1, int(size.y / CELL)):
			var center := Vector2(float(column) * CELL, float(row) * CELL)
			if center.distance_to(entry) > 600 and _free(layout, center, 60):
				(layout["spawn_points"] as Array[Vector2]).append(center)
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
		(layout["props"] as Array[Dictionary]).append({"sprite": String(sprites[0]), "base": base})
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
	var route := layout.get("route", []) as Array
	for index in range(route.size() - 1):
		if Geometry2D.get_closest_point_to_segment(base, route[index], route[index + 1]).distance_to(base) < 180.0:
			return
	var solid := Rect2(base + PROP_FOOTPRINT.position, PROP_FOOTPRINT.size)
	for other: Rect2 in layout["obstacles"]:
		if other.grow(75.0).intersects(solid):
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
