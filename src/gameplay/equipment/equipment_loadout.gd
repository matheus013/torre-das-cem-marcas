class_name EquipmentLoadout
extends RefCounted

const LootDifficultyScript := preload("res://src/gameplay/loot/loot_difficulty.gd")
const ItemAffixesScript := preload("res://src/gameplay/items/item_affixes.gd")

## Dois anéis (decisão 596; antes 10). Anéis de saves antigos acima do segundo voltam à mochila.
const RING_SLOT_COUNT := 2
const RELIC_SLOT_COUNT := 4

var weapon: EquipmentItemInstance
var offhand: EquipmentItemInstance
var amulet: EquipmentItemInstance
var armor: EquipmentItemInstance
var gloves: EquipmentItemInstance
var boots: EquipmentItemInstance
var pants: EquipmentItemInstance
var rings: Array[EquipmentItemInstance] = []
var relics: Array[EquipmentItemInstance] = []


func _init() -> void:
	rings.resize(RING_SLOT_COUNT)
	relics.resize(RELIC_SLOT_COUNT)


func equip(item: EquipmentItemInstance, index: int = 0) -> bool:
	var definition := item.definition
	if not definition.is_valid_definition() or _contains_item(item):
		return false
	if definition.slot == EquipmentItemDefinition.Slot.RELIC and not ItemTier.is_at_least(
		item.tier, ItemTier.Value.EPIC
	):
		return false
	match definition.slot:
		EquipmentItemDefinition.Slot.WEAPON:
			if weapon != null or (definition.two_handed and offhand != null):
				return false
			weapon = item
		EquipmentItemDefinition.Slot.OFFHAND:
			if offhand != null or (weapon != null and weapon.definition.two_handed):
				return false
			offhand = item
		EquipmentItemDefinition.Slot.AMULET:
			if amulet != null: return false
			amulet = item
		EquipmentItemDefinition.Slot.ARMOR:
			if armor != null: return false
			armor = item
		EquipmentItemDefinition.Slot.GLOVES:
			if gloves != null: return false
			gloves = item
		EquipmentItemDefinition.Slot.BOOTS:
			if boots != null: return false
			boots = item
		EquipmentItemDefinition.Slot.PANTS:
			if pants != null: return false
			pants = item
		EquipmentItemDefinition.Slot.RING:
			if index < 0 or index >= RING_SLOT_COUNT or rings[index] != null:
				return false
			rings[index] = item
		EquipmentItemDefinition.Slot.RELIC:
			if index < 0 or index >= RELIC_SLOT_COUNT or relics[index] != null or _relic_conflicts(item):
				return false
			relics[index] = item
		_:
			return false
	return true


func unequip(slot: EquipmentItemDefinition.Slot, index: int = 0) -> EquipmentItemInstance:
	var previous: EquipmentItemInstance = null
	match slot:
		EquipmentItemDefinition.Slot.WEAPON:
			previous = weapon
			weapon = null
		EquipmentItemDefinition.Slot.OFFHAND:
			previous = offhand
			offhand = null
		EquipmentItemDefinition.Slot.AMULET:
			previous = amulet
			amulet = null
		EquipmentItemDefinition.Slot.ARMOR:
			previous = armor
			armor = null
		EquipmentItemDefinition.Slot.GLOVES:
			previous = gloves
			gloves = null
		EquipmentItemDefinition.Slot.BOOTS:
			previous = boots
			boots = null
		EquipmentItemDefinition.Slot.PANTS:
			previous = pants
			pants = null
		EquipmentItemDefinition.Slot.RING:
			if index >= 0 and index < RING_SLOT_COUNT:
				previous = rings[index]
				rings[index] = null
		EquipmentItemDefinition.Slot.RELIC:
			if index >= 0 and index < RELIC_SLOT_COUNT:
				previous = relics[index]
				relics[index] = null
	return previous


func get_equipped(slot: EquipmentItemDefinition.Slot, index: int = 0) -> EquipmentItemInstance:
	match slot:
		EquipmentItemDefinition.Slot.WEAPON: return weapon
		EquipmentItemDefinition.Slot.OFFHAND: return offhand
		EquipmentItemDefinition.Slot.AMULET: return amulet
		EquipmentItemDefinition.Slot.ARMOR: return armor
		EquipmentItemDefinition.Slot.GLOVES: return gloves
		EquipmentItemDefinition.Slot.BOOTS: return boots
		EquipmentItemDefinition.Slot.PANTS: return pants
		EquipmentItemDefinition.Slot.RING:
			return rings[index] if index >= 0 and index < RING_SLOT_COUNT else null
		EquipmentItemDefinition.Slot.RELIC:
			return relics[index] if index >= 0 and index < RELIC_SLOT_COUNT else null
		_: return null


func equipped_count() -> int:
	var count := 0
	for item in [weapon, offhand, amulet, armor, gloves, boots, pants]:
		if item != null:
			count += 1
	for ring in rings:
		if ring != null:
			count += 1
	for relic in relics:
		if relic != null:
			count += 1
	return count


func combined_stat_modifiers() -> Dictionary:
	var result: Dictionary = {}
	for item in _all_items():
		var factor: float = LootDifficultyScript.fabrication_factor(String(item.quality)) * ItemAffixesScript.level_factor(item.item_level)
		for stat: Variant in item.definition.stat_modifiers.keys():
			result[stat] = float(result.get(stat, 0.0)) + float(item.definition.stat_modifiers[stat]) * factor
		var affix_stats := ItemAffixesScript.stats(item.affixes)
		for stat: Variant in affix_stats:
			result[stat] = float(result.get(stat, 0.0)) + float(affix_stats[stat])
	return result


func active_mechanic_changes() -> Array[StringName]:
	var result: Array[StringName] = []
	for item in _all_items():
		for mechanic in item.definition.mechanic_changes:
			if not result.has(mechanic):
				result.append(mechanic)
	return result


func _contains_item(item: EquipmentItemInstance) -> bool:
	for equipped in _all_items():
		if equipped.instance_id == item.instance_id:
			return true
	return false


func _relic_conflicts(candidate: EquipmentItemInstance) -> bool:
	for equipped_relic in relics:
		if equipped_relic == null:
			continue
		for tag in candidate.definition.incompatibility_tags:
			if equipped_relic.definition.tags.has(tag):
				return true
		for tag in equipped_relic.definition.incompatibility_tags:
			if candidate.definition.tags.has(tag):
				return true
	return false


func _all_items() -> Array[EquipmentItemInstance]:
	var result: Array[EquipmentItemInstance] = []
	for item in [weapon, offhand, amulet, armor, gloves, boots, pants]:
		if item != null:
			result.append(item)
	for ring in rings:
		if ring != null:
			result.append(ring)
	for relic in relics:
		if relic != null:
			result.append(relic)
	return result
