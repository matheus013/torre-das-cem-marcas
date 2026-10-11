extends SceneTree

## Decisão 598, lote 2: lendários e relíquias reescritos para mudar uma regra do jogo. Cada regra é
## testada pelo efeito: queimadura eterna que se espalha, estilhaço, gemas de raio sem recarga, toxina
## a partir do acerto, custo em Vida, cura que vira barreira, defesa parada, crítico em cadência,
## Força que vira dano físico, autoataque que lança o Q, invocações eternas, recarga só por abates,
## gemas grátis andando, imunidade a contato, rastro ao andar e o Pacto de Sangue.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _world(items: Array[String], gems: Array[String] = [], character: StringName = &"sena") -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5871)
	sim.add_player(1, character)
	sim.unlock_all_gems(1)
	for slot in range(gems.size()):
		sim.set_gem_slot(1, slot, gems[slot])
	for item_id in items:
		sim.equip_item(1, sim._add_equipment_instance(character, item_id, "regular"))
	sim._passive_cache.clear()
	sim.enter_tower(1)
	sim.enemies.clear()
	var state := sim.player(1)
	state["health"] = sim.max_health(1)
	state["breath"] = 500.0
	state["attack_timer"] = 1.0e9
	return sim


func _enemy(sim: WorldSimulation, offset: Vector2, health: float = 1.0e9) -> Dictionary:
	var enemy := sim.create_enemy(sim.content("enemies")[0], (sim.player(1)["position"] as Vector2) + offset, sim.enemies.size())
	enemy["health"] = health
	enemy["max_health"] = 1.0e9
	enemy["speed"] = 0.0
	enemy["shield_hits"] = 0
	enemy["modifier_mechanics"] = []
	enemy["race_trait"] = ""
	sim.enemies.append(enemy)
	return enemy


func _hit(gem_id: String) -> Dictionary:
	return {"gem": true, "gem_id": gem_id, "damage_type": "arcane"}


func _ready_slot(sim: WorldSimulation, slot: int) -> void:
	(sim.player(1)["cooldowns"] as Array)[slot] = 0.0
	(sim.player(1)["charges"] as Array)[slot] = 1


func _step(sim: WorldSimulation, seconds: float) -> void:
	for _frame in range(int(round(seconds * 60.0))):
		sim.step(1.0 / 60.0)
		sim.drain_events()


func _run() -> void:
	# Fogo que Não Apaga: a queimadura não expira e passa para os vizinhos de quem morre em chamas.
	var fire := _world(["lendario_coroa_de_brasa"])
	var burning := _enemy(fire, Vector2(100.0, 0.0), 5.0)
	var neighbor := _enemy(fire, Vector2(160.0, 0.0))
	var fire_hit := _hit("bola_de_fogo")
	fire.damage_enemy(1, 0, 1.0, fire_hit)
	if float(burning.get("burn_timer", 0.0)) < 1000.0:
		return _fail("Burns must not expire with the crown")
	fire.damage_enemy(1, fire.enemies.find(burning), 100.0, fire_hit)
	if float(neighbor.get("burn_timer", 0.0)) <= 0.0:
		return _fail("Fire must spread to neighbors when a burning enemy dies")

	# Inverno Interior: gelo estilhaça abaixo de 20%.
	var ice := _world(["lendario_manto_do_inverno"])
	var weak := _enemy(ice, Vector2(100.0, 0.0), 1.0e9 * 0.15)
	ice.damage_enemy(1, 0, 1.0, _hit("esfera_de_gelo"))
	if ice.enemies.has(weak):
		return _fail("Ice hits must shatter enemies below 20%")

	# Sobrecarga: gema de raio sem recarga e com o dobro do custo.
	var plain_storm := _world([], ["arco_voltaico"])
	var storm := _world(["lendario_luvas_da_tempestade"], ["arco_voltaico"])
	for sim: WorldSimulation in [plain_storm, storm]:
		_enemy(sim, Vector2(150.0, 0.0))
		sim.use_skill(1, 0, (sim.player(1)["position"] as Vector2) + Vector2(150.0, 0.0))
	if float((storm.player(1)["cooldowns"] as Array)[0]) > 0.01 or not is_equal_approx(500.0 - float(storm.player(1)["breath"]), (500.0 - float(plain_storm.player(1)["breath"])) * 2.0):
		return _fail("Overcharge: lightning gems without cooldown at double cost")

	# Raiz e Ácido: acerto de ácido envenena.
	var swamp := _world(["lendario_botas_do_brejo"])
	var poisoned := _enemy(swamp, Vector2(100.0, 0.0))
	swamp.damage_enemy(1, 0, 100.0, _hit("bolha_corrosiva"))
	swamp.drain_events()
	if not (poisoned.get("poisons", {}) as Dictionary).has("toxina"):
		return _fail("Acid hits must also poison")

	# Pacto Sombrio: trevas custam Vida, não Fôlego.
	var dark := _world(["lendario_veu_do_eclipse"], ["cometa_sombrio"])
	_enemy(dark, Vector2(150.0, 0.0))
	var health := float(dark.player(1)["health"])
	dark.use_skill(1, 0, (dark.player(1)["position"] as Vector2) + Vector2(150.0, 0.0))
	if float(dark.player(1)["breath"]) != 500.0 or float(dark.player(1)["health"]) >= health:
		return _fail("Dark gems must cost health instead of breath")

	# Luz Excedente: cura acima do máximo vira barreira.
	var light := _world(["lendario_anel_do_sol_partido"])
	light.heal_player(1, 50.0)
	if float(light.player(1)["barrier"]) <= 0.0:
		return _fail("Overheal must become barrier")

	# Pedra Viva: parada por 1 s, recebe 40% menos dano.
	var stone := _world(["lendario_anel_da_terra_viva"])
	stone.player(1)["still_time"] = 2.0
	var before := float(stone.player(1)["health"])
	stone.take_damage(1, 50.0)
	var still_loss := before - float(stone.player(1)["health"])
	stone.player(1)["still_time"] = 0.0
	before = float(stone.player(1)["health"])
	stone.take_damage(1, 50.0)
	var moving_loss := before - float(stone.player(1)["health"])
	if not is_equal_approx(still_loss, moving_loss * 0.6):
		return _fail("Standing still must cut damage by 40%%: %.2f vs %.2f" % [still_loss, moving_loss])

	# Clarividência: só o 5º acerto de gema critica, com +200%.
	var lens := _world(["lendario_lente_arcana"])
	_enemy(lens, Vector2(100.0, 0.0))
	var crits := 0
	for index in range(10):
		lens.damage_enemy(1, 0, 10.0, _hit("orbe_de_ruptura"))
		for event: Dictionary in lens.drain_events():
			if String(event.get("call", "")) == "number" and bool((event["args"] as Array)[2]):
				crits += 1
				if not is_equal_approx(float(event["args"][1]), 30.0):
					return _fail("Cadence crits must deal +200%%, got %.1f" % float(event["args"][1]))
	if crits != 2:
		return _fail("Exactly every 5th gem hit must crit: %d crits in 10" % crits)

	# Peso da Montanha: Força vira dano físico; 25% mais lenta.
	var light_fist := _world([], ["ceifa_ampla"])
	var fist := _world(["lendario_punho_da_montanha"], ["ceifa_ampla"])
	var strength := fist.raw_stat(1, "strength")
	var physical := {"gem_id": "ceifa_ampla", "tags": ["physical"]}
	var ratio := fist._skill_power_multiplier(1, physical) / light_fist._skill_power_multiplier(1, physical)
	# A Força do item soma escala própria; a conversão garante pelo menos +1% por ponto de Força.
	if strength <= 0.0 or not is_equal_approx(fist._mod(1, "strength_physical_conversion"), 0.01) or ratio < 1.0 + strength * 0.01:
		return _fail("Strength must add 1%% physical damage per point (ratio %.3f, strength %.0f)" % [ratio, strength])
	if float(fist.derived_stats(1)["movement_speed_multiplier"]) >= float(light_fist.derived_stats(1)["movement_speed_multiplier"]) * 0.76:
		return _fail("Mountain weight must slow by 25%")

	# Erudição Absoluta: tudo custa Vida; Vida máxima +30%.
	var plain_scholar := _world([], ["anel_de_geada"])
	var scholar := _world(["lendario_tomo_do_erudito"], ["anel_de_geada"])
	if not is_equal_approx(scholar.max_health(1) / scholar._mod(1, "max_health_mult"), scholar.max_health(1) / 1.3) or scholar.max_health(1) <= plain_scholar.max_health(1):
		return _fail("Scholar tome must raise max health by 30%")
	health = float(scholar.player(1)["health"])
	scholar.use_skill(1, 0, scholar.player(1)["position"])
	if float(scholar.player(1)["breath"]) != 500.0 or float(scholar.player(1)["health"]) >= health:
		return _fail("Every gem must cost health with the tome")

	# Gatilho Ancestral: Q só pelo autoataque.
	var trigger := _world(["lendario_gatilho_ancestral"], ["orbe_de_ruptura"])
	if trigger.use_skill(1, 0, trigger.player(1)["position"]):
		return _fail("The Q gem must not be cast by hand with the ancestral trigger")
	var target := _enemy(trigger, Vector2(80.0, 0.0))
	trigger.player(1)["attack_timer"] = 0.0
	var casts := 0
	for _frame in range(120):
		trigger.step(1.0 / 60.0)
		for event: Dictionary in trigger.drain_events():
			casts += int(String(event.get("call", "")) == "cast")
	if casts < 1 or float(target["health"]) >= 1.0e9:
		return _fail("Auto attacks must cast the Q gem")

	# Rebanho Eterno: invocações duram 100x; Vida -25%.
	var herd := _world(["lendario_calca_do_pastor"], ["molde_vigilante"])
	_enemy(herd, Vector2(150.0, 0.0))
	herd.use_skill(1, 0, (herd.player(1)["position"] as Vector2) + Vector2(100.0, 0.0))
	var summons := herd.persistent_effects.filter(func(effect: Dictionary) -> bool: return effect["mechanic"] == "summon")
	if summons.is_empty() or float(summons[0]["duration"]) < 500.0:
		return _fail("Summons must last ~100x longer with the shepherd pants")

	# Tempo Roubado: recarga parada; abate adianta 1 s.
	var hourglass := _world(["lendario_ampulheta_partida"], ["anel_de_geada"])
	hourglass.use_skill(1, 0, hourglass.player(1)["position"])
	var cooldown := float((hourglass.player(1)["cooldowns"] as Array)[0])
	_step(hourglass, 2.0)
	if not is_equal_approx(float((hourglass.player(1)["cooldowns"] as Array)[0]), cooldown):
		return _fail("Cooldowns must not tick with time under stolen time")
	var fodder := _enemy(hourglass, Vector2(100.0, 0.0), 1.0)
	hourglass.damage_enemy(1, hourglass.enemies.find(fodder), 10.0, _hit("anel_de_geada"))
	if float((hourglass.player(1)["cooldowns"] as Array)[0]) > cooldown - 0.99:
		return _fail("Kills must advance cooldowns by 1 s")

	# Pulmão do Mundo: andando é grátis; parada custa o dobro.
	var plain_lungs := _world([], ["anel_de_geada"])
	var lungs := _world(["lendario_folego_primordial"], ["anel_de_geada"])
	plain_lungs.use_skill(1, 0, plain_lungs.player(1)["position"])
	var base_cost := 500.0 - float(plain_lungs.player(1)["breath"])
	lungs.player(1)["moving"] = true
	lungs.use_skill(1, 0, lungs.player(1)["position"])
	if float(lungs.player(1)["breath"]) != 500.0:
		return _fail("Gems must be free while moving")
	_ready_slot(lungs, 0)
	lungs.player(1)["moving"] = false
	lungs.use_skill(1, 0, lungs.player(1)["position"])
	if not is_equal_approx(500.0 - float(lungs.player(1)["breath"]), base_cost * 2.0):
		return _fail("Gems must cost double while standing still")

	# Colosso: imune a dano de contato.
	var colossus := _world(["lendario_couraca_do_colosso"])
	var brute := _enemy(colossus, Vector2(10.0, 0.0))
	brute["speed"] = 40.0
	brute["damage"] = 50.0
	brute["awakened"] = true
	brute["provoked"] = 10.0
	health = float(colossus.player(1)["health"])
	colossus.player(1)["invulnerable"] = 0.0
	_step(colossus, 2.0)
	if float(colossus.player(1)["health"]) < health:
		return _fail("Colossus must ignore contact damage")

	# Rastro de Caça: andando, fere quem está perto; parada, não.
	var hunter := _world(["lendario_botas_do_cacador"])
	var trailed := _enemy(hunter, Vector2(40.0, 0.0))
	_step(hunter, 1.0)
	if float(trailed["health"]) < 1.0e9:
		return _fail("The trail must not hurt while standing still")
	for _frame in range(60):
		hunter.player(1)["moving"] = true
		ItemPassives.tick(hunter, 1, 1.0 / 60.0)
		hunter.drain_events()
	if float(trailed["health"]) >= 1.0e9:
		return _fail("The trail must hurt nearby enemies while moving")

	# Pacto de Sangue: cura nenhuma; abate dá barreira.
	var pact := _world(["lendario_pacto_de_sangue"])
	pact.player(1)["health"] = 10.0
	pact.heal_player(1, 50.0)
	if float(pact.player(1)["health"]) != 10.0:
		return _fail("Blood pact must block healing")
	var prey := _enemy(pact, Vector2(100.0, 0.0), 1.0)
	pact.damage_enemy(1, pact.enemies.find(prey), 10.0, _hit("anel_de_geada"))
	if float(pact.player(1)["barrier"]) <= 0.0:
		return _fail("Blood pact kills must grant barrier")

	print("REVOLUTION_LEGENDARIES_OK: 16 rewritten legendaries and the new Blood Pact change game rules")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
