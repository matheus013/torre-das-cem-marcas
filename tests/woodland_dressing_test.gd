extends SceneTree

const Floor := preload("res://src/gameplay/world/floor_layout.gd")
const Dressing := preload("res://src/presentation/art/environment_dressing.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var variants := {}
	for number in range(8, 17):
		var floor := Floor.generate(number)
		var original := floor.duplicate(true)
		var plan := Dressing.plan(&"tower", floor)
		variants[plan.get("composition", "")] = true
		if (plan.get("clearings", []) as Array).size() != (1 if floor.has("arena_center") else 2):
			return _fail("Missing woodland clearings")
		if floor != original or plan["details"].size() > 700:
			return _fail("Presentation changed simulation or exceeded detail budget")
		var details: Array = plan["details"].duplicate(true)
		var clearings: Array = plan["clearings"].duplicate(true)
		Dressing._plans.clear()
		var rebuilt := Dressing.plan(&"tower", floor)
		if rebuilt["details"] != details or rebuilt["clearings"] != clearings:
			return _fail("Woodland dressing is not deterministic")
		if not floor.has("arena_center"):
			var route: Array = floor["route"]
			for segment in range(route.size() - 1):
				for sample in range(101):
					if not Floor.can_stand(floor, (route[segment] as Vector2).lerp(route[segment + 1], sample / 100.0), 24):
						return _fail("Woodland corridor became blocked")
	if variants.size() != 3 or variants.has(""):
		return _fail("Missing woodland variants")
	if Dressing.plan(&"tower", Floor.generate(17)).has("clearings"):
		return _fail("Woodland styling leaked into another biome")
	print("WOODLAND_DRESSING_OK: nine floors, three visual variants, deterministic clearings, bounded details and unchanged collision")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
