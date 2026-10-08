class_name StatResolver
extends RefCounted

const FIRST_SOFT_CAP := 100.0
const SECOND_SOFT_CAP := 200.0
const THIRD_SOFT_CAP := 300.0
## Inteligência amplia o raio da explosão de esporos: +0,4% por ponto efetivo, até +100%.
const SPORE_SPREAD_PER_INTELLIGENCE := 0.004
const SPORE_SPREAD_CAP := 1.0


static func effective_primary(raw_value: float) -> float:
	var remaining := maxf(0.0, raw_value)
	var effective := minf(remaining, FIRST_SOFT_CAP)
	remaining = maxf(0.0, remaining - FIRST_SOFT_CAP)
	effective += minf(remaining, SECOND_SOFT_CAP - FIRST_SOFT_CAP) * 0.75
	remaining = maxf(0.0, remaining - (SECOND_SOFT_CAP - FIRST_SOFT_CAP))
	effective += minf(remaining, THIRD_SOFT_CAP - SECOND_SOFT_CAP) * 0.5
	remaining = maxf(0.0, remaining - (THIRD_SOFT_CAP - SECOND_SOFT_CAP))
	effective += remaining * 0.25
	return effective


static func effective_primaries(raw_stats: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for stat in CharacterBuild.PRIMARY_STATS:
		result[stat] = effective_primary(float(raw_stats.get(stat, 0.0)))
	return result


static func resolve(raw_stats: Dictionary) -> Dictionary:
	var effective := effective_primaries(raw_stats)
	var vitality := float(effective[&"vitality"])
	var strength := float(effective[&"strength"])
	var intelligence := float(effective[&"intelligence"])
	var agility := float(effective[&"agility"])
	var fortune := float(effective[&"fortune"])
	var wisdom := float(effective[&"wisdom"])
	return {
		"effective_primaries": effective,
		"max_health": 100.0 + vitality * 4.0,
		"wound_resistance": minf(vitality * 0.0015, 0.40),
		"physical_power": strength,
		"break_multiplier": 1.0 + minf(strength * 0.002, 0.60),
		"carry_capacity": 12.0 + floorf(strength / 10.0),
		"magical_power": intelligence,
		"barrier_multiplier": 1.0 + minf(intelligence * 0.002, 0.60),
		"healing_multiplier": 1.0 + minf(intelligence * 0.0015, 0.45),
		"spore_spread_multiplier": 1.0 + minf(intelligence * SPORE_SPREAD_PER_INTELLIGENCE, SPORE_SPREAD_CAP),
		"movement_speed_multiplier": 1.0 + minf(agility * 0.001, 0.25),
		"dodge_recovery_multiplier": 1.0 + minf(agility * 0.0015, 0.35),
		"automatic_attack_rate_multiplier": 1.0 + minf(agility * 0.001, 0.25),
		"critical_chance": minf(0.05 + fortune * 0.0008, 0.35),
		"critical_damage_multiplier": minf(1.50 + fortune * 0.001, 2.0),
		"conditional_effect_multiplier": 1.0 + minf(fortune * 0.002, 0.60),
		"cooldown_recovery_multiplier": 1.0 + minf(wisdom * 0.0015, 0.50),
		"resource_efficiency_multiplier": 1.0 + minf(wisdom * 0.0015, 0.50),
		"control_resistance": minf(wisdom * 0.0015, 0.45),
	}
