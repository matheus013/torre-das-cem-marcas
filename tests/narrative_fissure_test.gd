extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Progress := preload("res://src/gameplay/world/narrative_progress.gd")
const Floor := preload("res://src/gameplay/world/floor_layout.gd")

func _init() -> void:
	_run.call_deferred()

func _marker(sim: WorldSimulation, action: String) -> Vector2:
	for marker: Dictionary in sim.narrative_route_markers():
		if marker["action"] == action:
			return marker["position"]
	return Vector2.ZERO

func _run() -> void:
	var sim := Simulation.new()
	sim.setup(7331)
	sim.add_player(1, &"eloa")
	if sim.narrative_action(1, "enter_fissure") or sim.narrative_action(999, "enter_fissure"):
		return _fail("Missing actor/contract accepted")
	sim.narrative.accept()
	sim.enter_tower(1)
	if sim.narrative_action(1, "choose_safe_route") or sim.narrative_action(1, "enter_fissure"):
		return _fail("Remote route choice accepted")
	sim.player(1)["position"] = _marker(sim, "choose_safe_route")
	var count := sim.enemies.size()
	if not sim.narrative_action(1, "choose_safe_route") or sim.narrative_action(1, "choose_safe_route") or sim.enemies.size() != count:
		return _fail("Safe route spawned guards or repeated choice")
	# Safe is a preference, not a lock on the optional passage for other party members.
	sim.player(1)["position"] = _marker(sim, "enter_fissure")
	sim.player(1)["downed"] = true
	if sim.narrative_action(1, "enter_fissure"):
		return _fail("Downed actor entered fissure")
	sim.player(1)["downed"] = false
	if not sim.narrative_action(1, "enter_fissure") or sim.enemies.size() != count + 2 or sim.narrative_action(1, "enter_fissure"):
		return _fail("Fissure guards missing or duplicated")
	var end := _marker(sim, "inspect_fissure")
	sim.player(1)["position"] = end
	if sim.narrative_action(1, "inspect_fissure"):
		return _fail("Inspected while guarded")
	var branch: Array = sim.floor_layout["side_route"]
	for index in range(101):
		var point: Vector2 = (branch[0] as Vector2).lerp(branch[1], index / 100.0)
		if not Floor.can_stand(sim.floor_layout, point, 24):
			return _fail("Fissure corridor blocked")
	var exploring := sim.save_data(1)
	var restored := Simulation.new()
	restored.setup(7331)
	restored.add_player(1, &"eloa")
	if not restored.load_data(JSON.parse_string(JSON.stringify(exploring)), 1) or restored.narrative.route_choice != "fissure":
		return _fail("Exploring state lost")
	if restored.narrative_action(1, "enter_fissure") or restored.enemies.size() != count + 2:
		return _fail("Reload duplicated guards")
	sim.enemies.clear()
	if not sim.narrative_action(1, "inspect_fissure") or sim.narrative_action(1, "inspect_fissure") or not sim.narrative.fissure_found:
		return _fail("Evidence is not idempotent")
	if sim.narrative.stage != "active" or not sim.narrative.view()["dialogue"].contains("sulco da fissura"):
		return _fail("Optional evidence replaced contract or lacks reaction")
	sim.player(1)["position"] = sim.narrative_marker()
	if not sim.narrative_action(1, "inspect"):
		return _fail("Optional route blocked original observation")
	sim.leave_tower(1)
	if sim.narrative.stage != "report_ready" or not sim.narrative.fissure_found:
		return _fail("Retreat lost discovery or original report")
	var completed := sim.save_data(1)
	if not restored.load_data(JSON.parse_string(JSON.stringify(completed)), 1) or not restored.narrative.fissure_found:
		return _fail("Discovery lost after return/reload")
	var legacy := completed.duplicate(true)
	legacy["version"] = 13
	legacy["narrative"].erase("route_choice")
	legacy["narrative"].erase("fissure_found")
	if not restored.load_data(legacy, 1) or restored.narrative.fissure_found or restored.narrative.route_choice != "":
		return _fail("Legacy migration inferred route discovery")
	var blocked_legacy := exploring.duplicate(true)
	blocked_legacy["version"] = 13
	blocked_legacy["narrative"].erase("route_choice")
	blocked_legacy["narrative"].erase("fissure_found")
	var blocked := Vector2.ZERO
	for prop: Dictionary in sim.floor_layout["props"]:
		if prop["sprite"] == "props/galeria_muro_lateral":
			blocked = prop["base"] + Vector2(0, -60)
			break
	if blocked == Vector2.ZERO or Floor.can_stand(sim.floor_layout, blocked, 16):
		return _fail("Missing migration collision fixture")
	blocked_legacy["player_position"] = [blocked.x, blocked.y]
	blocked_legacy["enemies"][0]["position"] = [blocked.x, blocked.y]
	if not restored.load_data(blocked_legacy, 1) or not restored.can_stand(&"tower", restored.player(1)["position"]) or restored.narrative.stage != "active":
		return _fail("Old save trapped player inside new architecture")
	if not restored.can_stand(&"tower", restored.enemies[0]["position"]) or restored.enemies.size() != count + 2:
		return _fail("Migration trapped or removed old enemies")
	var invalid := completed.duplicate(true)
	invalid["narrative"].erase("route_choice")
	if restored.load_data(invalid, 1):
		return _fail("Current save accepted missing route")
	for choice: Variant in [null, true, "unknown", 1]:
		var raw := sim.narrative.snapshot()
		raw["route_choice"] = choice
		if Progress.valid(raw):
			return _fail("Invalid route choice accepted")
	var contradictory := sim.narrative.snapshot()
	contradictory["route_choice"] = "safe"
	if Progress.valid(contradictory):
		return _fail("Safe route with fissure evidence accepted")
	print("NARRATIVE_FISSURE_OK: safe route, optional guards, clear corridor, authority, evidence once, migration, persistence and original contract")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
