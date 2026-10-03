class_name SkillGemDefinition
extends RefCounted

enum Kind {
	ACTIVE,
	SUPPORT,
}

var id: StringName
var kind: Kind
var tags: Array[StringName] = []
var required_active_tags: Array[StringName] = []
var evolution: EvolutionTrack
var support_drain := 1


func _init(gem_id: StringName, gem_kind: Kind) -> void:
	id = gem_id
	kind = gem_kind
	if kind == Kind.ACTIVE:
		evolution = EvolutionTrack.new(StringName("gem_%s" % id))


func add_level_choice(level: int, choice: EvolutionChoice) -> bool:
	if kind != Kind.ACTIVE:
		return false
	return evolution.add_choice(level, choice)


func choices_for_level(level: int) -> Array[EvolutionChoice]:
	if kind != Kind.ACTIVE or not evolution.choices_by_level.has(level):
		return []
	var result: Array[EvolutionChoice] = []
	result.assign(evolution.choices_by_level[level])
	return result


func supports(active_definition: SkillGemDefinition) -> bool:
	if kind != Kind.SUPPORT or active_definition.kind != Kind.ACTIVE:
		return false
	for required_tag in required_active_tags:
		if not active_definition.tags.has(required_tag):
			return false
	return true
