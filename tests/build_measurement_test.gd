extends SceneTree

const Lab := preload("res://tools/bench/build_lab.gd")

class RankedLab extends "res://tools/bench/build_lab.gd":
	func _score(build: Dictionary) -> float:
		return float((build["paragon_shares"] as Dictionary)["elemental"])


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var lab := RankedLab.new()
	var build := lab._base_build("bola_de_fogo")
	lab._optimize_paragon(build)
	if build["paragon_shares"] != Lab.PARAGON_PRESETS[1]:
		return _fail("Paragon must retain the best preset, not the last")
	for tier in ["common", "uncommon", "rare", "epic", "legendary"]:
		var affixes := lab._good_affixes(build, tier, 100)
		if affixes.size() != int(ItemAffixes.count_range(tier)[1]):
			return _fail("Affix count exceeds rarity budget: " + tier)
	var sim := lab._world(build)
	sim.enter_tower(1)
	sim.start_floor(16)
	var enemy := sim.enemies[0]
	enemy["health"] = 1000.0
	enemy["max_health"] = 1000.0
	enemy["shield_hits"] = 0
	enemy["resistances"] = {}
	enemy.erase("behavior_id")
	sim.damage_meter_enabled = true
	var before := float(enemy["health"])
	sim.damage_enemy(1, 0, 10.0, {"dot": true, "gem_id": "bola_de_fogo", "percent_damage": 4.0})
	var actual := before - float(enemy["health"])
	if not is_equal_approx(float(sim.damage_meter.get("gem:bola_de_fogo", -1.0)), actual):
		return _fail("Damage meter must equal actual health loss")
	if not is_equal_approx(float(sim.damage_meter_percent["gem:bola_de_fogo"]), actual * 0.4):
		return _fail("Percent damage must be attributed without counting twice")
	sim.damage_enemy(1, 0, 10.0, {"dot": true, "passive": true, "gem_id": "bola_de_fogo"})
	if not sim.damage_meter.has("item_passive"):
		return _fail("Item procs must not be counted as gem damage")
	var isolated := lab._base_build("bola_de_fogo")
	isolated["gear"] = {}
	isolated["mastery"] = 1
	var measured := lab.measurement(isolated, "boss", Lab.DUMMY_HEALTH, 2.0, true)
	if float(measured["sources"].get("gem:bola_de_fogo", 0.0)) <= 0.0 or measured["sources"].has("auto_attack") or measured["sources"].has("item_passive"):
		return _fail("Isolated probe must measure gem damage without autoattack or items")
	for subject in ["brasa_persistente", "mina_de_lastro", "chuva_ferral", "corte_vetorial", "agulha_lastro", "poca_de_veneno"]:
		var trial := lab._base_build(subject)
		trial["gear"] = {}
		trial["mastery"] = 1
		for kind in ["boss", "pack"]:
			var result := lab.measurement(trial, kind, Lab.DUMMY_HEALTH, 3.0, true)
			if float(result["sources"].get("gem:" + subject, 0.0)) <= 0.0:
				return _fail("Arena and pilot must allow hits: %s %s" % [subject, kind])
	print("BUILD_MEASUREMENT_OK: Paragon, rarity budgets, damage attribution and isolated arena")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
