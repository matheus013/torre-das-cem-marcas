class_name EvolutionChoice
extends RefCounted

enum Kind {
	BUFF,
	MECHANIC,
}

var id: StringName
var kind: Kind
var display_name := ""
var description := ""
var branch := &""
var stat_modifiers: Dictionary = {}
var mechanic_id: StringName = &""


func _init(choice_id: StringName, choice_kind: Kind) -> void:
	id = choice_id
	kind = choice_kind
