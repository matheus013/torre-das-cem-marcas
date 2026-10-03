class_name ItemInventory
extends RefCounted

var owner_id: StringName
var items: Dictionary = {}


func _init(inventory_owner_id: StringName) -> void:
	owner_id = inventory_owner_id


func add(item: EquipmentItemInstance) -> bool:
	if items.has(item.instance_id):
		return false
	if not item.owner_id.is_empty() and item.owner_id != owner_id:
		return false
	item.owner_id = owner_id
	items[item.instance_id] = item
	return true


func remove(instance_id: StringName) -> EquipmentItemInstance:
	if not items.has(instance_id):
		return null
	var item := items[instance_id] as EquipmentItemInstance
	items.erase(instance_id)
	return item


func get_item(instance_id: StringName) -> EquipmentItemInstance:
	return items.get(instance_id) as EquipmentItemInstance


func has(instance_id: StringName) -> bool:
	return items.has(instance_id)
