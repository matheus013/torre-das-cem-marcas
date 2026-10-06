extends SceneTree

const Floor := preload("res://src/gameplay/world/floor_layout.gd")
const Layout := preload("res://src/gameplay/world/world_layout.gd")
const Navigation := preload("res://src/simulation/npc/village_navigation.gd")

func _init() -> void:
	_run()

func _run() -> void:
	var spots := Layout.village_spots()
	var navigation := Navigation.new()
	navigation.setup(Layout.WORLD_SIZE, spots["blocked"])
	for destination: Vector2 in (spots["homes"] as Array) + (spots["work"] as Dictionary).values() + (spots["social"] as Array) + (spots["patrol"] as Array):
		if navigation.route(Layout.WORLD_SPAWN, destination).is_empty():
			return _fail("Unreachable village point: %s" % destination)
	for node: Dictionary in spots["resources"]:
		if navigation.route(node["position"], spots["warehouse"]).is_empty():
			return _fail("Unreachable resource: " + String(node["id"]))
	for piece in Layout.VILLAGE_PIECES:
		if not FileAccess.file_exists("res://assets/sprites/" + String(piece["sprite"]) + ".png"):
			return _fail("Missing village sprite")
		if String(piece["sprite"]).begins_with("buildings/"):
			var footprint := Rect2((piece["base"] as Vector2) + (piece["solid"] as Rect2).position, (piece["solid"] as Rect2).size)
			for road in Layout.VILLAGE_ROADS:
				if footprint.intersects(road):
					return _fail("Building blocks a street: %s" % piece)
	for number in range(1, 101):
		var floor := Floor.generate(number)
		var entry := floor["entry"] as Vector2
		var stairs := (floor["stairs"] as Rect2).get_center()
		if not Floor.can_stand(floor, entry, 14) or not Floor.can_stand(floor, stairs, 14):
			return _fail("Blocked entrance/stairs on floor %d" % number)
		navigation.setup(floor["size"], floor["obstacles"])
		if navigation.route(entry, stairs).is_empty():
			return _fail("Disconnected floor %d" % number)
		for point: Vector2 in floor["spawn_points"]:
			if not Floor.can_stand(floor, point, 14) or navigation.route(entry, point).is_empty():
				return _fail("Unreachable spawn on floor %d at %s; can_stand=%s" % [number, point, Floor.can_stand(floor, point, 14)])
		if not floor.has("arena_center"):
			var route := floor["route"] as Array
			for piece: Dictionary in floor["props"]:
				for index in range(route.size() - 1):
					if Geometry2D.get_closest_point_to_segment(piece["base"], route[index], route[index + 1]).distance_to(piece["base"]) < 180:
						return _fail("Blocked route on floor %d" % number)
	print("MAP_CONNECTIVITY_OK: village homes, work, production, streets, all 100 floors and enemy spawns")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
