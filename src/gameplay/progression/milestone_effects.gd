class_name MilestoneEffects
extends RefCounted

## Soma os efeitos das escolhas de marco (níveis 10 a 100) de uma personagem em três grupos:
## `modifiers` da personagem (X_add soma, X_mult multiplica), ajustes da Passiva Autoral
## (repassados a PassiveRuntime.configure) e `mechanics` executadas pela simulação.
## A ordem é a dos níveis, então um valor substituído num marco alto prevalece.


static func resolve(definition: Dictionary, selected: Dictionary) -> Dictionary:
	var result := {"modifiers": {}, "passive": {}, "mechanics": [] as Array[Dictionary], "choices": [] as Array[String]}
	var milestones := definition.get("milestones", {}) as Dictionary
	var levels: Array[int] = []
	for raw_level: Variant in selected:
		levels.append(int(raw_level))
	levels.sort()
	for level in levels:
		var choice_id := String(selected.get(level, selected.get(str(level), "")))
		for raw_choice: Variant in milestones.get(str(level), []) as Array:
			var entry := raw_choice as Dictionary
			if String(entry.get("id", "")) != choice_id:
				continue
			(result["choices"] as Array[String]).append(choice_id)
			var effects := entry.get("effects", {}) as Dictionary
			_merge(result["modifiers"] as Dictionary, effects.get("modifiers", {}) as Dictionary)
			_merge(result["passive"] as Dictionary, effects.get("passive", {}) as Dictionary)
			for mechanic: Variant in effects.get("mechanics", []) as Array:
				if mechanic is Dictionary:
					(result["mechanics"] as Array[Dictionary]).append((mechanic as Dictionary).duplicate(true))
	return result


static func _merge(target: Dictionary, source: Dictionary) -> void:
	for raw_key: Variant in source:
		var key := String(raw_key)
		var value := float(source[raw_key])
		if key.ends_with("_add"):
			target[key] = float(target.get(key, 0.0)) + value
		elif key.ends_with("_mult"):
			target[key] = float(target.get(key, 1.0)) * value
		else:
			target[key] = value


## Valor de um modificador já agregado; multiplicadores ausentes valem 1 e somas ausentes valem 0.
static func modifier(effects: Dictionary, key: String) -> float:
	var modifiers := effects.get("modifiers", {}) as Dictionary
	return float(modifiers.get(key, 1.0 if key.ends_with("_mult") else 0.0))


static func mechanics(effects: Dictionary, mechanic_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for mechanic: Dictionary in effects.get("mechanics", []) as Array:
		if String(mechanic.get("id", "")) == mechanic_id:
			found.append(mechanic)
	return found
