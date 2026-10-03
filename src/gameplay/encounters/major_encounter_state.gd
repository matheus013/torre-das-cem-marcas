class_name MajorEncounterState
extends RefCounted

var instance_id: StringName
var definition: RefCounted
var party_size := 1
var maximum_health := 1.0
var health := 1.0
var break_value := 0.0
var stagger_remaining := 0.0
var enrage_remaining := 0.0
var enraged := false
var phase_index := 0
var objective_progress: Dictionary = {}
var completed := false


func _init(
	encounter_instance_id: StringName,
	encounter_definition: RefCounted,
	base_health: float,
	participant_count: int
) -> void:
	instance_id = encounter_instance_id
	definition = encounter_definition
	party_size = clampi(participant_count, 1, 4)
	maximum_health = maxf(1.0, base_health * float(definition.call("health_multiplier", party_size)))
	health = maximum_health
	enrage_remaining = float(definition.get("enrage_seconds"))
	for objective: Dictionary in definition.get("objectives"):
		objective_progress[StringName(String(objective.get("id", "")))] = 0


func current_phase() -> Dictionary:
	var phases: Array = definition.get("phases")
	return phases[phase_index] as Dictionary


func is_damage_locked() -> bool:
	var gate_id := StringName(String(current_phase().get("gate_objective_id", "")))
	return not gate_id.is_empty() and not is_objective_complete(gate_id)


func apply_damage(amount: float) -> float:
	if amount <= 0.0 or completed or is_damage_locked():
		return 0.0
	var previous_health := health
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		completed = true
		return previous_health
	_advance_phase_once()
	if is_damage_locked():
		var phase_floor := maximum_health * float(current_phase().get("health_threshold", 0.0))
		health = maxf(health, phase_floor)
	return previous_health - health


func apply_break_damage(amount: float) -> bool:
	if amount <= 0.0 or completed or stagger_remaining > 0.0:
		return false
	break_value += amount
	if break_value < float(definition.get("break_maximum")):
		return false
	break_value = 0.0
	stagger_remaining = float(definition.get("stagger_duration"))
	return true


func progress_objective(objective_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or not objective_progress.has(objective_id):
		return false
	var target := _objective_target(objective_id)
	objective_progress[objective_id] = mini(target, int(objective_progress[objective_id]) + amount)
	return true


func is_objective_complete(objective_id: StringName) -> bool:
	return objective_progress.has(objective_id) and int(objective_progress[objective_id]) >= _objective_target(objective_id)


func tick(delta: float) -> void:
	if completed or delta <= 0.0:
		return
	stagger_remaining = maxf(0.0, stagger_remaining - delta)
	if not enraged:
		enrage_remaining = maxf(0.0, enrage_remaining - delta)
		if enrage_remaining <= 0.0:
			enraged = true


func damage_multiplier() -> float:
	var multiplier := float(definition.call("damage_multiplier", party_size))
	return multiplier * (1.5 if enraged else 1.0)


func to_snapshot() -> Dictionary:
	return {
		"instance_id": String(instance_id),
		"definition_id": String(definition.get("id")),
		"party_size": party_size,
		"maximum_health": maximum_health,
		"health": health,
		"break_value": break_value,
		"stagger_remaining": stagger_remaining,
		"enrage_remaining": enrage_remaining,
		"enraged": enraged,
		"phase_index": phase_index,
		"objective_progress": objective_progress.duplicate(true),
		"completed": completed,
	}


func restore(snapshot: Dictionary) -> bool:
	if String(snapshot.get("definition_id", "")) != String(definition.get("id")):
		return false
	if String(snapshot.get("instance_id", "")) != String(instance_id):
		return false
	var phases: Array = definition.get("phases")
	var restored_phase := int(snapshot.get("phase_index", -1))
	if restored_phase < 0 or restored_phase >= phases.size():
		return false
	party_size = clampi(int(snapshot.get("party_size", party_size)), 1, 4)
	maximum_health = maxf(1.0, float(snapshot.get("maximum_health", maximum_health)))
	health = clampf(float(snapshot.get("health", health)), 0.0, maximum_health)
	break_value = clampf(float(snapshot.get("break_value", 0.0)), 0.0, float(definition.get("break_maximum")))
	stagger_remaining = maxf(0.0, float(snapshot.get("stagger_remaining", 0.0)))
	enrage_remaining = maxf(0.0, float(snapshot.get("enrage_remaining", 0.0)))
	enraged = bool(snapshot.get("enraged", false))
	phase_index = restored_phase
	completed = bool(snapshot.get("completed", false))
	var restored_objectives := snapshot.get("objective_progress", {}) as Dictionary
	for objective_id: Variant in objective_progress.keys():
		objective_progress[objective_id] = clampi(
			int(restored_objectives.get(objective_id, 0)), 0, _objective_target(StringName(objective_id))
		)
	return true


func _advance_phase_once() -> void:
	var phases: Array = definition.get("phases")
	if phase_index + 1 >= phases.size():
		return
	var next_phase := phases[phase_index + 1] as Dictionary
	if health / maximum_health <= float(next_phase.get("health_threshold", 0.0)):
		phase_index += 1


func _objective_target(objective_id: StringName) -> int:
	for objective: Dictionary in definition.get("objectives"):
		if StringName(String(objective.get("id", ""))) == objective_id:
			return int(objective.get("target", 1))
	return 1
