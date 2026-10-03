class_name SkillScalingProfile
extends RefCounted

const MAX_SCALING_STATS := 3

var weights: Dictionary = {}


func set_weight(stat: StringName, weight: float) -> bool:
	if not CharacterBuild.PRIMARY_STATS.has(stat) or weight <= 0.0:
		return false
	if not weights.has(stat) and weights.size() >= MAX_SCALING_STATS:
		return false
	weights[stat] = weight
	return true


func remove_weight(stat: StringName) -> void:
	weights.erase(stat)


func power_multiplier(raw_stats: Dictionary) -> float:
	var effective := StatResolver.effective_primaries(raw_stats)
	var contribution := 0.0
	for stat: Variant in weights.keys():
		contribution += float(effective.get(stat, 0.0)) * float(weights[stat])
	return 1.0 + contribution / 100.0
