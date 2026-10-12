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
	"seal": EquipmentItemDefinition.Slot.SEAL,
}
const TIER_BY_NAME: Dictionary = {
	"common": ItemTier.Value.COMMON,
	"uncommon": ItemTier.Value.UNCOMMON,
	"rare": ItemTier.Value.RARE,
	"epic": ItemTier.Value.EPIC,
	"legendary": ItemTier.Value.LEGENDARY,
	"divine": ItemTier.Value.DIVINE,
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
	definition.weapon_type = StringName(String(data.get("weapon_type", "unarmed")))
	definition.two_handed = bool(data.get("two_handed", false))
	for tag: Variant in data.get("tags", []) as Array:
		definition.tags.append(StringName(String(tag)))
	for tag: Variant in data.get("incompatibility_tags", []) as Array:
		definition.incompatibility_tags.append(StringName(String(tag)))
	if raw_stats is Dictionary:
		for raw_stat: Variant in raw_stats:
			definition.stat_modifiers[StringName(String(raw_stat))] = float(raw_stats[raw_stat])
	var raw_mechanics: Variant = data.get("mechanics", [])
	if raw_mechanics is Array:
		for mechanic: Variant in raw_mechanics:
			definition.mechanic_changes.append(StringName(String(mechanic)))
	# Passiva exclusiva (decisão 580) conta como a mudança mecânica do item.
	if data.get("passive", {}) is Dictionary and not (data.get("passive", {}) as Dictionary).is_empty():
		definition.mechanic_changes.append(StringName("passive:" + String(data.get("id", ""))))
	# Linhas divinas (decisão 608) também.
	if data.get("passives", []) is Array and not (data.get("passives", []) as Array).is_empty():
		definition.mechanic_changes.append(StringName("divine:" + String(data.get("id", ""))))
	return definition


func instance_from_data(data: Dictionary, instance_id: StringName, owner_id: StringName = &"") -> EquipmentItemInstance:
	var definition := definition_from_data(data)
	if definition == null:
		return null
	var instance := EquipmentItemInstance.new(instance_id, definition, owner_id)
	instance.tier = TIER_BY_NAME.get(String(data.get("tier", "common")), ItemTier.Value.COMMON) as ItemTier.Value
	return instance
