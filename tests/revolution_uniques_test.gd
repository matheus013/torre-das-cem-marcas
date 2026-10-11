extends SceneTree

## Decisão 598, lote 1: armas únicas reescritas para mudar a regra da gema. Cada uma é testada pelo
## comportamento (não pelo texto): ricochete, retorno, campo que puxa, sol que segue a personagem,
## divisão, estilhaço, órbita, reinício por abate, golpe de chegada, lançamento automático,
## imobilização, fenda, repulsão, zona permanente, propagação por abate e assim por diante.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _world(gem_id: String) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5870)
	sim.add_player(1, &"sena")
	sim.unlock_all_gems(1)
	sim.set_gem_slot(1, 0, gem_id)
	var weapon := sim._add_equipment_instance(&"sena", "unica_" + gem_id)
	sim.equip_item(1, weapon)
	sim.enter_tower(1)
	sim.enemies.clear()
	var state := sim.player(1)
	state["health"] = 1.0e9
	state["invulnerable"] = 1.0e9
	state["breath"] = 1.0e6
	state["attack_timer"] = 1.0e9
	return sim


func _enemy(sim: WorldSimulation, offset: Vector2, health: float = 1.0e9) -> Dictionary:
	var definition := sim.content("enemies")[0]
	var enemy := sim.create_enemy(definition, (sim.player(1)["position"] as Vector2) + offset, sim.enemies.size())
	enemy["health"] = health
	enemy["max_health"] = maxf(health, 1.0e9) if health < 1.0e9 else health
	enemy["speed"] = 0.0
	enemy["shield_hits"] = 0
	enemy["prefix_id"] = ""
	enemy["suffix_id"] = ""
	enemy["modifier_mechanics"] = []
	sim.enemies.append(enemy)
	return enemy


func _cast(sim: WorldSimulation, target: Vector2) -> bool:
	var state := sim.player(1)
	(state["cooldowns"] as Array)[0] = 0.0
	(state["charges"] as Array)[0] = 1
	return sim.use_skill(1, 0, target)


func _step(sim: WorldSimulation, seconds: float) -> void:
	for _frame in range(int(round(seconds * 60.0))):
		var state := sim.player(1)
		state["breath"] = 1.0e6
		state["health"] = 1.0e9
		sim.step(1.0 / 60.0)
		sim.drain_events()


func _effects(sim: WorldSimulation, gem_id: String) -> Array:
	return sim.persistent_effects.filter(func(effect: Dictionary) -> bool: return String(effect.get("gem_id", "")) == gem_id)


func _run() -> void:
	# Campos resolvidos que definem a nova regra de cada gema.
	var fields := {
		"agulha_lastro": {"ricochet": 6, "return_projectile": true},
		"lanca_ferral": {"pierce": 99, "return_projectile": true},
		"orbe_de_ruptura": {"mechanic": "field", "pull_strength": 140},
		"bola_de_fogo": {"mechanic": "field", "field_follows_player": true},
		"bolha_corrosiva": {"fork_count": 3},
		"disco_de_retorno": {"mechanic": "orbit", "orbit_count": 2},
		"anel_de_geada": {"root": true},
		"ruptura_sismica": {"mechanic": "beam"},
		"prisao_gravitica": {"field_follows_player": true, "pull_strength": -220},
		"brasa_persistente": {"deploy_limit": 1},
		"raizes_presas": {"field_follows_player": true},
		"arco_voltaico": {"chain_count": 30},
		"semeadura_vital": {"field_follows_player": true},
		"sopro_criogenico": {"mechanic": "beam"},
		"laminas_orbitais": {"deploy_limit": 1},
		"pilar_sagrado": {"mechanic": "field"},
		"poca_de_veneno": {"field_follows_player": true},
		"trovao_descendente": {"mechanic": "chain", "chain_count": 5},
	}
	for gem_id: String in fields:
		var sim := _world(gem_id)
		var resolved := sim.resolve_slot(1, 0)
		for field: String in fields[gem_id]:
			if resolved.get(field) != fields[gem_id][field]:
				return _fail("%s: unique must set %s = %s, got %s" % [gem_id, field, fields[gem_id][field], resolved.get(field)])
		# Sem a arma única, a gema volta ao normal.
		sim.unequip_item(1, EquipmentItemDefinition.Slot.WEAPON, 0)
		var plain := sim.resolve_slot(1, 0)
		for field: String in fields[gem_id]:
			if plain.get(field) == fields[gem_id][field] and field != "mechanic":
				return _fail("%s: %s must come only from the unique weapon" % [gem_id, field])

	# Orbe Gravitacional: vira campo que puxa e explode com o dobro do golpe.
	var orb := _world("orbe_de_ruptura")
	var pulled := _enemy(orb, Vector2(300.0, 100.0))
	_cast(orb, (orb.player(1)["position"] as Vector2) + Vector2(300.0, 0.0))
	var field: Array = _effects(orb, "orbe_de_ruptura")
	if field.is_empty() or float(field[0]["expire_damage"]) <= float(field[0]["power"]):
		return _fail("Gravitational orb must deploy a field with a strong final burst")
	var start := (pulled["position"] as Vector2).distance_to(field[0]["position"])
	_step(orb, 0.5)
	if (pulled["position"] as Vector2).distance_to(field[0]["position"]) >= start:
		return _fail("Gravitational orb must pull enemies in")

	# Sol Cativo, Repulsão, Trilha de Raízes, Jardim e Poça Viva acompanham a personagem.
	for gem_id in ["bola_de_fogo", "prisao_gravitica", "raizes_presas", "semeadura_vital", "poca_de_veneno"]:
		var aura := _world(gem_id)
		_cast(aura, (aura.player(1)["position"] as Vector2) + Vector2(200.0, 0.0))
		aura.move_player(1, Vector2(150.0, 90.0))
		_step(aura, 0.1)
		var own: Array = _effects(aura, gem_id)
		if own.is_empty() or (own[0]["position"] as Vector2).distance_to(aura.player(1)["position"]) > 1.0:
			return _fail("%s must follow the character" % gem_id)

	# Repulsão: inimigo dentro do raio é empurrado para fora.
	var push := _world("prisao_gravitica")
	var close := _enemy(push, Vector2(40.0, 0.0))
	_cast(push, push.player(1)["position"])
	_step(push, 1.0)
	if (close["position"] as Vector2).distance_to(push.player(1)["position"]) < 140.0:
		return _fail("Repulsion must push enemies out of its radius")

	# Zero Absoluto: estilhaça abaixo de 25% e solta esferas nos vizinhos.
	var ice := _world("esfera_de_gelo")
	var weak := _enemy(ice, Vector2(160.0, 0.0), 1.0e9)
	weak["health"] = float(weak["max_health"]) * 0.2
	var neighbor := _enemy(ice, Vector2(260.0, 60.0))
	_cast(ice, weak["position"])
	_step(ice, 1.5)
	if ice.enemies.has(weak) or float(neighbor["health"]) >= 1.0e9:
		return _fail("Absolute zero must shatter weak enemies and launch shards at neighbors")

	# Corte em Cadeia: abater zera a recarga.
	var dash := _world("corte_vetorial")
	var victim := _enemy(dash, Vector2(120.0, 0.0), 1.0)
	victim["max_health"] = 1.0
	_cast(dash, victim["position"])
	_step(dash, 0.1)
	if dash.enemies.has(victim) or float((dash.player(1)["cooldowns"] as Array)[0]) > 0.0:
		return _fail("Chain cut must reset its cooldown on a kill")

	# Salto do Martelo: aterrissagem fere e repele.
	var leap := _world("salto_de_guarda")
	var landing := _enemy(leap, Vector2(200.0, 0.0))
	var before := (landing["position"] as Vector2)
	_cast(leap, landing["position"])
	_step(leap, 0.1)
	if float(landing["health"]) >= 1.0e9 or (landing["position"] as Vector2).is_equal_approx(before):
		return _fail("Hammer leap must damage and knock back on landing")

	# Pulso Constante: dispara sozinho e fere quem está perto.
	var pulse := _world("pulso_cicatriz")
	var near := _enemy(pulse, Vector2(90.0, 0.0))
	_step(pulse, 3.0)
	if float(near["health"]) >= 1.0e9:
		return _fail("Constant pulse must cast on its own")
	# Artilharia Ferral: a Chuva cai sozinha (os meteoros caem em volta do alvo, então conta impactos).
	var artillery := _world("chuva_ferral")
	_enemy(artillery, Vector2(200.0, 0.0))
	var rings := 0
	for _frame in range(int(4.5 * 60.0)):
		artillery.player(1)["breath"] = 1.0e6
		artillery.step(1.0 / 60.0)
		for event: Dictionary in artillery.drain_events():
			rings += int(String(event.get("call", "")) == "target_ring")
	if rings < 6:
		return _fail("Feral artillery must rain on its own every 2 s: %d impacts" % rings)

	# Inverno que Prende: imobiliza por completo.
	var frost := _world("anel_de_geada")
	var frozen := _enemy(frost, Vector2(80.0, 0.0))
	_cast(frost, frost.player(1)["position"])
	_step(frost, 0.1)
	if not is_equal_approx(float(frozen.get("slow_amount", 0.0)), 1.0):
		return _fail("Binding winter must fully root enemies")

	# Fenda e Raio Congelante: linha longa até o alvo.
	for gem_id in ["ruptura_sismica", "sopro_criogenico"]:
		var line := _world(gem_id)
		var far := _enemy(line, Vector2(450.0, 0.0))
		_cast(line, far["position"])
		_step(line, 0.2)
		if float(far["health"]) >= 1.0e9:
			return _fail("%s must strike in a long line" % gem_id)

	# Fogueira Perene e Ciclone Perpétuo: só uma, sem expirar.
	for gem_id in ["brasa_persistente", "laminas_orbitais"]:
		var perennial := _world(gem_id)
		_cast(perennial, (perennial.player(1)["position"] as Vector2) + Vector2(150.0, 0.0))
		_cast(perennial, (perennial.player(1)["position"] as Vector2) + Vector2(-150.0, 0.0))
		_step(perennial, 20.0)
		if _effects(perennial, gem_id).size() != 1:
			return _fail("%s must keep exactly one permanent instance" % gem_id)

	# Pântano Contagioso: quem morre dentro abre outro Pântano.
	var swamp := _world("pantano_acido")
	var drowned := _enemy(swamp, Vector2(200.0, 0.0), 1.0)
	drowned["max_health"] = 1.0
	_cast(swamp, drowned["position"])
	_step(swamp, 1.5)
	if _effects(swamp, "pantano_acido").size() < 2:
		return _fail("Contagious swamp must open a new swamp where an enemy dies")

	# Muralha Ofensiva: o que sobra da barreira vira explosão de 3x.
	var wall := _world("muralha_refeita")
	_cast(wall, wall.player(1)["position"])
	if float(wall.player(1)["barrier_expire_damage"]) < float(wall.player(1)["barrier"]) * 2.9:
		return _fail("Offensive wall must explode with 3x the barrier")

	# Arco Infinito e Raio em Cadeia: saltos em sequência.
	var arc := _world("arco_voltaico")
	var hit_count := 0
	for index in range(12):
		_enemy(arc, Vector2(120.0 + index * 70.0, 0.0))
	_cast(arc, (arc.player(1)["position"] as Vector2) + Vector2(120.0, 0.0))
	_step(arc, 0.2)
	for enemy in arc.enemies:
		hit_count += int(float(enemy["health"]) < 1.0e9)
	if hit_count < 10:
		return _fail("Infinite arc must jump far beyond its normal 6 targets: %d" % hit_count)

	# Fome da Rede: abates acumulam dano de trevas.
	var drain := _world("dreno_em_rede")
	var prey := _enemy(drain, Vector2(150.0, 0.0), 1.0)
	prey["max_health"] = 1.0
	_cast(drain, prey["position"])
	_step(drain, 0.2)
	var buffs := (drain.player(1).get("item_passive", {}) as Dictionary).get("buffs", {}) as Dictionary
	if int((buffs.get("fome_da_rede", {}) as Dictionary).get("stacks", 0)) < 1:
		return _fail("Hungry web must stack dark damage on kills")

	# Ceifa Giratória: corta também atrás.
	var reap := _world("ceifa_ampla")
	var behind := _enemy(reap, Vector2(-100.0, 0.0))
	_cast(reap, (reap.player(1)["position"] as Vector2) + Vector2(100.0, 0.0))
	_step(reap, 0.1)
	if float(behind["health"]) >= 1.0e9:
		return _fail("Spinning scythe must hit all around")

	# Prisma Dividido: três alvos diferentes por lançamento.
	var prism := _world("raio_prismatico")
	var targets := [_enemy(prism, Vector2(200.0, 0.0)), _enemy(prism, Vector2(0.0, 220.0)), _enemy(prism, Vector2(-210.0, 0.0))]
	_cast(prism, targets[0]["position"])
	_step(prism, 0.2)
	if targets.any(func(enemy: Dictionary) -> bool: return float(enemy["health"]) >= 1.0e9):
		return _fail("Split prism must hit three different enemies")

	# Discos Gêmeos: orbitam e cortam quem chega perto.
	var discs := _world("disco_de_retorno")
	var orbiting := _enemy(discs, Vector2(110.0, 0.0))
	_cast(discs, orbiting["position"])
	_step(discs, 2.0)
	if _effects(discs, "disco_de_retorno").is_empty() or float(orbiting["health"]) >= 1.0e9:
		return _fail("Twin discs must orbit the character and cut enemies")

	print("REVOLUTION_UNIQUES_OK: 29 rewritten unique weapons change their gem rules")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
