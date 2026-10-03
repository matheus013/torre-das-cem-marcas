class_name EquipmentTransaction
extends RefCounted


static func equip_from_inventory(
	inventory: ItemInventory,
	loadout: EquipmentLoadout,
	instance_id: StringName,
	index: int = 0
) -> bool:
	var item := inventory.get_item(instance_id)
	if item == null or item.owner_id != inventory.owner_id:
		return false
	if not loadout.equip(item, index):
		return false
	if inventory.remove(instance_id) == null:
		loadout.unequip(item.definition.slot, index)
		return false
	return true


static func unequip_to_inventory(
	inventory: ItemInventory,
	loadout: EquipmentLoadout,
	slot: EquipmentItemDefinition.Slot,
	index: int = 0
) -> bool:
	var item := loadout.unequip(slot, index)
	if item == null:
		return false
	if inventory.add(item):
		return true
	loadout.equip(item, index)
	return false
