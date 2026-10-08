extends SceneTree

## Regressão (2026-10-07): dano contínuo (veneno e queimadura) não é bloqueável nem esquivável.
## Escudos de inimigos (afixo de primeiro golpe, barreira de aliado, Casca Adaptável) consumiam os
## ticks como "BLOQUEIO". Também: o raio da explosão de esporos cresce com a Inteligência.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const ItemPassives := preload("res://src/gameplay/items/item_passives.gd")


func _init() -> void:
	_run.call_deferred()


func _world(intelligence: float, gems: Array[String]) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5861)
	sim.add_player(1, &"eloa")
	sim.unlock_all_gems(1)
	for slot in range(gems.size()):
		sim.set_gem_slot(1, slot, gems[slot])
	for item: EquipmentItemInstance in (sim._gear(1)["equipment"] as EquipmentLoadout)._all_items():
		item.affixes = []
	sim._passive_cache.clear()
	var build := sim.character_build(1)
	for stat in CharacterBuild.PRIMARY_STATS:
		build.base_stats[stat] = 0.0
	build.base_stats[&"intelligence"] = intelligence
	sim.enter_tower(1)
	var state := sim.player(1)
	state["breath"] = 200.0
	state["health"] = 1.0e6
	sim.enemies.resize(2)
	for index in range(2):
		var enemy := sim.enemies[index]
		enemy["position"] = (state["position"] as Vector2) + Vector2(80.0, 0.0)
		enemy["health"] = 1.0e6
		enemy["max_health"] = 1.0e6
		enemy["shield_hits"] = 0
		enemy["speed"] = 0.0
		enemy["race_trait"] = ""
		enemy.erase("poisons")
	return sim


func _step(sim: WorldSimulation, seconds: float) -> Array:
	var events := []
	for _frame in range(int(round(seconds * 30.0))):
		sim.player(1)["health"] = 1.0e6
		# Sem autoataque: só o dano contínuo toca os escudos.
		sim.player(1)["attack_timer"] = 999.0
		for enemy in sim.enemies:
			enemy["vulnerable_amount"] = 0.0
		sim.step(1.0 / 30.0)
		events.append_array(sim.drain_events())
	return events


func _blocks(events: Array) -> int:
	return events.filter(func(event: Dictionary) -> bool: return String(event.get("call", "")) == "label" and String((event["args"] as Array)[1]) == "BLOQUEIO").size()


func _run() -> void:
	# Veneno contra escudo: todos os ticks acertam e nenhuma carga de bloqueio é gasta.
	var poisoned := _world(0.0, ["esporos"])
	var target := poisoned.enemies[0]
	poisoned.use_skill(1, 0, target["position"])
	target["shield_hits"] = 2
	var events := _step(poisoned, 3.05)
	if float(target["health"]) >= 1.0e6 or int(target["shield_hits"]) != 2 or _blocks(events) > 0:
		return _fail("Poison ticks were blocked by an enemy shield (health %.1f, shields %d)" % [float(target["health"]), int(target["shield_hits"])])

	# Casca Adaptável: ticks de veneno não contam como golpes, então não geram escudo.
	var adaptive := _world(0.0, ["esporos"])
	var shell := adaptive.enemies[0]
	shell["race_trait"] = "adaptive_shell"
	adaptive.use_skill(1, 0, shell["position"])
	_step(adaptive, 6.05)
	if int(shell["shield_hits"]) != 0:
		return _fail("Adaptive shell grew shields from poison ticks: %d" % int(shell["shield_hits"]))

	# Queimadura contra escudo: o tick acerta, não critica e usa o número laranja de queimadura.
	var burning := _world(0.0, [])
	var burnt := burning.enemies[0]
	burnt["shield_hits"] = 3
	burnt["burn_timer"] = 2.0
	burnt["burn_dps"] = 40.0
	burnt["burn_peer"] = 1
	burnt["burn_tick"] = ItemPassives.BURN_TICK
	events = _step(burning, 1.05)
	var burn_numbers := events.filter(func(event: Dictionary) -> bool: return String(event.get("call", "")) == "number" and (event["args"] as Array).size() > 3 and String(event["args"][3]) == "burn")
	if float(burnt["health"]) >= 1.0e6 or int(burnt["shield_hits"]) != 3 or burn_numbers.is_empty() or _blocks(events) > 0:
		return _fail("Burn ticks were blocked or not shown as burn (health %.1f, shields %d)" % [float(burnt["health"]), int(burnt["shield_hits"])])
	if burn_numbers.any(func(event: Dictionary) -> bool: return bool(event["args"][2])):
		return _fail("Burn ticks must not crit")

	# Golpe direto continua sendo bloqueado: só o dano contínuo atravessa.
	var direct := _world(0.0, [])
	var guarded := direct.enemies[0]
	guarded["shield_hits"] = 1
	direct.damage_enemy(1, 0, 50.0, {"gem": true})
	if float(guarded["health"]) != 1.0e6 or int(guarded["shield_hits"]) != 0:
		return _fail("Direct hits must still be blocked by shields")

	# Raio da explosão de esporos: +0,4% por Inteligência efetiva, até +100%. Acima de 100 pontos a
	# Inteligência rende 75% (StatResolver): 300 brutos são 225 efetivos, x1,9.
	var reach := {}
	for intelligence in [0.0, 50.0, 300.0]:
		var sim := _world(intelligence, ["esporos"])
		reach[intelligence] = sim.spore_spread_multiplier(1)
		var dying := sim.enemies[0]
		var far := sim.enemies[1]
		far["position"] = (dying["position"] as Vector2) + Vector2(200.0, 0.0)
		sim.use_skill(1, 0, dying["position"])
		dying["health"] = 1.0
		_step(sim, 1.05)
		var reached := (far.get("poisons", {}) as Dictionary).has("esporo")
		if reached != (intelligence >= 300.0):
			return _fail("Spore burst at 200 must reach only with high Intelligence (INT %d reached=%s, x%.2f)" % [int(intelligence), reached, float(reach[intelligence])])
	if not is_equal_approx(float(reach[0.0]), 1.0) or not is_equal_approx(float(reach[50.0]), 1.2) or not is_equal_approx(float(reach[300.0]), 1.9):
		return _fail("Spore spread multiplier must be 1.0 / 1.2 / 1.9 for INT 0 / 50 / 300: %s" % [reach])
	var rows := (_world(50.0, []).detailed_stats(1)["combat"] as Array).filter(func(row: Array) -> bool: return String(row[0]).begins_with("Raio da explosao de esporos"))
	if rows.size() != 1 or not String(rows[0][1]).begins_with("+20%"):
		return _fail("Detailed stats must show the spore burst radius from Intelligence: %s" % [rows])

	print("DOT_UNBLOCKABLE_OK: poison and burn ignore shields; spore burst radius scales with Intelligence")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
