extends SceneTree

const Dressing := preload("res://src/presentation/art/environment_dressing.gd")
const Floor := preload("res://src/gameplay/world/floor_layout.gd")
const Sprites := preload("res://src/presentation/art/sprite_library.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var biomes := {}
	for number in range(1, 101):
		var floor := Floor.generate(number)
		var obstacles := (floor["obstacles"] as Array).duplicate()
		var data := Dressing.plan(&"tower", floor)
		if data["patches"].is_empty() or data["details"].is_empty():
			return _fail("Undressed floor %d" % number)
		if data != Dressing.plan(&"tower", floor) or floor["obstacles"] != obstacles:
			return _fail("Presentation mutated collision or failed to reuse its plan")
		for detail: Dictionary in data["details"]:
			if Sprites.texture(detail["sprite"]) == null or not Rect2(Vector2.ZERO, floor["size"]).has_point(detail["base"]):
				return _fail("Missing or out-of-bounds ground detail")
		for patch: Dictionary in data["patches"]:
			if patch["texture"] == null or patch["mesh"].get_surface_count() != 1:
				return _fail("Missing baked ground mesh")
			if not Rect2(Vector2.ZERO, floor["size"]).encloses(patch["bounds"]):
				return _fail("Ground patch exceeds floor bounds")
		if not (floor.get("rooms", []) as Array).is_empty():
			var details := (data["details"] as Array).duplicate(true)
			Dressing._plans.clear()
			if Dressing.plan(&"tower", floor)["details"] != details:
				return _fail("Architectural wear is not deterministic")
		if not floor.has("arena_center") and (floor["props"] as Array).size() < 20:
			return _fail("Too few roadside silhouettes on floor %d" % number)
		biomes[floor["biome"]] = true
	if biomes.size() != 10 or Dressing.PARTICLE_BUDGET > 28:
		return _fail("Biome coverage or ambient budget changed")
	for zone: StringName in [&"village", &"house", &"boss_room"]:
		var data := Dressing.plan(zone, {})
		if data["patches"].is_empty() and data["rugs"].is_empty():
			return _fail("Undressed static zone: " + String(zone))
	print("ENVIRONMENT_DRESSING_OK: 100 floors, ten profiles, static zones, baked meshes, valid assets and unchanged collisions")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
