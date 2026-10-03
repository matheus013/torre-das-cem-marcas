class_name SkillEffectResolver
extends RefCounted


func resolve(active_gem: Dictionary, support_gems: Array[Dictionary], evolution_modifiers: Array[Dictionary] = []) -> Dictionary:
	var result := active_gem.duplicate(true) as Dictionary
	for support in support_gems:
		if supports(active_gem, support):
			_apply_modifiers(result, support.get("modifiers", {}) as Dictionary)
	for modifiers in evolution_modifiers:
		_apply_modifiers(result, modifiers)
	return result


func supports(active_gem: Dictionary, support_gem: Dictionary) -> bool:
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
