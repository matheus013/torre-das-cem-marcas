class_name SkillGemLoadout
extends RefCounted

const ACTIVE_SLOT_COUNT := 4
const SLOT_COMMANDS: Array[StringName] = [&"Q", &"W", &"E", &"R"]

var active_slots: Array[EquippedActiveGem] = []


func _init() -> void:
	active_slots.resize(ACTIVE_SLOT_COUNT)


func equip_active(slot: int, gem: EquippedActiveGem) -> bool:
	if slot < 0 or slot >= ACTIVE_SLOT_COUNT:
		return false
	if active_slots.has(gem):
		return false
	active_slots[slot] = gem
	return true


func unequip_active(slot: int) -> EquippedActiveGem:
	if slot < 0 or slot >= ACTIVE_SLOT_COUNT:
		return null
	var previous := active_slots[slot]
	active_slots[slot] = null
	return previous


func gem_for_command(command: StringName) -> EquippedActiveGem:
	var slot := SLOT_COMMANDS.find(command)
	if slot < 0:
		return null
	return active_slots[slot]
