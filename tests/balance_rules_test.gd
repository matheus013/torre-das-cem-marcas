extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Descriptions := preload("res://src/gameplay/content/content_descriptions.gd")
const TIERS: Array[String] = ["common", "uncommon", "rare", "epic", "legendary"]
## Valor de cada atributo em "pontos de atributo primário" (referência da revisão de balanceamento).
const VALUE := {"health": 0.25, "breath": 0.5, "strength": 1.0, "intelligence": 1.0, "agility": 1.0, "vitality": 1.0,
	"wisdom": 1.0, "fortune": 1.0, "movement_speed": 1.5, "attack_speed": 1.5, "critical_chance": 2.0, "cooldown_recovery": 2.0,
	"area": 1.0, "defense": 0.6}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var beta := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var lowest := {}
	var highest := {}
	for item: Dictionary in beta["items"]:
		var slot := String(item.get("slot", "none"))
		# Selos da Cicatriz valem pelo multiplicador (decisão 610), não por atributos.
		if slot in ["none", "weapon", "seal"]:
			continue
		var stats := item.get("stats", {}) as Dictionary
		var value := 0.0
		for stat: String in stats:
			if stat not in Descriptions.FUNCTIONAL_STATS:
				return _fail("%s has a stat with no effect: %s" % [item["id"], stat])
			value += float(VALUE[stat]) * float(stats[stat])
		var tier := String(item["tier"])
		lowest[tier] = minf(float(lowest.get(tier, INF)), value)
		highest[tier] = maxf(float(highest.get(tier, 0.0)), value)
	for index in range(1, TIERS.size()):
		var below := TIERS[index - 1]
		var tier := TIERS[index]
		if lowest.has(tier) and highest.has(below) and float(lowest[tier]) <= float(highest[below]):
			return _fail("Every %s item must be worth more than any %s item" % [tier, below])

	var weapons := (JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/weapon_profiles.json")) as Dictionary)["types"] as Dictionary
	var ordered := ["focus", "spear", "staff", "gauntlets"]
	for index in range(1, ordered.size()):
		var longer := weapons[ordered[index - 1]] as Dictionary
		var shorter := weapons[ordered[index]] as Dictionary
		if float(shorter["range"]) >= float(longer["range"]) or float(shorter.get("guard", 0.0)) < float(longer.get("guard", 0.0)):
			return _fail("Shorter-range weapons must have at least as much guard: " + String(ordered[index]))

	var sim := Simulation.new()
	sim.setup(31)
	sim.add_player(1, &"cira")
	var before := float(sim.derived_stats(1)["damage_reduction"])
	sim.equip_item(1, sim._add_equipment_instance(&"cira", "escudo_de_escora", "regular"))
	var after := float(sim.derived_stats(1)["damage_reduction"])
	var defense := 12.0 + 5.0 if before > 0.0 else 12.0
	if not is_equal_approx(after, defense / (defense + 100.0)):
		return _fail("Defense must reduce damage as defense / (defense + 100), got %.3f" % after)
	print("BALANCE_RULES_OK: item value rises with rarity, no dead stats, melee guard and defense")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
