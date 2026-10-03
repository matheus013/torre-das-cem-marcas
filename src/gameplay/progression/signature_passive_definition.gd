class_name SignaturePassiveDefinition
extends RefCounted

var id: StringName
var owner_character_id: StringName
var mechanic_id: StringName
var display_name := ""
var description := ""
var resource_id := &""
var maximum_resource := 0
var trigger_events: Array[StringName] = []
var spend_modes: Array[StringName] = []


func _init(
	passive_id: StringName,
	passive_owner_character_id: StringName,
	passive_mechanic_id: StringName
) -> void:
	id = passive_id
	owner_character_id = passive_owner_character_id
	mechanic_id = passive_mechanic_id
