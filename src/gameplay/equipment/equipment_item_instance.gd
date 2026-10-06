class_name EquipmentItemInstance
extends RefCounted

var instance_id: StringName
var definition: EquipmentItemDefinition
var owner_id: StringName
var tier: ItemTier.Value = ItemTier.Value.COMMON
var quality: StringName = &"common"
var integrity := 1.0
var provenance: Array[Dictionary] = []
## Afixos sorteados na criação da peça (decisão 583): [{"id", "value"}].
var affixes: Array[Dictionary] = []
## Nível do item: andar onde a peça foi obtida (1 na vila). Escala atributos-base e afixos.
var item_level := 1


func _init(
	item_instance_id: StringName,
	item_definition: EquipmentItemDefinition,
	item_owner_id: StringName = &""
) -> void:
	instance_id = item_instance_id
	definition = item_definition
	owner_id = item_owner_id


func record_transfer(from_id: StringName, to_id: StringName, reason: StringName) -> void:
	provenance.append({
		"from": from_id,
		"to": to_id,
		"reason": reason,
	})
	owner_id = to_id


func set_integrity(value: float) -> void:
	integrity = clampf(value, 0.0, 1.0)
