class_name EquippedActiveGem
extends RefCounted

const MAX_SUPPORTS := 2

var definition: SkillGemDefinition
var progression: EvolutionTrack
var support_gems: Array[SkillGemDefinition] = []

var level: int:
	get:
		return progression.level


func _init(active_definition: SkillGemDefinition) -> void:
	assert(active_definition.kind == SkillGemDefinition.Kind.ACTIVE)
	definition = active_definition
	progression = EvolutionTrack.new(active_definition.evolution.track_id)
	progression.choices_by_level = active_definition.evolution.choices_by_level


func has_pending_choice() -> bool:
	return progression.has_pending_choice()


func choose_evolution(choice_id: StringName) -> bool:
	return progression.choose(choice_id) != null


func can_level_up() -> bool:
	return progression.can_level_up()


func level_up() -> bool:
	return progression.level_up()


func attach_support(support: SkillGemDefinition) -> bool:
	if support_gems.size() >= MAX_SUPPORTS:
		return false
	if not support.supports(definition):
		return false
	if support_gems.has(support):
		return false
	if used_support_capacity() + support.support_drain > support_capacity():
		return false
	support_gems.append(support)
	return true


func support_capacity() -> int:
	return 2 + level


func used_support_capacity() -> int:
	var used := 0
	for support in support_gems:
		used += support.support_drain
	return used


func detach_support(support_id: StringName) -> SkillGemDefinition:
	for index in support_gems.size():
		if support_gems[index].id == support_id:
			return support_gems.pop_at(index)
	return null
