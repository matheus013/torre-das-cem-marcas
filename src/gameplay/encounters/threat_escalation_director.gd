class_name ThreatEscalationDirector
extends RefCounted

var normal_kills_per_boss := 25
var boss_kills_per_raid := 10
var normal_kills := 0
var boss_kills := 0
var raid_kills := 0
var pending_bosses := 0
var pending_raids := 0


func configure(values: Dictionary) -> void:
	normal_kills_per_boss = maxi(1, int(values.get("normal_kills_per_boss", normal_kills_per_boss)))
	boss_kills_per_raid = maxi(1, int(values.get("boss_kills_per_raid", boss_kills_per_raid)))


func register_defeat(encounter_class: StringName) -> Dictionary:
	var result := {"boss_queued": false, "raid_queued": false}
	match encounter_class:
		&"common", &"elite":
			normal_kills += 1
			while normal_kills >= normal_kills_per_boss:
				normal_kills -= normal_kills_per_boss
				pending_bosses += 1
				result["boss_queued"] = true
		&"boss":
			boss_kills += 1
			while boss_kills >= boss_kills_per_raid:
				boss_kills -= boss_kills_per_raid
				pending_raids += 1
				result["raid_queued"] = true
		&"raid":
			raid_kills += 1
	return result


func consume_next_spawn() -> StringName:
	if pending_raids > 0:
		pending_raids -= 1
		return &"raid"
	if pending_bosses > 0:
		pending_bosses -= 1
		return &"boss"
	return &""


func snapshot() -> Dictionary:
	return {
		"normal_kills_per_boss": normal_kills_per_boss,
		"boss_kills_per_raid": boss_kills_per_raid,
		"normal_kills": normal_kills,
		"boss_kills": boss_kills,
		"raid_kills": raid_kills,
		"pending_bosses": pending_bosses,
		"pending_raids": pending_raids,
	}


func restore(data: Dictionary) -> void:
	configure(data)
	normal_kills = maxi(0, int(data.get("normal_kills", 0)))
	boss_kills = maxi(0, int(data.get("boss_kills", 0)))
	raid_kills = maxi(0, int(data.get("raid_kills", 0)))
	pending_bosses = maxi(0, int(data.get("pending_bosses", 0)))
	pending_raids = maxi(0, int(data.get("pending_raids", 0)))
