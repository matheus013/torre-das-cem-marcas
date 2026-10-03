class_name SpecialBossRoomState
extends RefCounted

var room_id: StringName = &""
var encounter_id: StringName = &""
var respawn_seconds := 1200.0
var cooldown_remaining := 0.0
var encounter_active := false


func setup(definition: Dictionary) -> bool:
	room_id = StringName(String(definition.get("id", "")))
	encounter_id = StringName(String(definition.get("encounter_id", "")))
	respawn_seconds = maxf(1.0, float(definition.get("respawn_seconds", 1200.0)))
	return not room_id.is_empty() and not encounter_id.is_empty() and bool(definition.get("exclusive_enemy", false))


func can_enter() -> bool:
	return not encounter_active and cooldown_remaining <= 0.0


func begin_encounter() -> bool:
	if not can_enter():
		return false
	encounter_active = true
	return true


func complete_encounter() -> void:
	if not encounter_active:
		return
	encounter_active = false
	cooldown_remaining = respawn_seconds


func cancel_encounter() -> void:
	encounter_active = false


func tick_world_time(delta: float) -> void:
	if not encounter_active:
		cooldown_remaining = maxf(0.0, cooldown_remaining - maxf(0.0, delta))


func snapshot() -> Dictionary:
	return {
		"room_id": String(room_id),
		"encounter_id": String(encounter_id),
		"respawn_seconds": respawn_seconds,
		"cooldown_remaining": cooldown_remaining,
		"encounter_active": encounter_active,
	}


func restore(data: Dictionary) -> void:
	room_id = StringName(String(data.get("room_id", room_id)))
	encounter_id = StringName(String(data.get("encounter_id", encounter_id)))
	respawn_seconds = maxf(1.0, float(data.get("respawn_seconds", respawn_seconds)))
	cooldown_remaining = maxf(0.0, float(data.get("cooldown_remaining", 0.0)))
	encounter_active = bool(data.get("encounter_active", false))
