extends SceneTree

const LootDifficultyScript := preload("res://src/gameplay/loot/loot_difficulty.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if not is_equal_approx(LootDifficultyScript.bonus_chance(0.0), 0.08):
		return _fail("Common enemies need a base chance of bonus equipment")
	if LootDifficultyScript.bonus_chance(100.0) > 0.75:
		return _fail("Bonus chance must stay capped at 75%")
	var beta := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var items: Array[Dictionary] = []
	var slots := {}
	for item: Dictionary in beta["items"]:
		items.append(item)
		slots[String(item["id"])] = String(item.get("slot", "none"))
	var random := RandomNumberGenerator.new()
	random.seed = 31
	for roll in range(2000):
		var difficulty := float(roll % 9)
		var bonus := LootDifficultyScript.pick_bonus_item(items, difficulty, false, random)
		if bonus.is_empty() or slots[bonus] in ["none", "relic"]:
			return _fail("Bonus must be non-relic equipment, got '%s' at D %.0f" % [bonus, difficulty])
	print("LOOT_BONUS_OK: 8% base chance, equipment-only bonus, relics reserved")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
