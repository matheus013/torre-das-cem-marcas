class_name WeaponCombat
extends RefCounted

const PATH := "res://data/combat/weapon_profiles.json"
static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func resolve(type_id: String, character_id: String, stats: Dictionary, fabrication: float = 1.0) -> Dictionary:
	var types := data().get("types", {}) as Dictionary
	var result := (types.get(type_id, types.get("unarmed", {})) as Dictionary).duplicate(true)
	var affinities := data().get("affinities", {}) as Dictionary
	result["affinities"] = (affinities.get(character_id, {}) as Dictionary).duplicate()
	result["affinity"] = float((result["affinities"] as Dictionary).get(type_id, 100.0))
	var multiplier := 1.0
	for stat: String in result.get("scaling", {}) as Dictionary:
		multiplier += float(stats.get(StringName(stat), 0.0)) * float(result["scaling"][stat])
	result["damage"] = float(result.get("power", 0.0)) * multiplier * fabrication * float(result["affinity"]) / 100.0
	return result


static func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var types := data().get("types", {}) as Dictionary
	for id in ["unarmed", "focus", "spear", "gauntlets", "staff"]:
		var profile := types.get(id, {}) as Dictionary
		for key in ["range", "power", "interval"]:
			var value := float(profile.get(key, 0.0))
			if not is_finite(value) or value <= 0.0:
				errors.append("Invalid %s.%s" % [id, key])
		if profile.get("pattern", "") not in ["single", "line", "cone"] or profile.get("damage_type", "") not in ["physical", "arcane"]:
			errors.append("Invalid attack geometry or damage type: " + id)
		for stat: String in profile.get("scaling", {}) as Dictionary:
			if StringName(stat) not in CharacterBuild.PRIMARY_STATS or not is_finite(float(profile["scaling"][stat])) or float(profile["scaling"][stat]) < 0.0:
				errors.append("Invalid scaling: " + id)
	for character in ["eloa", "sena", "cira", "rui"]:
		var row := (data().get("affinities", {}) as Dictionary).get(character, {}) as Dictionary
		for id in ["focus", "spear", "gauntlets", "staff"]:
			var percent := float(row.get(id, 0.0))
			if not is_finite(percent) or percent <= 0.0 or percent > 200.0:
				errors.append("Invalid affinity: %s.%s" % [character, id])
	return errors
