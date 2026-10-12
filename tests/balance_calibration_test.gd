extends SceneTree

## Balanceamento (decisão 610): fatores de potência por gema (data/combat/gem_balance.json, aplicados
## uma vez na carga); Selos da Cicatriz (encaixe próprio, caem só na dificuldade deles, multiplicam todo
## o dano e a Vida, lapidação até +5 na Forja) e marcos multiplicativos do Paragon. O multiplicador
## geral não age sobre a parte do golpe que é fração da Vida do alvo. A dificuldade não é reduzida.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Paragon := preload("res://src/gameplay/progression/paragon.gd")
const LootDifficulty := preload("res://src/gameplay/loot/loot_difficulty.gd")


func _init() -> void:
	_run.call_deferred()


func _world(level: int) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(6101)
	sim.add_player(1, &"eloa")
	sim.unlocked_difficulty = 5
	sim.set_difficulty(1, level)
	sim.clock.call("set_period", "tarde")
	return sim


func _dummy(sim: WorldSimulation) -> Dictionary:
	sim.enter_tower(1)
	sim.start_floor(16)
	sim.enemies.clear()
	var dummy := sim.create_enemy(sim.content("enemies")[0], (sim.player(1)["position"] as Vector2) + Vector2(80.0, 0.0), 1)
	for key in ["max_health", "health"]:
		dummy[key] = 1.0e9
	dummy["resistances"] = {}
	dummy["shield_hits"] = 0
	dummy.erase("behavior_id")
	sim.enemies.append(dummy)
	return dummy


func _hit(sim: WorldSimulation, hit: Dictionary) -> float:
	var dummy := _dummy(sim)
	sim.damage_enemy(1, 0, 100.0, hit)
	return 1.0e9 - float(dummy["health"])


func _equip_seal(sim: WorldSimulation, seal_id: String, upgrade: int = 0) -> EquipmentItemInstance:
	var instance_id := sim._add_equipment_instance(&"eloa", seal_id, "masterwork", 50)
	var seal := (sim._gear(1)["inventory"] as ItemInventory).items[instance_id] as EquipmentItemInstance
	seal.upgrade = upgrade
	sim.equip_item(1, instance_id)
	sim._passive_cache.clear()
	return seal


func _run() -> void:
	# Fatores por gema: o número de dano do catálogo é multiplicado uma vez na carga.
	var balance := (JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/gem_balance.json")) as Dictionary)["power"] as Dictionary
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var sim := _world(1)
	for gem: Dictionary in catalog["active_gems"]:
		var expected := float(gem.get("power", 0.0)) * float(balance.get(String(gem["id"]), 1.0))
		if not is_equal_approx(float(sim.gem_definition(String(gem["id"])).get("power", 0.0)), expected):
			return _fail("Gem balance factor must apply once on load: %s" % gem["id"])

	# A dificuldade não dá poder por si: o mesmo golpe causa o mesmo dano na 1 e na 5.
	if not is_equal_approx(_hit(_world(1), {"crit_add": -1.0}), _hit(_world(5), {"crit_add": -1.0})):
		return _fail("Difficulty itself must not change player damage")

	# Selo Mestre: multiplica todo o dano e a Vida pelos valores do catálogo; lapidação +10% de dano por nível.
	var master := (sim.item_data("selo_mestre")["seal"]) as Dictionary
	var plain := _hit(_world(3), {"crit_add": -1.0})
	var sealed_world := _world(3)
	var health := sealed_world.max_health(1)
	_equip_seal(sealed_world, "selo_mestre")
	if not is_equal_approx(sealed_world.max_health(1) / health, float(master["health"])):
		return _fail("The Master Seal must multiply max health")
	if not is_equal_approx(_hit(sealed_world, {"crit_add": -1.0}) / plain, float(master["damage"])):
		return _fail("The Master Seal must multiply all damage")
	var upgraded := _world(3)
	_equip_seal(upgraded, "selo_mestre", 2)
	if not is_equal_approx(_hit(upgraded, {"crit_add": -1.0}) / plain, float(master["damage"]) * 1.2):
		return _fail("Each seal upgrade must add 10% damage")
	# Fração da Vida (veneno com `percent_damage`): só a parte fixa ganha o multiplicador.
	var mixed_plain := _hit(_world(3), {"dot": true, "percent_damage": 80.0, "poison": "esporo"})
	var mixed_world := _world(3)
	_equip_seal(mixed_world, "selo_mestre")
	if not is_equal_approx(_hit(mixed_world, {"dot": true, "percent_damage": 80.0, "poison": "esporo"}), mixed_plain * (0.2 * float(master["damage"]) + 0.8)):
		return _fail("Percent-of-health damage must stay out of the general multiplier")

	# Selos caem só na dificuldade deles; o primeiro chefe garante; não entram no saque bônus.
	for level in [1, 3]:
		var drops := _world(level)
		drops.enter_tower(1)
		drops.start_floor(16)
		var boss: Dictionary = drops.enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("floor_boss", false)))[0]
		drops._register_floor_kill(boss)
		var owned := drops._owns_item(1, "selo_mestre")
		if owned != (level == 3) or drops._owns_item(1, "selo_veterano"):
			return _fail("Seals must drop only on their difficulty, guaranteed on the first boss (difficulty %d)" % level)
	var random := RandomNumberGenerator.new()
	random.seed = 7
	for roll in range(400):
		if LootDifficulty.pick_bonus_item(sim.content("items"), 12.0, true, random).begins_with("selo_"):
			return _fail("Seals must not come from random bonus loot")

	# Lapidação na Forja: Pólen Lunar do armazém e prata; sobrevive ao save.
	var forge := _world(3)
	_equip_seal(forge, "selo_mestre")
	var npc := forge.village_life.call("find", "dalia_ferral") as Dictionary
	forge.player(1)["position"] = (npc["position"] as Vector2) + Vector2(20.0, 0.0)
	if forge.upgrade_seal(1):
		return _fail("Upgrading needs Lunar Pollen")
	forge.banked_loot["polen_lunar"] = 10
	forge._gear(1)["silver"] = 5000
	if not forge.upgrade_seal(1) or forge.equipped_seal(1).upgrade != 1 or int(forge.banked_loot["polen_lunar"]) != 8:
		return _fail("Upgrading the seal must spend pollen and silver")
	var restored := Simulation.new()
	restored.setup(6101)
	restored.add_player(1, &"eloa")
	if not restored.load_data(forge.save_data(1), 1) or restored.equipped_seal(1) == null or restored.equipped_seal(1).upgrade != 1:
		return _fail("Seal upgrades must survive save and load")

	# Paragon: marcos a cada 10 pontos multiplicam (ofensiva: todo o dano x1,25).
	var board := _world(3)
	board.set_paragon(1, {"level": 30, "experience": 0, "boards": {"eloa": {"ofensiva": 30, "defensiva": 0, "utilidade": 0, "elemental": 0}}})
	if not is_equal_approx(board._mod(1, "all_damage_mult"), pow(1.25, 3.0)):
		return _fail("Offensive Paragon milestones must multiply all damage: %s" % board._mod(1, "all_damage_mult"))
	print("BALANCE_CALIBRATION_OK: gem factors on load, difficulty adds no power, seals x damage and health with upgrades, percent damage excluded, seal drops and forge, multiplicative Paragon milestones")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
