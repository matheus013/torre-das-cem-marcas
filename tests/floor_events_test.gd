extends SceneTree

## Épico E1, fase 4 (G8.6 e G8.7; decisão 606): sete afixos de comportamento de elite no terceiro
## espaço (só da dificuldade 2 em diante), mutadores de andar (1 normal na 3, 2 na 4, 2 + 1 cruel na
## 5) com bônus de saque, e marés com aviso, objetivo, recompensa, campeão na 5 e a Lua da Cicatriz.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const FloorRules := preload("res://src/gameplay/world/floor_rules.gd")


func _init() -> void:
	_run.call_deferred()


func _world(level: int = 1, floor_number: int = 5) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(6061)
	sim.add_player(1, &"sena")
	sim.unlocked_difficulty = 5
	sim.set_difficulty(1, level)
	sim.clock.call("set_period", "tarde")
	sim.enter_tower(1)
	sim.start_floor(floor_number)
	sim.enemies.clear()
	(sim.floor_run["tide"] as Dictionary).clear()
	sim.floor_run["mutators"] = []
	sim.player(1)["position"] = Vector2(900.0, 900.0)
	return sim


func _definition(sim: WorldSimulation, encounter_class: String) -> Dictionary:
	return sim.content("enemies").filter(func(item: Dictionary) -> bool: return String(item.get("encounter_class", "")) == encounter_class and String(item.get("time_of_day", "")).is_empty() and String(item.get("biome", "galerias")) == "galerias")[0] as Dictionary


func _enemy(sim: WorldSimulation, behavior: String, offset: Vector2) -> Dictionary:
	var enemy := sim.create_enemy(_definition(sim, "common"), (sim.player(1)["position"] as Vector2) + offset, 7)
	enemy["shield_hits"] = 0
	enemy["max_health"] = 1000.0
	enemy["health"] = 1000.0
	enemy["resistances"] = {}
	enemy["modifier_mechanics"] = []
	if not behavior.is_empty():
		sim.apply_behavior(enemy, behavior)
		enemy["max_health"] = 1000.0
		enemy["health"] = 1000.0
	sim.enemies.append(enemy)
	return enemy


func _hit(kind: String) -> Dictionary:
	return {"element": kind, "crit_add": -1.0}


func _run() -> void:
	# Afixos de comportamento: nunca na 1; sempre em elites da 4.
	for level in [1, 4]:
		var sim := _world(level)
		var behaviors := 0
		for index in range(20):
			if not String(sim.create_enemy(_definition(sim, "elite"), Vector2(500.0, 500.0), index).get("behavior_id", "")).is_empty():
				behaviors += 1
		if (level == 1 and behaviors > 0) or (level == 4 and behaviors != 20):
			return _fail("Behavior affixes: none at difficulty 1, always on difficulty 4 elites (%d got %d)" % [level, behaviors])

	# Absorvente: imune por 3 s ao último tipo que o feriu.
	var absorb := _world(2)
	var sponge := _enemy(absorb, "absorvente", Vector2(80.0, 0.0))
	absorb.damage_enemy(1, 0, 100.0, _hit("fire"))
	var after_first := float(sponge["health"])
	absorb.damage_enemy(1, 0, 100.0, _hit("fire"))
	if not is_equal_approx(float(sponge["health"]), after_first):
		return _fail("Absorbing elites must ignore the same type for 3 s")
	absorb.damage_enemy(1, 0, 100.0, _hit("ice"))
	if float(sponge["health"]) >= after_first:
		return _fail("Absorbing elites still take other types")

	# Escudeiro: aliados perto recebem 30% menos; Vinculado divide metade com o vizinho.
	var squad := _world(2)
	var guarded := _enemy(squad, "", Vector2(80.0, 0.0))
	_enemy(squad, "escudeiro", Vector2(120.0, 0.0))
	squad.damage_enemy(1, 0, 100.0, _hit("physical"))
	if not is_equal_approx(1000.0 - float(guarded["health"]), 70.0):
		return _fail("Squires must cut allies' damage by 30%%: %s" % (1000.0 - float(guarded["health"])))
	var linked_world := _world(2)
	var linked := _enemy(linked_world, "vinculado", Vector2(80.0, 0.0))
	var neighbor := _enemy(linked_world, "", Vector2(140.0, 0.0))
	linked_world.damage_enemy(1, 0, 100.0, _hit("physical"))
	if not is_equal_approx(1000.0 - float(linked["health"]), 50.0) or not is_equal_approx(1000.0 - float(neighbor["health"]), 50.0):
		return _fail("Linked elites must share half the damage")

	# Refletor: devolve 20% do tipo dele, até 10% da Vida de quem bate.
	var mirror := _world(2)
	var reflector := _enemy(mirror, "refletor", Vector2(80.0, 0.0))
	var reflect_type := String(reflector["reflect_type"])
	var health := float(mirror.player(1)["health"])
	mirror.damage_enemy(1, 0, 100000.0, _hit(reflect_type))
	var lost := health - float(mirror.player(1)["health"])
	if lost <= 0.0 or lost > mirror.max_health(1) * FloorRules.REFLECT_CAP + 0.01:
		return _fail("Reflectors must return capped damage: %s" % lost)

	# Profanador corta a cura pela metade; Fome tira 40%.
	var holy := _world(2)
	holy.player(1)["health"] = 10.0
	_enemy(holy, "profanador", Vector2(80.0, 0.0))
	holy.heal_player(1, 20.0)
	if not is_equal_approx(float(holy.player(1)["health"]), 20.0):
		return _fail("Desecrators must halve healing nearby: %s" % holy.player(1)["health"])
	var hungry := _world(3)
	hungry.floor_run["mutators"] = ["fome"]
	hungry.player(1)["health"] = 10.0
	hungry.heal_player(1, 20.0)
	if not is_equal_approx(float(hungry.player(1)["health"]), 22.0):
		return _fail("Hunger must cut healing by 40%")

	# Caçador persegue a marcada mesmo com outra personagem mais perto.
	var hunt := _world(2)
	hunt.add_player(2, &"cira")
	hunt.enter_tower(2)
	hunt.player(2)["position"] = Vector2(1500.0, 900.0)
	var stalker := _enemy(hunt, "cacador", Vector2(500.0, 0.0))
	stalker["hunt_peer"] = 2
	stalker["position"] = Vector2(1300.0, 900.0)
	var start := stalker["position"] as Vector2
	hunt.player(1)["position"] = Vector2(1250.0, 900.0)
	hunt._update_enemies(0.2)
	if (stalker["position"] as Vector2).x <= start.x:
		return _fail("Hunters must chase the marked player")

	# Fissurador deixa fendas.
	var cracks := _world(2)
	var fissurer := _enemy(cracks, "fissurador", Vector2(200.0, 0.0))
	fissurer["fissure_timer"] = 0.0
	cracks._update_enemies(0.1)
	if not cracks.telegraphs.any(func(entry: Dictionary) -> bool: return String(entry.get("source", "")) == "fissure"):
		return _fail("Fissurers must leave delayed fissures")

	# Mutadores: nenhum até a 2; 1 na 3; 2 + 1 cruel na 5; reproduzíveis; bônus de saque.
	if not FloorRules.roll_mutators(5, 2, 10).is_empty() or FloorRules.roll_mutators(5, 3, 10).size() != 1:
		return _fail("Difficulty 3 floors get exactly one normal mutator")
	var cruel := FloorRules.roll_mutators(5, 5, 10)
	if cruel.size() != 3 or not bool(FloorRules.MUTATORS[cruel[2]]["cruel"]) or cruel != FloorRules.roll_mutators(5, 5, 10):
		return _fail("Difficulty 5 floors get two normal and one mandatory cruel mutator, reproducibly: %s" % [cruel])
	if not is_equal_approx(FloorRules.mutator_loot(cruel), 1.0 + 2.0 * FloorRules.NORMAL_LOOT + FloorRules.CRUEL_LOOT):
		return _fail("Mutators must raise loot")
	var real := _world(5)
	real.start_floor(9)
	if (real.floor_run["mutators"] as Array).size() != 3 or (real.view_snapshot()["floor"]["mutators"] as Array).size() != 3:
		return _fail("Floors must carry and show their mutators")
	var mutated := _world(3)
	var plain_enemy := mutated._spawn_floor_enemy(_definition(mutated, "common"), Vector2(400.0, 400.0), 1)
	mutated.floor_run["mutators"] = ["pressa", "blindagem"]
	var fast := mutated._spawn_floor_enemy(_definition(mutated, "common"), Vector2(400.0, 400.0), 1)
	if not is_equal_approx(float(fast["speed"]) / float(plain_enemy["speed"]), FloorRules.HASTE_SPEED) or not is_equal_approx(float(fast["resistances"].get("physical", 0.0)) - float(plain_enemy["resistances"].get("physical", 0.0)), FloorRules.PLATING_RESIST):
		return _fail("Haste and Plating must change spawned enemies")
	# Dívida: sem regeneração; abate devolve 15%.
	var debt := _world(5)
	debt.floor_run["mutators"] = ["divida"]
	debt.player(1)["breath"] = 10.0
	debt._step_player(1, 1.0)
	if not is_equal_approx(float(debt.player(1)["breath"]), 10.0):
		return _fail("Debt must stop breath regeneration")
	_enemy(debt, "", Vector2(60.0, 0.0))["health"] = 1.0
	debt.damage_enemy(1, 0, 50.0, _hit("physical"))
	if not is_equal_approx(float(debt.player(1)["breath"]), 10.0 + debt.max_breath(1) * FloorRules.DEBT_REFUND):
		return _fail("Debt must refund breath on kills")
	# Cicatriz dobra o peso das quedas; Sem Retorno sela o portal até a escada.
	var scarred := _world(5)
	var full := scarred.max_health(1)
	scarred.player(1)["wounds"] = 1
	scarred.floor_run["mutators"] = ["cicatriz"]
	if not is_equal_approx(scarred.max_health(1), full * (1.0 - scarred.WOUND_PENALTY * 2.0)):
		return _fail("Scar must double the wound penalty")
	scarred.floor_run["mutators"] = ["sem_retorno"]
	scarred.player(1)["position"] = (scarred.floor_layout["return_portal"] as Rect2).get_center()
	scarred.player(1)["transition_cooldown"] = 0.0
	scarred._check_transition(1)
	if scarred.player(1)["zone"] != &"tower":
		return _fail("No Return must seal the portal until the stairs open")
	# Escuridão: escuro de dia, luz pela metade.
	var dark := _world(3)
	dark.floor_run["mutators"] = ["escuridao"]
	dark._light_radii.clear()
	if not dark.is_dark() or not is_equal_approx(dark.light_radius(1), dark.LIGHT_RADIUS * FloorRules.DARKNESS_LIGHT):
		return _fail("Darkness must darken the floor by day and halve the light")
	# Enxertia: o morto volta uma vez com metade da Vida.
	var graft := _world(3)
	graft.floor_run["mutators"] = ["enxertia"]
	_enemy(graft, "", Vector2(60.0, 0.0))["health"] = 1.0
	graft.damage_enemy(1, 0, 50.0, _hit("physical"))
	if graft.enemies.size() != 1 or not bool(graft.enemies[0].get("grafted", false)) or not is_equal_approx(float(graft.enemies[0]["health"]), 500.0):
		return _fail("Grafting must bring the dead back once at half health")
	graft.damage_enemy(1, 0, 5000.0, _hit("physical"))
	if not graft.enemies.is_empty():
		return _fail("Grafted enemies come back only once")
	# Tempestade: raios anunciados sobre o grupo.
	var storm := _world(3)
	storm.floor_run["mutators"] = ["tempestade"]
	storm._step_storm(FloorRules.STORM_INTERVAL + 0.1)
	if not storm.telegraphs.any(func(entry: Dictionary) -> bool: return String(entry.get("source", "")) == "storm"):
		return _fail("Storm must call lightning on the party")

	# Marés: sorteio reproduzível; a Lua da Cicatriz encadeia todas.
	if FloorRules.roll_tide(7, 2, 12, false, false) != FloorRules.roll_tide(7, 2, 12, false, false):
		return _fail("Tides must be reproducible")
	if (FloorRules.roll_tide(7, 1, 12, true, true)["queue"] as Array) != FloorRules.SCAR_MOON_SEQUENCE:
		return _fail("The Scar Moon must chain every tide")
	# Enxame: aviso de 5 s, ondas, objetivo e recompensa.
	var swarm := _force_tide(_world(1), "enxame")
	swarm._step_tide(0.1)
	if String(swarm.tide_view()["state"]) != "warning" or not swarm.telegraphs.any(func(entry: Dictionary) -> bool: return String(entry.get("source", "")) == "tide"):
		return _fail("Tides must warn 5 s ahead on the ground and the HUD")
	swarm._step_tide(FloorRules.WARNING_SECONDS)
	swarm._step_tide(0.1)
	if not swarm.tide_active("enxame") or swarm.enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("tide", false))).size() != 12:
		return _fail("The swarm must start with its first wave")
	for wave in range(3):
		_kill_tide(swarm)
		swarm._step_tide(6.1)
	_kill_tide(swarm)
	swarm._step_tide(0.1)
	var rewards := swarm.ground_items.filter(func(item: Dictionary) -> bool: return swarm._is_equipment(String(item["item_id"])))
	if swarm.tide_active() or rewards.size() < 3:
		return _fail("Clearing the swarm must drop the Swarm Chest (%d items)" % rewards.size())
	# Procissão: o carregador foge e a maré falha; derrubado, rende peça do maior tier.
	var escape := _force_tide(_world(1), "procissao")
	escape._step_tide(0.1)
	escape._step_tide(FloorRules.WARNING_SECONDS + 0.1)
	var carrier := escape._enemy_by_uid(int(escape.floor_run["tide"]["carrier_uid"]))
	carrier["position"] = carrier["carrier_exit"]
	escape._update_enemies(0.1)
	escape._step_tide(0.1)
	if escape.tide_active() or escape.ground_items.size() > 0:
		return _fail("An escaped carrier must fail the procession")
	var caught := _force_tide(_world(3), "procissao")
	caught._step_tide(0.1)
	caught._step_tide(FloorRules.WARNING_SECONDS + 0.1)
	var target := caught._enemy_by_uid(int(caught.floor_run["tide"]["carrier_uid"]))
	target["shield_hits"] = 0
	caught.damage_enemy(1, caught.enemies.find(target), 1.0e12, _hit("physical"))
	caught._step_tide(0.1)
	if not caught.ground_items.any(func(item: Dictionary) -> bool: return String(caught.item_data(String(item["item_id"])).get("tier", "")) == "legendary"):
		return _fail("Catching the carrier on difficulty 3 must drop a legendary piece")
	# Vínculo: o par divide a Vida e morre junto.
	var bond := _force_tide(_world(1), "vinculo")
	bond._step_tide(0.1)
	bond._step_tide(FloorRules.WARNING_SECONDS + 0.1)
	var first := bond.enemies.filter(func(enemy: Dictionary) -> bool: return enemy.has("link_uid"))[0] as Dictionary
	var mate := bond._enemy_by_uid(int(first["link_uid"]))
	first["shield_hits"] = 0
	bond.damage_enemy(1, bond.enemies.find(first), 10.0, _hit("physical"))
	if not is_equal_approx(float(first["health"]), float(mate["health"])):
		return _fail("Bonded pairs must share health")
	var before := bond.enemies.size()
	bond.damage_enemy(1, bond.enemies.find(first), 1.0e12, _hit("physical"))
	if bond.enemies.size() != before - 2:
		return _fail("Killing one of a bonded pair must kill both")
	# Eclipse: escuro total e luz menor.
	var eclipse := _force_tide(_world(1), "eclipse")
	eclipse.clock.call("set_period", "noite")
	eclipse._step_tide(0.1)
	eclipse._step_tide(FloorRules.WARNING_SECONDS + 0.1)
	eclipse._light_radii.clear()
	if not eclipse.tide_active("eclipse") or not bool(eclipse.view_snapshot()["floor"]["eclipse"]) or eclipse.light_radius(1) >= eclipse.LIGHT_RADIUS:
		return _fail("The eclipse must darken everything outside the light")
	# Dificuldade 5: campeão com três afixos em toda maré.
	var champion_world := _force_tide(_world(5), "cerco")
	champion_world._step_tide(0.1)
	champion_world._step_tide(FloorRules.WARNING_SECONDS + 0.1)
	var champions := champion_world.enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("tide_champion", false)))
	if champions.size() != 1 or String(champions[0].get("behavior_id", "")).is_empty() or String(champions[0].get("prefix_id", "")).is_empty() or String(champions[0].get("suffix_id", "")).is_empty():
		return _fail("Difficulty 5 tides must bring a three-affix champion")
	print("FLOOR_EVENTS_OK: seven behavior affixes from difficulty 2, mutators by difficulty with loot, cruel mutators, tides with warning, goals, rewards, Scar Moon chain and difficulty 5 champions")
	quit(0)


func _force_tide(sim: WorldSimulation, tide_id: String) -> WorldSimulation:
	sim.floor_run["tide"] = {"queue": [tide_id], "scar_moon": false, "state": "waiting", "timer": 0.0, "id": "", "goal": 0, "progress": 0, "successes": 0, "center": [0.0, 0.0], "waves": 0, "wave_timer": 0.0}
	return sim


func _kill_tide(sim: WorldSimulation) -> void:
	for index in range(sim.enemies.size() - 1, -1, -1):
		if index < sim.enemies.size() and bool(sim.enemies[index].get("tide", false)) and not bool(sim.enemies[index].get("tide_bonus", false)):
			sim.enemies[index]["shield_hits"] = 0
			sim.damage_enemy(1, index, 1.0e12, _hit("physical"))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
