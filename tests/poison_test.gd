extends SceneTree

## Decisão 586 (esporo revisto na 591): venenos de tipos diferentes. Esporo é uma colônia que cresce,
## não escala com atributos e se espalha na morte; toxina da poça escala com Inteligência e não cresce; ticks de veneno são
## verdes e não criticam; Presa da Serpente explode qualquer inimigo envenenado e deixa uma poça.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _world(intelligence: float, gems: Array[String], items: Array[String] = []) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5860)
	sim.add_player(1, &"eloa")
	sim.unlock_all_gems(1)
	for slot in range(gems.size()):
		sim.set_gem_slot(1, slot, gems[slot])
	for item_id in items:
		sim.equip_item(1, sim._add_equipment_instance(&"eloa", item_id, "regular"))
	# Atributos e afixos fora da conta: só a Inteligência pedida escala.
	# (afixos fixos, como a proliferação da Presa, ficam)
	for item: EquipmentItemInstance in (sim._gear(1)["inventory"] as ItemInventory).items.values():
		item.affixes = item.affixes.filter(func(affix: Dictionary) -> bool: return String(affix["id"]) == "proliferacao")
	for item: EquipmentItemInstance in (sim._gear(1)["equipment"] as EquipmentLoadout)._all_items():
		item.affixes = item.affixes.filter(func(affix: Dictionary) -> bool: return String(affix["id"]) == "proliferacao")
	sim._passive_cache.clear()
	var build := sim.character_build(1)
	for stat in CharacterBuild.PRIMARY_STATS:
		build.base_stats[stat] = 0.0
	build.base_stats[&"intelligence"] = intelligence
	sim.enter_tower(1)
	var state := sim.player(1)
	state["breath"] = 200.0
	state["health"] = 1.0e6
	sim.enemies.resize(3)
	for index in range(3):
		var enemy := sim.enemies[index]
		enemy["position"] = (state["position"] as Vector2) + Vector2(80.0 + index * 40.0, 0.0)
		enemy["health"] = 1.0e6
		enemy["max_health"] = 1.0e6
		enemy["shield_hits"] = 0
		enemy["speed"] = 0.0
		enemy.erase("poisons")
		# Resistências por raça (E1 fase 1) ficam fora da conta: o teste mede a regra do veneno.
		enemy["resistances"] = {}
	return sim


func _step(sim: WorldSimulation, seconds: float) -> Array:
	var events := []
	for _frame in range(int(round(seconds * 30.0))):
		sim.player(1)["health"] = 1.0e6
		# Vulnerabilidade de outras fontes (ex.: Luz Residual da Eloa) amplifica veneno; aqui, só o veneno.
		for enemy in sim.enemies:
			enemy["vulnerable_amount"] = 0.0
		sim.step(1.0 / 30.0)
		events.append_array(sim.drain_events())
	return events


func _poison_numbers(events: Array) -> Array:
	return events.filter(func(event: Dictionary) -> bool: return String(event.get("call", "")) == "number" and (event["args"] as Array).size() > 3 and String(event["args"][3]) == "poison")


func _run() -> void:
	# Esporos (decisão 591): sem dano direto; tick = (5 + fração da Vida máxima) × acúmulo, que cresce
	# 20% por tick; mesma conta com 0 ou 300 de Inteligência.
	for intelligence in [0.0, 300.0]:
		var spore := _world(intelligence, ["esporos"])
		var target := spore.enemies[0]
		if not spore.use_skill(1, 0, target["position"]) or float(target["health"]) != 1.0e6:
			return _fail("Spores must infect without direct damage")
		var poison := (target["poisons"] as Dictionary)["esporo"] as Dictionary
		if not is_equal_approx(float(poison["damage"]), 5.0) or not is_equal_approx(float(poison["stack"]), 1.0):
			return _fail("Spore poison starts at 5 x1 and ignores Intelligence, got %.2f x%.2f" % [float(poison["damage"]), float(poison["stack"])])
		var first := 5.0 + spore.spore_health_share(target) * 1.0e6
		var events := _step(spore, 2.05)
		var ticks := _poison_numbers(events)
		if ticks.size() != 2 or not is_equal_approx(float(ticks[0]["args"][1]), first) or not is_equal_approx(float(ticks[1]["args"][1]), first * 1.2):
			return _fail("Spore ticks must be %.0f then x1.2, got %s" % [first, ticks.map(func(event: Dictionary) -> float: return float(event["args"][1]))])
		if ticks.any(func(event: Dictionary) -> bool: return bool(event["args"][2])):
			return _fail("Poison ticks never crit")

	# Espalhamento: o alvo morre e os vizinhos recebem esporos com o acúmulo atual, mutado +10%.
	var spread := _world(0.0, ["esporos"])
	spread.use_skill(1, 0, spread.enemies[0]["position"])
	_step(spread, 3.05)
	var current := float((spread.enemies[0]["poisons"] as Dictionary)["esporo"]["stack"])
	var dying := spread.enemies[0]
	var neighbours := [spread.enemies[1], spread.enemies[2]]
	dying["health"] = 1.0
	_step(spread, 1.05)
	if spread.enemies.has(dying):
		return _fail("Spored target must die from its tick")
	for enemy: Dictionary in neighbours:
		var inherited := (enemy.get("poisons", {}) as Dictionary).get("esporo", {}) as Dictionary
		if inherited.is_empty() or float(inherited["stack"]) < current * 1.1:
			return _fail("Spores spread to neighbours keeping the grown stack")

	# Poça: toxina constante (não cresce) que escala com Inteligência e dura 2 s depois de sair.
	var weak := _world(0.0, ["poca_de_veneno"])
	var strong := _world(100.0, ["poca_de_veneno"])
	var weak_ticks := []
	var strong_ticks := []
	for pair in [[weak, weak_ticks], [strong, strong_ticks]]:
		var sim := pair[0] as WorldSimulation
		sim.use_skill(1, 0, sim.enemies[0]["position"])
		for event: Dictionary in _poison_numbers(_step(sim, 3.0)):
			(pair[1] as Array).append(float(event["args"][1]))
	if weak_ticks.size() < 4 or not is_equal_approx(float(weak_ticks[0]), float(weak_ticks[weak_ticks.size() - 1])):
		return _fail("Pool toxin must not grow: %s" % [weak_ticks])
	var ratio := float(strong_ticks[0]) / float(weak_ticks[0])
	if not is_equal_approx(snappedf(ratio, 0.01), 1.6):
		return _fail("Pool toxin scales with Intelligence (100 INT = x1.6), got x%.2f" % ratio)
	var lingering := strong.enemies[2]
	strong.persistent_effects.clear()
	_step(strong, 2.6)
	if not (lingering.get("poisons", {}) as Dictionary).is_empty():
		return _fail("Toxin must fade 2 s after leaving the pool")

	# Presa da Serpente: qualquer veneno; explode com 20% da Vida máxima e deixa uma poça.
	var plain := _world(0.0, ["esporos"], ["lendario_presa_da_serpente"])
	var victim := plain.enemies[0]
	plain.apply_poison(1, victim, "toxina", {"damage": 1.0, "interval": 0.5, "remaining": 5.0})
	victim["max_health"] = 1000.0
	victim["health"] = 1.0
	var neighbour := plain.enemies[1]
	var before := float(neighbour["health"])
	_step(plain, 0.6)
	if absf((before - float(neighbour["health"])) - 200.0) > 30.0:
		return _fail("Serpent fang explosion deals 20%% of the victim max health, got %.0f" % (before - float(neighbour["health"])))
	var base_pool := plain.persistent_effects.filter(func(effect: Dictionary) -> bool: return String(effect["mechanic"]) == "poison_pool")
	if base_pool.size() != 1 or not is_equal_approx(float(base_pool[0]["radius"]), _pool_radius(plain)):
		return _fail("Serpent fang must leave a level 1 poison pool (radius x area x spread)")
	# Gema no nível 21 (requisito de Inteligência cumprido) com Pântano Profundo e Pântano Sem Fim.
	var evolved := _world(300.0, ["poca_de_veneno"], ["lendario_presa_da_serpente"])
	var progress := evolved._gem_state(1)["gems"]["poca_de_veneno"] as Dictionary
	progress["level"] = 21
	progress["choices"] = {"5": "poca_de_veneno_m5_0", "21": "poca_de_veneno_m21_0"}
	var spored := evolved.enemies[0]
	evolved.apply_poison(1, spored, "esporo", {"damage": 1.0, "growth": 0.2, "interval": 0.5, "remaining": -1.0})
	spored["health"] = 1.0
	_step(evolved, 0.6)
	var evolved_pool := evolved.persistent_effects.filter(func(effect: Dictionary) -> bool: return String(effect["mechanic"]) == "poison_pool")
	if evolved_pool.is_empty() or not is_equal_approx(float(evolved_pool[0]["radius"]), _pool_radius(evolved) * 1.4 * 1.6):
		return _fail("With the pool gem equipped the fang pool carries its upgrades (radius x1.4 x1.6)")
	# Proliferação: toda Presa traz +30% a +100%; amplia o espalhamento dos esporos e a poça.
	var fang_sim := _world(0.0, ["esporos"])
	var spread_values := []
	for copy in range(12):
		var fang_id := fang_sim._add_equipment_instance(&"eloa", "lendario_presa_da_serpente", "regular")
		var fang := (fang_sim._gear(1)["inventory"] as ItemInventory).get_item(fang_id)
		var fixed := fang.affixes.filter(func(affix: Dictionary) -> bool: return String(affix["id"]) == "proliferacao")
		if fixed.size() != 1 or float(fixed[0]["value"]) < 0.3 or float(fixed[0]["value"]) > 1.0:
			return _fail("Every Serpent Fang carries spread range +30%% to +100%%: %s" % [fang.affixes])
		spread_values.append(float(fixed[0]["value"]))
	if spread_values.min() == spread_values.max():
		return _fail("Spread range must vary between copies")
	var reach := _world(0.0, ["esporos"], ["lendario_presa_da_serpente"])
	var bonus := reach._mod(1, "poison_spread_mult")
	if bonus < 1.3 or bonus > 2.0:
		return _fail("Equipped fang must raise poison_spread_mult to 1.3..2.0, got %.2f" % bonus)
	var carrier := reach.enemies[0]
	var far := reach.enemies[1]
	far["position"] = (carrier["position"] as Vector2) + Vector2(130.0 * (1.0 + (bonus - 1.0) * 0.5) + 4.0, 0.0)
	reach.apply_poison(1, carrier, "esporo", {"damage": 1.0, "growth": 0.2, "interval": 0.5, "remaining": -1.0, "spread_radius": 130.0})
	carrier["health"] = 1.0
	_step(reach, 0.6)
	if not (far.get("poisons", {}) as Dictionary).has("esporo"):
		return _fail("Spores must reach farther with the fang's spread range")
	var fang_pool := reach.persistent_effects.filter(func(effect: Dictionary) -> bool: return String(effect["mechanic"]) == "poison_pool")
	if fang_pool.is_empty() or not is_equal_approx(float(fang_pool[0]["radius"]), _pool_radius(reach)) or bonus <= 1.0:
		return _fail("Fang pool radius scales with the spread range")

	print("POISON_OK: growing fixed spores, spread on death, green non-crit ticks, INT-scaled constant toxin with linger, serpent fang on any poison with upgraded pool and +30..100% spread range")
	quit(0)


## Raio da poça de nível 1 lançada pela Presa: base do catálogo x Área x proliferação.
func _pool_radius(sim: WorldSimulation) -> float:
	return float(sim.gem_definition("poca_de_veneno")["radius"]) * float(sim.derived_stats(1)["area_multiplier"]) * sim._mod(1, "poison_spread_mult")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
