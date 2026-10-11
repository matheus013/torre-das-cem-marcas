extends SceneTree

const Floor := preload("res://src/gameplay/world/floor_layout.gd")
const Dressing := preload("res://src/presentation/art/environment_dressing.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var variants := {}
	for number in range(17, 28):
		var floor := Floor.generate(number)
		var original := floor.duplicate(true)
		var plan := Dressing.plan(&"tower", floor)
		variants[plan.get("composition", "")] = true
		if (plan.get("mycelial_beds", []) as Array).is_empty():
			return _fail("Manto has no colonies, floor %d" % number)
		if floor != original or plan["details"].size() > 700:
			return _fail("Manto changed simulation or exceeded detail budget")
		var beds: Array = plan["mycelial_beds"].duplicate(true)
		var details: Array = plan["details"].duplicate(true)
		Dressing._plans.clear()
		var rebuilt := Dressing.plan(&"tower", floor)
		if rebuilt["mycelial_beds"] != beds or rebuilt["details"] != details:
			return _fail("Manto composition is not deterministic")
		if not floor.has("arena_center"):
			var route: Array = floor["route"]
			for segment in range(route.size() - 1):
				for sample in range(101):
					if not Floor.can_stand(floor, (route[segment] as Vector2).lerp(route[segment + 1], sample / 100.0), 24):
						return _fail("Manto corridor blocked")
	if variants.size() != 3 or variants.has(""):
		return _fail("Missing Manto variants")
	for number in [16, 28]:
		if Dressing.plan(&"tower", Floor.generate(number)).has("mycelial_beds"):
			return _fail("Manto styling leaked into adjacent biomes")
	print("MANTO_DRESSING_OK: eleven floors, three variants, deterministic colonies and unchanged simulation")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
