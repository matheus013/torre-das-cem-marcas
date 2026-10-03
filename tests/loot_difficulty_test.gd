extends SceneTree

## Saque cresce com a dificuldade (decisão 552): mais quantidade, tiers mais altos, fabricação melhor
## e relíquias restritas a chefes e raids.

const LootDifficultyScript := preload("res://src/gameplay/loot/loot_difficulty.gd")
const ResolverScript := preload("res://src/gameplay/loot/enemy_loot_resolver.gd")
const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var nascent := {"encounter_class": "common", "rank_id": "nascente"}
	var elite := {"encounter_class": "elite", "rank_id": "alfa", "prefix_id": "robusto"}
	var boss := {"encounter_class": "boss", "rank_id": "apice", "prefix_id": "a", "suffix_id": "b"}
	var easy := LootDifficultyScript.score(nascent)
	var hard := LootDifficultyScript.score(elite)
	var extreme := LootDifficultyScript.score(boss, 2.8)
	if not (easy < hard and hard < extreme) or not is_equal_approx(extreme, 4.0 + 2.0 + 1.5 + 1.8):
		return _fail("Difficulty must grow with class, rank, affixes and party (got %s, %s, %s)" % [easy, hard, extreme])

	var table := {"id": "teste", "entries": [{"item_id": "pedra_regenerativa", "chance": 1.0, "minimum": 1, "maximum": 2}, {"item_id": "musgo_de_orientacao", "chance": 0.2, "minimum": 1, "maximum": 1}]}
	var resolver: RefCounted = ResolverScript.new()
	var totals := {}
	for difficulty: float in [easy, extreme]:
		var amount := 0
		for sequence in range(400):
			for drop: Dictionary in resolver.call("resolve", table, 5, sequence, LootDifficultyScript.chance_multiplier(difficulty), LootDifficultyScript.quantity_multiplier(difficulty)):
				amount += int(drop["quantity"])
		totals[difficulty] = amount
	if int(totals[extreme]) <= int(totals[easy]) * 1.6:
		return _fail("Harder kills must drop clearly more (easy %d, extreme %d)" % [totals[easy], totals[extreme]])

	var items: Array[Dictionary] = []
	for raw: Variant in (JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary)["items"]:
		items.append(raw as Dictionary)
	var random := RandomNumberGenerator.new()
	random.seed = 9
	var average_tier := {}
	var relic_without_boss := false
	for difficulty: float in [hard, extreme]:
		var tier_sum := 0
		for _roll in range(600):
			var item_id := LootDifficultyScript.pick_bonus_item(items, difficulty, difficulty == extreme, random)
			for item in items:
				if String(item["id"]) == item_id:
					tier_sum += LootDifficultyScript.TIERS.find(String(item["tier"]))
					if difficulty != extreme and String(item["slot"]) == "relic":
						relic_without_boss = true
		average_tier[difficulty] = float(tier_sum) / 600.0
	if float(average_tier[extreme]) <= float(average_tier[hard]) + 0.3 or relic_without_boss:
		return _fail("Quality must rise with difficulty and relics need bosses (%s)" % average_tier)
	var masterwork := {}
	for difficulty: float in [easy, extreme]:
		var count := 0
		for _roll in range(600):
			if LootDifficultyScript.pick_weighted(LootDifficultyScript.fabrication_weights(difficulty), random) in ["refined", "masterwork"]:
				count += 1
		masterwork[difficulty] = count
	if int(masterwork[extreme]) <= int(masterwork[easy]) * 2:
		return _fail("Fabrication must improve with difficulty (%s)" % masterwork)

	# Fabricação altera os bônus do equipamento equipado.
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", 3)
	sim.call("add_player", 1, &"eloa")
	var regular_health := float(sim.call("max_health", 1))
	var gear := sim.call("_gear", 1) as Dictionary
	for item: EquipmentItemInstance in (gear["equipment"] as EquipmentLoadout).call("_all_items"):
		if item.definition.stat_modifiers.has(&"health"):
			item.quality = &"masterwork"
	if float(sim.call("max_health", 1)) <= regular_health:
		return _fail("Masterwork fabrication must strengthen equipment bonuses")
	print("LOOT_DIFFICULTY_OK: quantity, tier, fabrication and relic gating scale with difficulty")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
