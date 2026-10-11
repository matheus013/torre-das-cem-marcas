extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Progress := preload("res://src/gameplay/world/narrative_progress.gd")
const Floor := preload("res://src/gameplay/world/floor_layout.gd")

func _init() -> void:
	_run.call_deferred()

func _tick(sim: WorldSimulation, count: int = 21) -> void:
	for index in range(count):
		sim._step_cicatrization(0.25)

func _run() -> void:
	var sim := Simulation.new()
	sim.setup(7331)
	sim.add_player(1, &"eloa")
	sim.add_player(2, &"sena", "cicatrization-reserved")
	if sim.narrative_action(999, "observe_cicatrization") or sim.narrative_action(1, "observe_cicatrization"):
		return _fail("Missing actor/contract accepted")
	sim.narrative.accept()
	sim.enter_tower(1)
	if sim.narrative_action(1, "observe_cicatrization"):
		return _fail("Wrong floor accepted")
	sim.start_floor(2)
	sim.enemies.clear()
	var center: Vector2 = sim.floor_layout["cicatrization_center"]
	var original_count: int = sim.floor_layout["obstacles"].size()
	var marker := sim.cicatrization_marker()
	sim.player(1)["position"] = sim.floor_layout["entry"]
	if sim.narrative_action(1, "observe_cicatrization"):
		return _fail("Remote interaction accepted")
	sim.player(1)["position"] = marker
	sim.player(1)["downed"] = true
	if sim.narrative_action(1, "observe_cicatrization"):
		return _fail("Downed actor triggered closure")
	sim.player(1)["downed"] = false
	if not sim.narrative_action(1, "observe_cicatrization") or sim.narrative_action(1, "observe_cicatrization"):
		return _fail("Warning not idempotent")
	sim._step_cicatrization(NAN)
	sim._step_cicatrization(-1)
	_tick(sim, 4)
	if sim.narrative.cicatrization_remaining != 4 or not Floor.can_stand(sim.floor_layout, center, 24):
		return _fail("Premature closure or invalid time advanced")
	var warning_save := sim.save_data(1)
	var restored := Simulation.new()
	restored.setup(7331)
	restored.add_player(1, &"eloa")
	if not restored.load_data(JSON.parse_string(JSON.stringify(warning_save)), 1) or restored.narrative.cicatrization_remaining != 4:
		return _fail("Warning timer lost on reload")
	var build := restored.character_build(1)
	while not build.has_pending_milestone():
		restored.add_experience(1, restored.experience_required(build.level))
	restored.step(0.25)
	if restored.narrative.cicatrization_remaining != 4:
		return _fail("Milestone pause advanced closure")
	sim.player(1)["connected"] = false
	_tick(sim)
	if sim.narrative.cicatrization_remaining != 4:
		return _fail("Warning advanced without connected tower party")
	sim.player(1)["connected"] = true
	sim.player(2)["zone"] = &"tower"
	sim.player(2)["position"] = center
	sim.player(2)["downed"] = true
	sim.disconnect_player(2)
	_tick(sim)
	if sim.narrative.cicatrization_state != "warning" or sim.narrative.cicatrization_remaining != 0:
		return _fail("Closure trapped disconnected/downed body")
	if not sim.reconnect_player("cicatrization-reserved", 3) or sim.player(3)["position"] != center:
		return _fail("Reservation did not restore body in open seam")
	sim.player(3)["position"] = center + Vector2(-240, 0)
	sim.enemies.append({"position": center, "health": 1.0})
	_tick(sim)
	if sim.narrative.cicatrization_state != "warning":
		return _fail("Closure trapped live enemy")
	sim.enemies.clear()
	sim.ground_items.append({"zone": &"tower", "position": center})
	sim.ground_items.append({"zone": &"village", "position": Vector2.ZERO})
	_tick(sim, 1)
	if sim.narrative.cicatrization_state != "closed" or Floor.can_stand(sim.floor_layout, center, 24):
		return _fail("Closure lacks actual collision")
	if not Floor.can_stand(sim.floor_layout, sim.ground_items[0]["position"], 12) or sim.ground_items[1]["position"] != Vector2.ZERO:
		return _fail("Loot inaccessible or another zone modified")
	sim.ground_items.clear()
	if Floor.generate(2)["obstacles"].size() != original_count or not Floor.can_stand(Floor.generate(2), center, 24):
		return _fail("Shared original map mutated")
	var route: Array = sim.floor_layout["route"]
	var branch: Array = sim.floor_layout["side_route"]
	var path: Array = [route[0], route[1], branch[0], branch[1], branch[2], branch[3], route[2], route[3]]
	for segment in range(path.size() - 1):
		for index in range(101):
			if not Floor.can_stand(sim.floor_layout, (path[segment] as Vector2).lerp(path[segment + 1], index / 100.0), 24):
				return _fail("Detour blocked stairs/return route")
	_tick(sim)
	if sim.floor_layout["obstacles"].size() != original_count + 3 or sim.narrative_action(1, "observe_cicatrization"):
		return _fail("Repeated closure duplicated geometry")
	var closed_save := sim.save_data(1)
	if not restored.load_data(JSON.parse_string(JSON.stringify(closed_save)), 1) or Floor.can_stand(restored.floor_layout, center, 24):
		return _fail("Closed map lost on reload")
	sim.leave_tower(1)
	if not sim.narrative.view()["dialogue"].contains("segundo andar"):
		return _fail("Missing Nara reaction")
	sim.start_floor(2)
	if Floor.can_stand(sim.floor_layout, center, 24):
		return _fail("Re-entry reopened recorded closure")
	var legacy := warning_save.duplicate(true)
	legacy["version"] = 14
	legacy["narrative"].erase("cicatrization_state")
	legacy["narrative"].erase("cicatrization_remaining")
	if not restored.load_data(legacy, 1) or restored.narrative.cicatrization_state != "unseen":
		return _fail("Migration invented discovery")
	var invalid := closed_save.duplicate(true)
	invalid["narrative"].erase("cicatrization_state")
	if restored.load_data(invalid, 1):
		return _fail("Current save accepted missing event")
	for bad: Variant in [null, true, "closed", -1, INF, NAN, 5.1]:
		var raw := sim.narrative.snapshot()
		raw["cicatrization_remaining"] = bad
		if Progress.valid(raw):
			return _fail("Invalid timer accepted")
	for bad: Variant in [null, true, "unknown", 1]:
		var raw := sim.narrative.snapshot()
		raw["cicatrization_state"] = bad
		if Progress.valid(raw):
			return _fail("Invalid phase accepted")
	print("NARRATIVE_CICATRIZATION_OK: warning, protected bodies/enemies, detour, actual collision, immutable cache, loot, saves and migration")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
