extends SceneTree

const DefinitionScript := preload("res://src/gameplay/encounters/major_encounter_definition.gd")
const StateScript := preload("res://src/gameplay/encounters/major_encounter_state.gd")


func _init() -> void:
	var definition: RefCounted = DefinitionScript.from_dictionary({
		"id": "raid_test",
		"name": "Raid Test",
		"enemy_definition_id": "raid_enemy",
		"encounter_type": "raid",
		"enrage_seconds": 120,
		"player_scaling": {"health_per_extra_player": 0.5, "damage_per_extra_player": 0.1},
		"break": {"maximum": 100, "stagger_duration": 4},
		"objectives": [{"id": "break_seals", "target": 2}],
		"phases": [
			{"id": "opening", "health_threshold": 1.0, "mechanics": ["sweep"]},
			{"id": "sealed", "health_threshold": 0.7, "mechanics": ["adds"], "gate_objective_id": "break_seals"},
			{"id": "core", "health_threshold": 0.3, "mechanics": ["collapse"]},
		],
	})
	if not bool(definition.call("is_valid_definition")):
		_fail("Valid raid definition was rejected")
		return
	var state: RefCounted = StateScript.new(&"raid_instance", definition, 1000.0, 3)
	if not is_equal_approx(float(state.get("maximum_health")), 2000.0):
		_fail("Raid health did not scale for party size")
		return
	var dealt := float(state.call("apply_damage", 800.0))
	if not is_equal_approx(dealt, 600.0) or int(state.get("phase_index")) != 1 or not bool(state.call("is_damage_locked")):
		_fail("Raid phase gate did not clamp damage at its threshold")
		return
	if float(state.call("apply_damage", 100.0)) != 0.0:
		_fail("Raid accepted damage while its objective gate was active")
		return
	state.call("progress_objective", &"break_seals")
	state.call("progress_objective", &"break_seals")
	if bool(state.call("is_damage_locked")) or not bool(state.call("apply_break_damage", 100.0)):
		_fail("Raid objective or break bar did not resolve")
		return
	state.call("tick", 120.0)
	if not bool(state.get("enraged")) or not is_equal_approx(float(state.call("damage_multiplier")), 1.8):
		_fail("Raid enrage did not update authoritative damage scaling")
		return
	var snapshot: Dictionary = state.call("to_snapshot")
	var restored: RefCounted = StateScript.new(&"raid_instance", definition, 1000.0, 3)
	if not bool(restored.call("restore", snapshot)) or int(restored.get("phase_index")) != 1:
		_fail("Raid snapshot could not restore its phase and objectives")
		return
	print("MAJOR_ENCOUNTER_OK: scaling, phases, objectives, break, enrage and snapshots validated")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
