extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Progress := preload("res://src/gameplay/world/narrative_progress.gd")
const Floor := preload("res://src/gameplay/world/floor_layout.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var sim := Simulation.new()
	sim.setup(7312)
	sim.add_player(1, &"eloa")
	sim.add_player(2, &"sena")
	if sim.narrative_action(1, "rescue_worker") or sim.narrative_action(999, "rescue_worker"):
		return _fail("Rescue accepted without contract/actor")
	sim.narrative.accept()
	sim.enter_tower(1)
	if sim.narrative_action(1, "rescue_worker"):
		return _fail("Remote rescue accepted")
	sim.player(1)["position"] = sim.narrative_worker_position()
	sim.player(1)["downed"] = true
	if sim.narrative_action(1, "rescue_worker"):
		return _fail("Downed actor started rescue")
	sim.player(1)["downed"] = false
	if not sim.narrative_action(1, "rescue_worker") or sim.narrative_action(1, "rescue_worker"):
		return _fail("Start is not idempotent")
	sim.enemies.clear()
	sim._step_narrative_rescue(0.1)
	if sim.narrative.rescue_progress <= 0:
		return _fail("Escort did not move")
	var before := sim.narrative.rescue_progress
	sim.player(1)["connected"] = false
	sim._step_narrative_rescue(0.1)
	if sim.narrative.rescue_progress != before:
		return _fail("Escort moved without a connected companion")
	sim.player(1)["connected"] = true
	sim.enemies.append({"health": 10, "position": sim.narrative_worker_position()})
	sim._step_narrative_rescue(0.1)
	if sim.narrative.rescue_progress != before:
		return _fail("Worker ignored nearby danger")
	sim.enemies.clear()
	var saved := sim.save_data(1)
	var restored := Simulation.new()
	restored.setup(7312)
	restored.add_player(1, &"eloa")
	if not restored.load_data(JSON.parse_string(JSON.stringify(saved)), 1) or not is_equal_approx(restored.narrative.rescue_progress, before):
		return _fail("Escort progress lost on JSON save/reload")
	var legacy := saved.duplicate(true)
	legacy["version"] = 12
	legacy["narrative"].erase("rescue_state")
	legacy["narrative"].erase("rescue_progress")
	if not restored.load_data(legacy, 1) or restored.narrative.rescue_state != "waiting" or restored.narrative.stage != "active":
		return _fail("Legacy migration inferred a rescue or lost contract")
	var invalid := saved.duplicate(true)
	invalid["narrative"].erase("rescue_state")
	if restored.load_data(invalid, 1):
		return _fail("Current save missing rescue accepted")
	for value: Variant in [NAN, INF, -1, 2, "0", true]:
		var raw := sim.narrative.snapshot()
		raw["rescue_progress"] = value
		if Progress.valid(raw):
			return _fail("Malformed progress accepted")
	# Either companion can continue; the village player cannot escort remotely.
	sim.enter_tower(2)
	sim.player(1)["connected"] = false
	for step in range(1500):
		var position := sim.narrative_worker_position()
		if not Floor._free(sim.floor_layout, position, 16):
			return _fail("Escort route intersects collision")
		sim.player(2)["position"] = position + Vector2(70, 0)
		sim._step_narrative_rescue(0.1)
		if sim.narrative.rescue_state == "rescued":
			break
	if sim.narrative.rescue_state != "rescued" or sim.narrative_view().has("field_worker"):
		return _fail("Worker did not reach portal or remains active")
	if sim.narrative_action(2, "rescue_worker") or sim.narrative.rescue_progress != 1:
		return _fail("Completed rescue repeated")
	sim.player(2)["position"] = sim._narrative_rescue_destination()
	sim.player(2)["transition_cooldown"] = 0
	sim._check_transition(2)
	if sim.player(2)["zone"] != &"village" or sim.narrative.rescue_state != "rescued":
		return _fail("Portal transition lost completed rescue")
	if not sim.narrative.view()["dialogue"].contains("trabalhador chegou") or sim.narrative.view()["journal"].is_empty():
		return _fail("Missing return reaction/journal")
	if not restored.load_data(JSON.parse_string(JSON.stringify(sim.save_data(2))), 1) or restored.narrative.rescue_state != "rescued":
		return _fail("Completed rescue lost")
	print("NARRATIVE_RESCUE_OK: authority, proximity, escort danger/companions, safe route, migration, persistence and return reaction")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
