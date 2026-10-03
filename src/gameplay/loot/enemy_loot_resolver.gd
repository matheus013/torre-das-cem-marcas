class_name EnemyLootResolver
extends RefCounted


## `chance_multiplier` e `quantity_multiplier` vêm da dificuldade da baixa (LootDifficulty).
func resolve(loot_table: Dictionary, seed: int, kill_sequence: int, chance_multiplier: float = 1.0, quantity_multiplier: float = 1.0) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	var random := RandomNumberGenerator.new()
	random.seed = seed + kill_sequence * 7919 + String(loot_table.get("id", "")).hash()
	var entries: Variant = loot_table.get("entries", [])
	if not entries is Array:
		return drops
	for raw_entry: Variant in entries:
		if not raw_entry is Dictionary:
			continue
		var entry := raw_entry as Dictionary
		var chance := clampf(float(entry.get("chance", 0.0)) * maxf(0.0, chance_multiplier), 0.0, 1.0)
		if random.randf() >= chance:
			continue
		var minimum := maxi(1, int(entry.get("minimum", 1)))
		var maximum := maxi(minimum, int(entry.get("maximum", minimum)))
		var scaled := float(random.randi_range(minimum, maximum)) * maxf(1.0, quantity_multiplier)
		var whole := int(floor(scaled))
		drops.append({
			"item_id": String(entry.get("item_id", "")),
			"quantity": whole + (1 if random.randf() < scaled - float(whole) else 0),
		})
	return drops
