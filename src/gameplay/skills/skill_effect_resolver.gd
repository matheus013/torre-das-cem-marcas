class_name SkillEffectResolver
extends RefCounted

const SUPPORT_FIELDS: Array[String] = [
	"power", "radius", "range", "cooldown", "breath_cost", "duration", "speed",
	"projectile_count", "pierce", "ricochet", "homing", "return_projectile", "fork_count", "impact_area",
	"repeat_count", "repeat_delay", "life_steal", "knockback", "remote_nova", "inner_radius",
	"field_follows_player", "expire_damage", "allies_receive_barrier", "barrier", "summon_follows_player",
	"summon_count", "repeat_last_target", "overheal_barrier", "healing", "arrival_area", "arrival_damage",
	"critical_chance", "tick_interval", "distance", "invulnerability", "attack_interval", "chain_range",
	"stability", "breath_per_hit", "barrier_per_hit",
]


func resolve(active_gem: Dictionary, support_gems: Array[Dictionary], evolution_modifiers: Array[Dictionary] = []) -> Dictionary:
	var result := active_gem.duplicate(true) as Dictionary
	for support in support_gems:
		if supports(active_gem, support):
			_apply_modifiers(result, support.get("modifiers", {}) as Dictionary)
	for modifiers in evolution_modifiers:
		_apply_modifiers(result, modifiers)
	return result


func supports(active_gem: Dictionary, support_gem: Dictionary) -> bool:
	if support_gem.is_empty():
		return false
	var mechanics := support_gem.get("allowed_mechanics", []) as Array
	if not mechanics.is_empty() and String(active_gem.get("mechanic", "")) not in mechanics:
		return false
	var tags: Array = active_gem.get("tags", []) as Array
	var required: Array = support_gem.get("requires", []) as Array
	for tag: Variant in required:
		if tag not in tags:
			return false
	return true


func _apply_modifiers(effect: Dictionary, modifiers: Dictionary) -> void:
	for raw_key: Variant in modifiers:
		var key := String(raw_key)
		var value: Variant = modifiers[raw_key]
		if key.ends_with("_multiplier"):
			var target := key.trim_suffix("_multiplier")
			effect[target] = float(effect.get(target, 1.0)) * float(value)
		elif key.ends_with("_add"):
			var target := key.trim_suffix("_add")
			effect[target] = float(effect.get(target, 0.0)) + float(value)
		else:
			effect[key] = value
