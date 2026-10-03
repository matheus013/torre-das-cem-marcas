class_name BetaItemFactory
extends RefCounted

const SLOT_BY_NAME: Dictionary = {
	"weapon": EquipmentItemDefinition.Slot.WEAPON,
	"offhand": EquipmentItemDefinition.Slot.OFFHAND,
	"amulet": EquipmentItemDefinition.Slot.AMULET,
	"armor": EquipmentItemDefinition.Slot.ARMOR,
	"gloves": EquipmentItemDefinition.Slot.GLOVES,
	"boots": EquipmentItemDefinition.Slot.BOOTS,
	"pants": EquipmentItemDefinition.Slot.PANTS,
	"ring": EquipmentItemDefinition.Slot.RING,
	"relic": EquipmentItemDefinition.Slot.RELIC,
}
const TIER_BY_NAME: Dictionary = {
	"common": ItemTier.Value.COMMON,
	"uncommon": ItemTier.Value.UNCOMMON,
	"rare": ItemTier.Value.RARE,
	"epic": ItemTier.Value.EPIC,
	"legendary": ItemTier.Value.LEGENDARY,
}


func definition_from_data(data: Dictionary) -> EquipmentItemDefinition:
	var slot_name := String(data.get("slot", "none"))
	if not SLOT_BY_NAME.has(slot_name):
		return null
	var definition := EquipmentItemDefinition.new(
		StringName(String(data.get("id", "invalid_item"))),
		SLOT_BY_NAME[slot_name] as EquipmentItemDefinition.Slot
	)
	var raw_stats: Variant = data.get("stats", {})
	if raw_stats is Dictionary:
		for raw_stat: Variant in raw_stats:
			definition.stat_modifiers[StringName(String(raw_stat))] = float(raw_stats[raw_stat])
	var raw_mechanics: Variant = data.get("mechanics", [])
	if raw_mechanics is Array:
		for mechanic: Variant in raw_mechanics:
			definition.mechanic_changes.append(StringName(String(mechanic)))
	return definition


func instance_from_data(data: Dictionary, instance_id: StringName, owner_id: StringName = &"") -> EquipmentItemInstance:
	var definition := definition_from_data(data)
	if definition == null:
		return null
	var instance := EquipmentItemInstance.new(instance_id, definition, owner_id)
	instance.tier = TIER_BY_NAME.get(String(data.get("tier", "common")), ItemTier.Value.COMMON) as ItemTier.Value
	return instance
