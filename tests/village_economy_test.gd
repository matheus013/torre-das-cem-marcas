extends SceneTree

const Life := preload("res://src/simulation/npc/village_life.gd")
const Layout := preload("res://src/gameplay/world/world_layout.gd")

func _init() -> void:
	_run()

func _run() -> void:
	var life := Life.new()
	life.setup(9, Layout.village_spots())
	var fixed := {}
	for npc in life.npcs:
		if String(npc["routine"]) in ["resident", "stationary"]:
			fixed[npc["id"]] = npc["position"]
	for frame in range(7200):
		life.step(0.1, {})
		for npc in life.npcs:
			if fixed.has(npc["id"]) and npc["position"] != fixed[npc["id"]]:
				return _fail("Fixed resident moved: " + String(npc["id"]))
	for resource in life.economy.RESOURCES:
		if int(life.economy.stock[resource]) <= 0:
			for npc in life.npcs:
				if npc["resource"] == resource:
					print(npc["id"], " at ", npc["position"], " target ", npc["target"], " cargo ", npc["cargo"])
			return _fail("No deliveries for " + resource)
	var saved := life.snapshot()
	var copy := Life.new()
	copy.setup(9, Layout.village_spots())
	copy.restore(JSON.parse_string(JSON.stringify(saved)))
	if JSON.stringify(copy.snapshot()) != JSON.stringify(saved):
		return _fail("Economy/worker save roundtrip failed")
	var stock_before := life.economy.stock.duplicate()
	life.period_index = 3
	for frame in range(5000):
		life.step(0.1, {})
	for npc in life.npcs:
		if not String(npc["resource"]).is_empty() and (npc["position"] as Vector2).distance_to(npc["home"]) > 5:
			return _fail("Worker did not return home: " + String(npc["id"]))
	for resource in life.economy.RESOURCES:
		if int(life.economy.stock[resource]) < int(stock_before[resource]):
			return _fail("Night lost stock")
	for npc: Dictionary in copy.npcs:
		var resource := String(npc["resource"])
		if resource.is_empty():
			continue
		copy.economy.stock[resource] = copy.economy.CAPACITY
		npc["cargo"] = 6
		npc["job_phase"] = "entregar"
		copy.economy.worker_step(npc, 1.0, true)
		if npc["target"] != npc["home"] or int(npc["cargo"]) != 6 or int(copy.economy.stock[resource]) != copy.economy.CAPACITY:
			return _fail("Full warehouse must preserve cargo and allow returning home at night")
	print("VILLAGE_ECONOMY_OK: %d residents, fixed homes/services, collection, deliveries, night and persistence: " % life.npcs.size(), stock_before)
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
