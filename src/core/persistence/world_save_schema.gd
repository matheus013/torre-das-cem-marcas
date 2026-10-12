extends RefCounted

const ITEM := {
	"definition_id": TYPE_STRING, "instance_id": TYPE_STRING, "location": TYPE_STRING,
	"tier": TYPE_FLOAT, "quality": TYPE_STRING, "integrity": TYPE_FLOAT, "index": TYPE_FLOAT,
	"affixes": [{"id": TYPE_STRING, "value": TYPE_FLOAT}], "item_level": TYPE_FLOAT, "upgrade": TYPE_FLOAT,
}
const SHAPE := {
	"version": TYPE_FLOAT, "zone": TYPE_STRING, "character_id": TYPE_STRING,
	"player_position": [TYPE_FLOAT], "target_position": [TYPE_FLOAT], "last_world_position": [TYPE_FLOAT],
	"player_health": TYPE_FLOAT, "player_breath": TYPE_FLOAT, "quick_items": TYPE_FLOAT,
	"carried_stone": TYPE_FLOAT, "carried_loot": {"*": TYPE_FLOAT}, "banked_loot": {"*": TYPE_FLOAT},
	"banked_stone": TYPE_FLOAT, "current_floor": TYPE_FLOAT, "deepest_floor": TYPE_FLOAT,
	"tower_start_floor": TYPE_FLOAT, "loot_kill_sequence": TYPE_FLOAT,
	"village_progress": TYPE_FLOAT, "encounter_seed": TYPE_FLOAT, "equipment_instance_sequence": TYPE_FLOAT,
	"boss_cooldowns": {"*": TYPE_FLOAT},
	"floor_run": {
		"floor": TYPE_FLOAT, "time": TYPE_FLOAT, "kills": TYPE_FLOAT, "party_peak": TYPE_FLOAT,
		"quota": TYPE_FLOAT, "quota_base": TYPE_FLOAT, "population": TYPE_FLOAT,
		"stairs_open": TYPE_BOOL, "recorded": TYPE_BOOL, "boss_fight": TYPE_BOOL,
	},
	"character_progress": {"*": {
		"experience": TYPE_FLOAT, "build": {
			"character_id": TYPE_STRING, "level": TYPE_FLOAT, "unspent_stat_points": TYPE_FLOAT,
			"base_stats": {"*": TYPE_FLOAT}, "selected_milestones": {"*": TYPE_STRING},
			"unlocked_mechanics": [TYPE_STRING],
		},
	}},
	"character_gear": {"*": {"items": [ITEM]}},
	"equipment": {"instance_sequence": TYPE_FLOAT, "items": [ITEM]},
	"character_gems": {"*": {
		"auto_supports": [TYPE_STRING], "boss_misses": {"*": TYPE_FLOAT},
		"slots": [TYPE_STRING], "supports": [[TYPE_STRING]],
		"gems": {"*": {"level": TYPE_FLOAT, "experience": TYPE_FLOAT, "choices": {"*": TYPE_STRING}}},
	}},
	"character_bestiary": {"*": {"*": {"kills": TYPE_FLOAT, "min_health": TYPE_FLOAT, "max_health": TYPE_FLOAT,
		"drops": {"*": TYPE_FLOAT}, "affixes": {"*": TYPE_FLOAT}}}},
	"shop_sequence": TYPE_FLOAT, "shop_sold": [TYPE_FLOAT],
	"difficulty": TYPE_FLOAT, "unlocked_difficulty": TYPE_FLOAT, "difficulty_progress": {"*": {"deepest": TYPE_FLOAT, "start": TYPE_FLOAT}},
	"village_life": {
		"period": TYPE_FLOAT, "minds": {"*": {"memories": [TYPE_DICTIONARY], "facts": TYPE_ARRAY}},
		"economy": {"stock": {"*": TYPE_FLOAT}, "deliveries": TYPE_FLOAT,
			"nodes": {"*": {"amount": TYPE_FLOAT, "regen": TYPE_FLOAT}}},
		"workers": {"*": {"position": [TYPE_FLOAT], "cargo": TYPE_FLOAT, "job_phase": TYPE_STRING, "work_timer": TYPE_FLOAT}},
	},
	"world_clock": {"time": TYPE_FLOAT, "day": TYPE_FLOAT},
	"respawn": {
		"death_sequence": TYPE_FLOAT, "spawn_sequence": TYPE_FLOAT,
		"queue": [{"definition_id": TYPE_STRING, "encounter_class": TYPE_STRING,
			"preferred_position": [TYPE_FLOAT], "remaining": TYPE_FLOAT, "death_sequence": TYPE_FLOAT}],
	},
	"threat": {"*": TYPE_FLOAT},
	"ground_items": [{"floor": TYPE_FLOAT, "position": [TYPE_FLOAT], "item_id": TYPE_STRING,
		"quantity": TYPE_FLOAT, "quality": TYPE_STRING, "zone": TYPE_STRING}],
	"enemies": [{"position": [TYPE_FLOAT], "home": [TYPE_FLOAT], "wander_target": [TYPE_FLOAT],
		"health": TYPE_FLOAT, "max_health": TYPE_FLOAT, "shield_hits": TYPE_FLOAT,
		"minimum_affixes": TYPE_FLOAT, "maximum_affixes": TYPE_FLOAT, "modifier_mechanics": [TYPE_STRING]}],
}


static func validate(data: Dictionary, maximum_version: int) -> Error:
	var version: Variant = data.get("version", 0)
	if not _matches(version, TYPE_FLOAT) or float(version) != floorf(float(version)) or float(version) < 1:
		return ERR_FILE_CORRUPT
	if float(version) > maximum_version:
		return ERR_UNAVAILABLE
	if not _matches(data, SHAPE):
		return ERR_FILE_CORRUPT
	if data.get("zone", "village") not in ["village", "house", "tower", "boss_room"]:
		return ERR_FILE_CORRUPT
	if float(data.get("current_floor", 0)) > 0:
		var run: Dictionary = data.get("floor_run", {})
		for key in ["time", "kills", "quota", "stairs_open"]:
			if not run.has(key):
				return ERR_FILE_CORRUPT
	# Fields absent in older saves retain the simulation's migration defaults.
	return OK


static func validate_records(data: Dictionary) -> Error:
	var shape := {"*": {"*": [{"time": TYPE_FLOAT, "characters": [TYPE_STRING], "date": TYPE_STRING}]}}
	if not _matches(data, shape):
		return ERR_FILE_CORRUPT
	for floor_key: Variant in data:
		for mode: Variant in data[floor_key]:
			for entry: Dictionary in data[floor_key][mode]:
				if not entry.has("time") or float(entry["time"]) < 0:
					return ERR_FILE_CORRUPT
	return OK


static func _matches(value: Variant, shape: Variant) -> bool:
	if shape is Dictionary:
		if not value is Dictionary:
			return false
		for key: Variant in value:
			var rule: Variant = shape.get(key, shape.get("*", null))
			if rule != null and not _matches(value[key], rule):
				return false
		return true
	if shape is Array:
		if not value is Array:
			return false
		for entry: Variant in value:
			if not _matches(entry, shape[0]):
				return false
		return true
	if shape == TYPE_FLOAT:
		return (value is int or value is float) and is_finite(float(value))
	if shape == TYPE_STRING:
		return value is String or value is StringName
	return typeof(value) == int(shape)
