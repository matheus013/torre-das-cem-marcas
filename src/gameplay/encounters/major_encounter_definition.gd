class_name MajorEncounterDefinition
extends RefCounted

const ENCOUNTER_TYPES: Array[StringName] = [&"boss", &"raid"]

var id: StringName
var display_name := ""
var enemy_definition_id: StringName
var encounter_type := &"boss"
var enrage_seconds := 180.0
var health_per_extra_player := 0.6
var damage_per_extra_player := 0.15
var break_maximum := 100.0
var stagger_duration := 4.0
var phases: Array[Dictionary] = []
var objectives: Array[Dictionary] = []


static func from_dictionary(data: Dictionary) -> RefCounted:
	var definition: RefCounted = load("res://src/gameplay/encounters/major_encounter_definition.gd").new()
	definition.id = StringName(String(data.get("id", "")))
	definition.display_name = String(data.get("name", definition.id))
	definition.enemy_definition_id = StringName(String(data.get("enemy_definition_id", "")))
	definition.encounter_type = StringName(String(data.get("encounter_type", "boss")))
	definition.enrage_seconds = float(data.get("enrage_seconds", 180.0))
	var scaling := data.get("player_scaling", {}) as Dictionary
	definition.health_per_extra_player = float(scaling.get("health_per_extra_player", 0.6))
	definition.damage_per_extra_player = float(scaling.get("damage_per_extra_player", 0.15))
	var break_data := data.get("break", {}) as Dictionary
	definition.break_maximum = float(break_data.get("maximum", 100.0))
	definition.stagger_duration = float(break_data.get("stagger_duration", 4.0))
	definition.phases.assign(data.get("phases", []))
	definition.objectives.assign(data.get("objectives", []))
	return definition


func is_valid_definition() -> bool:
	if (
		id.is_empty()
		or enemy_definition_id.is_empty()
		or encounter_type not in ENCOUNTER_TYPES
		or enrage_seconds <= 0.0
		or health_per_extra_player < 0.0
		or damage_per_extra_player < 0.0
		or break_maximum <= 0.0
		or stagger_duration <= 0.0
		or phases.is_empty()
	):
		return false
	var previous_threshold := 1.01
	var phase_ids: Dictionary = {}
	for phase in phases:
		var phase_id := String(phase.get("id", ""))
		var threshold := float(phase.get("health_threshold", -1.0))
		if (
			phase_id.is_empty()
			or phase_ids.has(phase_id)
			or threshold <= 0.0
			or threshold > 1.0
			or threshold >= previous_threshold
			or (phase.get("mechanics", []) as Array).is_empty()
		):
			return false
		phase_ids[phase_id] = true
		previous_threshold = threshold
	var objective_ids: Dictionary = {}
	for objective in objectives:
		var objective_id := String(objective.get("id", ""))
		if objective_id.is_empty() or objective_ids.has(objective_id) or int(objective.get("target", 0)) <= 0:
			return false
		objective_ids[objective_id] = true
	for phase in phases:
		var gate_id := String(phase.get("gate_objective_id", ""))
		if not gate_id.is_empty() and not objective_ids.has(gate_id):
			return false
	return encounter_type != &"raid" or not objectives.is_empty()


func health_multiplier(party_size: int) -> float:
	return 1.0 + float(clampi(party_size, 1, 4) - 1) * health_per_extra_player


func damage_multiplier(party_size: int) -> float:
	return 1.0 + float(clampi(party_size, 1, 4) - 1) * damage_per_extra_player
