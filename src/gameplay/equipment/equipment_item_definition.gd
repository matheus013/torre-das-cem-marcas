class_name EquipmentItemDefinition
extends RefCounted

enum Slot {
	WEAPON,
	OFFHAND,
	AMULET,
	ARMOR,
	GLOVES,
	BOOTS,
	PANTS,
	RING,
	RELIC,
	## Selo da Cicatriz (decisão 610): encaixe auxiliar de poder por dificuldade.
	SEAL,
}

var id: StringName
var slot: Slot
var two_handed := false
var weapon_type: StringName = &"unarmed"
var stat_modifiers: Dictionary = {}
var mechanic_changes: Array[StringName] = []
var incompatibility_tags: Array[StringName] = []
var tags: Array[StringName] = []


func _init(item_id: StringName, item_slot: Slot) -> void:
	id = item_id
	slot = item_slot


func is_valid_definition() -> bool:
	if slot == Slot.RELIC and mechanic_changes.is_empty():
		return false
	return true
