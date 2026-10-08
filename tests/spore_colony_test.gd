extends SceneTree

## Decisão 591: colônia de esporos. O tick é (5 + fração da Vida máxima do alvo) × acúmulo, então a
## gema vale o mesmo contra mil ou bilhões de Vida; o acúmulo tem teto (x25, Sabedoria até x40); a
## Cepa faz infecções novas herdarem metade do maior acúmulo do andar; cada salto muta +10%.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _world(wisdom: float, health: float, encounter: String = "common") -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5862)
	sim.add_player(1, &"eloa")
	sim.unlock_all_gems(1)
	sim.set_gem_slot(1, 0, "esporos")
	for item: EquipmentItemInstance in (sim._gear(1)["equipment"] as EquipmentLoadout)._all_items():
		item.affixes = []
	sim._passive_cache.clear()
	var build := sim.character_build(1)
	for stat in CharacterBuild.PRIMARY_STATS:
		build.base_stats[stat] = 0.0
	build.base_stats[&"wisdom"] = wisdom
	sim.enter_tower(1)
	var state := sim.player(1)
	state["breath"] = 200.0
	sim.enemies.resize(2)
	for index in range(2):
		var enemy := sim.enemies[index]
		enemy["position"] = (state["position"] as Vector2) + Vector2(80.0 + index * 40.0, 0.0)
		enemy["health"] = health
		enemy["max_health"] = health
		enemy["shield_hits"] = 0
		enemy["speed"] = 0.0
		enemy["encounter_class"] = encounter
		enemy["floor_boss"] = false
		enemy.erase("poisons")
	return sim


func _step(sim: WorldSimulation, seconds: float) -> void:
	for _frame in range(int(round(seconds * 30.0))):
		sim.player(1)["health"] = 1.0e6
		sim.player(1)["attack_timer"] = 999.0
		for enemy in sim.enemies:
			enemy["vulnerable_amount"] = 0.0
		sim.step(1.0 / 30.0)
		sim.drain_events()


## Segundos até a colônia derrubar um alvo sozinho (ou -1 se não derrubar no limite).
func _kill_time(health: float, encounter: String) -> float:
	var sim := _world(0.0, health, encounter)
	var target := sim.enemies[0]
	sim.use_skill(1, 0, target["position"])
	for second in range(1, 121):
		_step(sim, 1.0)
		if not sim.enemies.has(target) or float(target["health"]) <= 0.0:
			return float(second)
	return -1.0


func _run() -> void:
	# Escala invariante: um milhão e um bilhão de Vida caem no mesmo tempo; com mil, a base fixa de 5
	# ainda pesa e o alvo cai antes.
	var times := []
	for health in [1.0e3, 1.0e6, 1.0e9]:
		times.append(_kill_time(health, "common"))
	if times.has(-1.0) or absf(float(times[1]) - float(times[2])) > 1.0 or float(times[0]) > float(times[1]) or float(times.max()) > 40.0:
		return _fail("Spores must kill any common enemy in the same time, whatever its health: %s" % [times])
	# Chefes usam uma fração 10x menor: demoram muito mais, sem ficarem imunes.
	var boss_time := _kill_time(1.0e9, "boss")
	if boss_time >= 0.0 and boss_time < float(times.max()) * 2.0:
		return _fail("Bosses must take much longer than commons to a lone colony: boss %.0f s, common %s" % [boss_time, times])
	var shares := _world(0.0, 1.0e6)
	var dummy := {"encounter_class": "elite"}
	if not is_equal_approx(shares.spore_health_share(dummy), 0.0025) or not is_equal_approx(shares.spore_health_share({"floor_boss": true}), 0.0005) or not is_equal_approx(shares.spore_health_share({}), 0.005):
		return _fail("Health share must be 0.5% common, 0.25% elite, 0.05% boss")

	# Teto: x25 sem Sabedoria; 150 de Sabedoria (137,5 efetivos) leva a x38,75.
	for case in [[0.0, 25.0], [150.0, 38.75]]:
		var capped := _world(float(case[0]), 1.0e15)
		var host := capped.enemies[0]
		capped.use_skill(1, 0, host["position"])
		_step(capped, 40.0)
		var stack := float((host["poisons"] as Dictionary)["esporo"]["stack"])
		if not is_equal_approx(stack, float(case[1])) or not is_equal_approx(capped.spore_stack_cap(1), float(case[1])):
			return _fail("Spore stack cap must be x%.2f with %d Wisdom, got x%.2f" % [float(case[1]), int(case[0]), stack])

	# Cepa: depois de cultivar a colônia, uma infecção nova começa com metade do maior acúmulo.
	var strain := _world(0.0, 1.0e15)
	strain.use_skill(1, 0, strain.enemies[0]["position"])
	_step(strain, 10.05)
	var grown := float((strain.enemies[0]["poisons"] as Dictionary)["esporo"]["stack"])
	(strain.player(1)["cooldowns"] as Array[float]).fill(0.0)
	var fresh := strain.enemies[1]
	fresh["position"] = (strain.player(1)["position"] as Vector2) + Vector2(0.0, 300.0)
	strain.use_skill(1, 0, fresh["position"])
	var inherited := float(((fresh.get("poisons", {}) as Dictionary).get("esporo", {}) as Dictionary).get("stack", 0.0))
	if grown < 5.0 or not is_equal_approx(inherited, grown * 0.5):
		return _fail("New infections must inherit half the floor's strain: grown x%.2f, fresh x%.2f" % [grown, inherited])
	strain.current_floor += 1
	if strain.spore_strain(1) != 0.0:
		return _fail("The strain must reset on another floor")

	# Mutação: o salto leva o acúmulo do tick fatal +10% e a fração da Vida passa a ser a do novo alvo.
	var mutate := _world(0.0, 1.0e6)
	var dying := mutate.enemies[0]
	var next := mutate.enemies[1]
	next["encounter_class"] = "elite"
	mutate.use_skill(1, 0, dying["position"])
	_step(mutate, 3.05)
	var before := float((dying["poisons"] as Dictionary)["esporo"]["stack"])
	dying["health"] = 1.0
	_step(mutate, 1.05)
	var jumped := (next.get("poisons", {}) as Dictionary).get("esporo", {}) as Dictionary
	if jumped.is_empty() or not is_equal_approx(float(jumped["stack"]), before * 1.1) or not is_equal_approx(float(jumped["share"]), 0.0025):
		return _fail("Spread must mutate the stack +10%% and use the new target's share: %s (before x%.2f)" % [jumped, before])

	var rows := (_world(150.0, 1.0).detailed_stats(1)["combat"] as Array).filter(func(row: Array) -> bool: return String(row[0]).begins_with("Teto do acumulo de esporos"))
	if rows.size() != 1 or String(rows[0][1]) != "x38.8":
		return _fail("Detailed stats must show the spore stack cap from Wisdom: %s" % [rows])

	print("SPORE_COLONY_OK: health-share ticks (kill times %s s, boss %.0f s), cap x25..x38.75, strain, mutation" % [times, boss_time])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
