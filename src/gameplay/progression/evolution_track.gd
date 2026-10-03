class_name EvolutionTrack
extends RefCounted

const MAX_LEVEL := 10

var track_id: StringName
var level := 1
var choices_by_level: Dictionary = {}
var selected_choices: Dictionary = {}


func _init(evolution_track_id: StringName) -> void:
	track_id = evolution_track_id


func add_choice(level_number: int, choice: EvolutionChoice) -> bool:
	if level_number < 1 or level_number > MAX_LEVEL:
		return false
	if level_number == MAX_LEVEL and choice.kind != EvolutionChoice.Kind.MECHANIC:
		return false
	if not choices_by_level.has(level_number):
		choices_by_level[level_number] = []
	var choices := choices_by_level[level_number] as Array
	for existing_value: Variant in choices:
		var existing := existing_value as EvolutionChoice
		if existing.id == choice.id:
			return false
	choices.append(choice)
	return true


func choices_for_current_level() -> Array[EvolutionChoice]:
	var result: Array[EvolutionChoice] = []
	if not choices_by_level.has(level):
		return result
	result.assign(choices_by_level[level])
	return result


func has_pending_choice() -> bool:
	return not selected_choices.has(level)


func choose(choice_id: StringName) -> EvolutionChoice:
	if not has_pending_choice():
		return null
	for choice in choices_for_current_level():
		if choice.id == choice_id:
			selected_choices[level] = choice.id
			return choice
	return null


func can_level_up() -> bool:
	return level < MAX_LEVEL and not has_pending_choice()


func level_up() -> bool:
	if not can_level_up():
		return false
	level += 1
	return true
