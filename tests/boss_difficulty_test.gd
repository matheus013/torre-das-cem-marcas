extends SceneTree

## Épico E1, fase 5 (G8.10; decisão 609): chefes por dificuldade. As habilidades anunciadas escalam com
## a dificuldade (antes ficavam no valor base: regressão); na 2 o chefe ganha a habilidade do bioma;
## na 3 uma fase de fúria abaixo de 30%; na 4 a forma ascendida a 50% (arena alterada, golpes
## combinados e curandeiros); na 5 o escudo cronometrado a 60% e 30%. Na 5 também há um Guardião da
## Cicatriz por andar e Pactos opcionais com +25% de saque e EXP cada.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _boss_world(level: int, floor_number: int = 16) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(6091)
	sim.add_player(1, &"cira")
	sim.unlocked_difficulty = 5
	sim.set_difficulty(1, level)
	sim.clock.call("set_period", "tarde")
	sim.enter_tower(1)
	sim.start_floor(floor_number)
	return sim


func _boss(sim: WorldSimulation) -> Dictionary:
	return sim.enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("floor_boss", false)))[0] as Dictionary


func _run() -> void:
	# Regressão: o dano das habilidades acompanha a dificuldade.
	var easy := _boss(_boss_world(1))
	var hard := _boss(_boss_world(3))
	var easy_hit := float((easy["kit"] as Array)[0]["damage"])
	var hard_hit := float((hard["kit"] as Array)[0]["damage"])
	if not is_equal_approx(hard_hit / easy_hit, 4.0):
		return _fail("Boss ability damage must scale with difficulty: %s -> %s" % [easy_hit, hard_hit])
	# Dificuldade 2: habilidade do bioma; 1 não muda.
	var veteran := _boss(_boss_world(2))
	if (veteran["kit"] as Array).size() != (easy["kit"] as Array).size() + 1 or not bool((veteran["kit"] as Array).back().get("biome_ability", false)):
		return _fail("Difficulty 2 bosses gain their biome ability")
	# Dificuldade 3: fase de fúria abaixo de 30%, com reforços e golpes mais rápidos.
	var master := _boss_world(3)
	var surge := _boss(master)
	if not (surge["phases"] as Array).has(0.3):
		return _fail("Difficulty 3 bosses gain a phase below 30%")
	var before := master.enemies.size()
	surge["health"] = float(surge["max_health"]) * 0.25
	master._update_enemies(0.1)
	if not bool(surge.get("surge", false)) or master.enemies.size() != before + 2:
		return _fail("The 30% phase must speed the boss up and call adds")
	# Dificuldade 4: forma ascendida a 50%.
	var mythic := _boss_world(4)
	var ascended := _boss(mythic)
	ascended["health"] = float(ascended["max_health"]) * 0.45
	mythic._update_enemies(0.1)
	var healers := mythic.enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("boss_healer", false)))
	if not bool(ascended.get("ascended", false)) or mythic.hazard_zones.size() < 3 or healers.size() != 2:
		return _fail("Difficulty 4 bosses must ascend: arena hazards and healers")
	var hurt := float(ascended["health"])
	mythic._update_enemies(1.0)
	if float(ascended["health"]) <= hurt:
		return _fail("Healers must heal the ascended boss")
	# Dificuldade 5: escudo cronometrado; se não cair, a fase recomeça.
	var scar := _boss_world(5)
	var shielded := _boss(scar)
	shielded["health"] = float(shielded["max_health"]) * 0.55
	scar._update_enemies(0.1)
	if float(shielded.get("shield_hp", 0.0)) <= 0.0 or not (scar.view_snapshot()["floor"]["boss_shield"] as float) > 0.0:
		return _fail("Difficulty 5 bosses must raise a timed shield at 60%")
	var index := scar.enemies.find(shielded)
	var health := float(shielded["health"])
	scar.damage_enemy(1, index, float(shielded["shield_hp"]) * 0.5, {"crit_add": -1.0})
	if float(shielded["health"]) != health:
		return _fail("The shield must absorb damage first")
	scar._update_enemies(scar.BOSS_SHIELD_SECONDS + 0.1)
	if float(shielded["health"]) / float(shielded["max_health"]) < 0.74 or float(shielded.get("shield_hp", 0.0)) > 0.0:
		return _fail("An unbroken shield must restart the phase: %s" % (float(shielded["health"]) / float(shielded["max_health"])))
	var broken_world := _boss_world(5)
	var breakable := _boss(broken_world)
	breakable["health"] = float(breakable["max_health"]) * 0.55
	broken_world._update_enemies(0.1)
	broken_world.damage_enemy(1, broken_world.enemies.find(breakable), float(breakable["shield_hp"]) * 3.0, {"crit_add": -1.0})
	if float(breakable.get("shield_hp", 0.0)) > 0.0 or float(breakable.get("vulnerable_timer", 0.0)) <= 0.0:
		return _fail("Breaking the shield in time must expose the boss")

	# Guardião da Cicatriz em todo andar comum da 5, com material raro garantido.
	var guarded := _boss_world(5, 10)
	var guardians := guarded.enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("scar_guardian", false)))
	if guardians.size() != 1 or String(guardians[0].get("behavior_id", "")).is_empty() or String(guardians[0].get("prefix_id", "")).is_empty() or String(guardians[0].get("suffix_id", "")).is_empty():
		return _fail("Difficulty 5 floors must have one three-affix Scar Guardian")
	var lower := _boss_world(4, 10)
	if lower.enemies.any(func(enemy: Dictionary) -> bool: return bool(enemy.get("scar_guardian", false))):
		return _fail("Scar Guardians only on difficulty 5")
	var guardian := guardians[0] as Dictionary
	guardian["shield_hits"] = 0
	guarded.ground_items.clear()
	guarded.damage_enemy(1, guarded.enemies.find(guardian), 1.0e15, {"crit_add": -1.0})
	if not guarded.ground_items.any(func(item: Dictionary) -> bool: return String(item["item_id"]) == "membrana_de_pressao"):
		return _fail("Scar Guardians must drop the biome rare material")

	# Pactos: só na 5, fora da Torre; aplicam a maldição e pagam +25% de saque e EXP cada.
	var pact := Simulation.new()
	pact.setup(6092)
	pact.add_player(1, &"cira")
	pact.unlocked_difficulty = 5
	pact.set_difficulty(1, 4)
	if pact.set_pact(1, "pacto_do_vidro", true):
		return _fail("Pacts only on difficulty 5")
	pact.set_difficulty(1, 5)
	var health_before := pact.max_health(1)
	if not pact.set_pact(1, "pacto_do_vidro", true) or not is_equal_approx(pact.max_health(1), health_before * 0.7):
		return _fail("The Glass Pact must cut max health by 30%")
	pact.set_pact(1, "pacto_da_pressa", true)
	if not is_equal_approx(pact.pact_reward(), 1.5):
		return _fail("Each pact must add 25% loot and EXP")
	var restored := Simulation.new()
	restored.setup(6092)
	restored.add_player(1, &"cira")
	if not restored.load_data(pact.save_data(1), 1) or restored.pacts.size() != 2:
		return _fail("Pacts must survive save and load")
	pact.enter_tower(1)
	if pact.set_pact(1, "pacto_de_sangue", true):
		return _fail("Pacts change only outside the Tower")
	print("BOSS_DIFFICULTY_OK: scaled boss abilities, biome ability, 30% surge, ascended form with healers, timed shield, Scar Guardians and pacts")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
