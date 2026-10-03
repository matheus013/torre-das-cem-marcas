extends SceneTree

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const REINFORCEMENT_SECONDS := 40.0


func _init() -> void:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", 4242)
	for peer_id in [1, 2, 3, 4]:
		if not bool(sim.call("add_player", peer_id)):
			_fail("Player %d could not join" % peer_id)
			return
	if bool(sim.call("add_player", 5)):
		_fail("A fifth player must be rejected")
		return
	var characters := {}
	for peer_id: int in (sim.get("players") as Dictionary):
		characters[String((sim.call("player", peer_id) as Dictionary)["character_id"])] = true
	if characters.size() != 4:
		_fail("Players must receive four distinct characters")
		return
	if bool(sim.call("select_character", 2, &"eloa")):
		_fail("A character already in the session must not be duplicated")
		return

	# Gemas e suportes em área segura.
	if not bool(sim.call("set_gem_slot", 1, 3, "elo_residual")):
		_fail("Gem slot could not be changed in Aresta")
		return
	if not bool(sim.call("attach_support", 1, 0, "projeteis_gemeos")):
		_fail("Compatible support was rejected")
		return
	if bool(sim.call("attach_support", 1, 0, "perfuracao_refeita")):
		_fail("Support capacity must block a second support beyond 2 + level")
		return
	if bool(sim.call("attach_support", 1, 0, "area_expandida")):
		_fail("Support without required tags must be rejected")
		return
	var resolved: Dictionary = sim.call("resolve_slot", 1, 0)
	if int(resolved.get("projectile_count", 0)) != 1 or not is_equal_approx(float(resolved["power"]), 35.0 * 0.78):
		_fail("Support modifiers were not resolved into the gem")
		return
	if not bool(sim.call("choose_gem_evolution", 1, "agulha_lastro", "ponta_pesada")):
		_fail("Level one evolution could not be chosen")
		return
	resolved = sim.call("resolve_slot", 1, 0)
	if not is_equal_approx(float(resolved["power"]), 35.0 * 1.35 * 0.78):
		_fail("Evolution and support must compose in canonical order")
		return

	# Combate cooperativo na Torre.
	for peer_id in [1, 2, 3, 4]:
		sim.call("enter_tower", peer_id)
	if bool(sim.call("set_gem_slot", 1, 0, "pulso_cicatriz")) or bool(sim.call("attach_support", 2, 0, "projeteis_gemeos")):
		_fail("Gems and supports must stay locked inside the Tower")
		return
	var enemies := sim.get("enemies") as Array
	var before := enemies.size()
	var first_enemy := (enemies[0] as Dictionary)["position"] as Vector2
	var shooter := sim.call("player", 1) as Dictionary
	shooter["position"] = first_enemy + Vector2(-120.0, 0.0)
	if not bool(sim.call("use_skill", 1, 0, first_enemy)):
		_fail("Projectile gem could not be cast")
		return
	sim.call("damage_enemies", 1, first_enemy, 40.0, 500.0)
	if (sim.get("enemies") as Array).size() >= before:
		_fail("Enemy was not defeated")
		return
	var builds := sim.get("character_experience") as Dictionary
	for key: String in characters:
		if int(builds.get(key, 0)) <= 0 and int((sim.call("character_build", _peer_for(sim, key)) as CharacterBuild).level) <= 1:
			_fail("Every character in the arena must receive full experience (%s)" % key)
			return
	var floor_items := sim.get("ground_items") as Array
	if floor_items.is_empty():
		_fail("Defeated enemies must drop loot on the ground")
		return
	var collector := sim.call("player", 2) as Dictionary
	for item: Dictionary in floor_items.duplicate():
		collector["position"] = item["position"]
		sim.call("_collect_ground_items", 2)
	if not (sim.get("ground_items") as Array).is_empty() or (collector["carried_loot"] as Dictionary).is_empty():
		_fail("Any player walking over the loot must collect it")
		return

	# Modificadores: repetição agendada, lentidão e corrente com cura.
	var nova := {"mechanic": "nova", "radius": 2000.0, "power": 1.0, "repeat_count": 1, "repeat_delay": 0.2, "slow": 0.5, "duration": 2.0}
	sim.call("execute_gem_effect", 2, nova, Vector2.ZERO)
	sim.call("drain_events")
	for _frame in range(20):
		sim.call("step", 1.0 / 60.0)
	var repeated := false
	for event: Dictionary in sim.call("drain_events"):
		if event.get("call", "") == "ring":
			repeated = true
	if not repeated:
		_fail("Echo repeat was not scheduled")
		return
	var slowed := false
	for enemy: Dictionary in sim.get("enemies"):
		if float(enemy.get("slow_timer", 0.0)) > 0.0:
			slowed = true
	if not slowed:
		_fail("Slow modifier did not reach enemies")
		return
	var healer := sim.call("player", 3) as Dictionary
	healer["health"] = 10.0
	sim.call("execute_gem_effect", 3, {"mechanic": "chain", "power": 1.0, "range": 4000.0, "chain_range": 4000.0, "chain_count": 2, "heal_per_chain": 5.0}, Vector2.ZERO)
	if float(healer["health"]) <= 10.0:
		_fail("Chain heal_per_chain did not heal the caster")
		return

	# Raiz Estável: santuário com estabilidade reduz o dano recebido por aliados dentro dele.
	var guarded := sim.call("player", 2) as Dictionary
	guarded["health"] = 100.0
	guarded["invulnerable"] = 0.0
	guarded["barrier"] = 0.0
	sim.call("execute_gem_effect", 2, {"mechanic": "sanctuary", "radius": 120.0, "duration": 5.0, "power": 0.0, "healing": 0.0, "stability": 0.25}, guarded["position"])
	sim.call("take_damage", 2, 20.0)
	if not is_equal_approx(float(guarded["health"]), 85.0):
		_fail("Sanctuary stability must reduce damage taken inside it (health %s)" % guarded["health"])
		return

	# Nível de gema bloqueado pela escolha pendente do nível atual.
	var gems := ((sim.get("character_gems") as Dictionary)[String((sim.call("player", 1) as Dictionary)["character_id"])] as Dictionary)["gems"] as Dictionary
	var needle := gems["agulha_lastro"] as Dictionary
	needle["experience"] = 500
	sim.call("_advance_gem", 1, "agulha_lastro")
	if int(needle["level"]) != 2:
		_fail("Gem must level once and stop at the next pending choice")
		return

	# Segunda Rota: carga extra permite dois usos seguidos e recarrega uma por vez.
	var dasher := sim.call("player", 3) as Dictionary
	var dasher_gems := (sim.get("character_gems") as Dictionary)[String(dasher["character_id"])] as Dictionary
	var dash_progress := (dasher_gems["gems"] as Dictionary)["passo_vetorial"] as Dictionary
	dash_progress["level"] = 3
	dash_progress["choices"] = {"1": "passo_economico", "2": "guarda_de_chegada", "3": "segunda_rota"}
	sim.call("refresh_charges", 3)
	dasher["breath"] = 100.0
	var dash_target := (dasher["position"] as Vector2) + Vector2(60.0, 0.0)
	if not bool(sim.call("use_skill", 3, 1, dash_target)) or not bool(sim.call("use_skill", 3, 1, dash_target)):
		_fail("Extra charge must allow two consecutive dashes")
		return
	if bool(sim.call("use_skill", 3, 1, dash_target)):
		_fail("A third dash must wait for the recharge")
		return
	for _frame in range(int(3.2 * 60.0)):
		sim.call("step", 1.0 / 60.0)
	if int((dasher["charges"] as Array[int])[1]) != 1:
		_fail("Recharge must restore exactly one charge at a time")
		return

	# Salvamento preserva gemas.
	var save: Dictionary = JSON.parse_string(JSON.stringify(sim.call("save_data", 1)))
	var restored: RefCounted = SimulationScript.new()
	restored.call("setup", 1)
	restored.call("add_player", 1)
	if not bool(restored.call("load_data", save, 1)):
		_fail("Save could not be loaded")
		return
	var restored_skills: Array = (restored.call("menu_model", 1) as Dictionary)["skills"]
	if String((restored_skills[3] as Dictionary)["id"]) != "elo_residual" or (restored_skills[0] as Dictionary)["supports"].is_empty() or int((restored_skills[0] as Dictionary)["level"]) != 2:
		_fail("Gem slots, supports and levels were not restored")
		return

	# Escalonamento cooperativo (documento 58): orçamento, Vida de elite e chefe, recompensa.
	var scaled: RefCounted = SimulationScript.new()
	scaled.call("setup", 31)
	scaled.call("add_player", 1)
	scaled.call("enter_tower", 1)
	var elite_definition := {"id": "teste_elite", "name": "Elite", "encounter_class": "elite", "health": 100.0, "rank_id": "maduro", "allow_affixes": false}
	var boss_definition := {"id": "teste_chefe", "name": "Chefe", "encounter_class": "boss", "health": 1000000.0, "rank_id": "apice", "allow_affixes": false}
	var scaled_enemies := scaled.get("enemies") as Array
	scaled_enemies.append(scaled.call("create_enemy", elite_definition, Vector2(900.0, 300.0), 1))
	scaled_enemies.append(scaled.call("create_enemy", boss_definition, Vector2(1000.0, 300.0), 2))
	var elite := scaled_enemies[scaled_enemies.size() - 2] as Dictionary
	var boss := scaled_enemies[scaled_enemies.size() - 1] as Dictionary
	var common := scaled_enemies[0] as Dictionary
	var common_health := float(common["max_health"])
	var elite_solo := float(elite["max_health"])
	var boss_solo := float(boss["max_health"])
	scaled.call("step", 0.01)
	if not is_equal_approx(float(elite["max_health"]), elite_solo) or not is_equal_approx(float(scaled.call("reward_share")), 1.0):
		_fail("Solo must keep reference health and full rewards")
		return
	for peer_id in [2, 3, 4]:
		scaled.call("add_player", peer_id)
		scaled.call("enter_tower", peer_id)
	boss["health"] = boss_solo * 0.5
	scaled.call("step", 0.01)
	if int(scaled.call("party_size")) != 4:
		_fail("Party size must count connected players in the arena")
		return
	if not is_equal_approx(float(elite["max_health"]), elite_solo * 1.2) or not is_equal_approx(float(boss["max_health"]), boss_solo * 2.5):
		_fail("Elite and boss health must follow the four-player table (elite %s, boss %s)" % [elite["max_health"], boss["max_health"]])
		return
	if not is_equal_approx(float(boss["health"]), boss_solo * 2.5 * 0.5) or not is_equal_approx(float(common["max_health"]), common_health):
		_fail("Scaling must keep the health fraction and leave common enemies untouched")
		return
	if not is_equal_approx(float(scaled.call("reward_share")), (1.0 + 0.8 * 1.8) / 2.8):
		_fail("Rewards must grow 80% of the budget growth")
		return
	if int((scaled.get("threat") as RefCounted).get("normal_kills_per_boss")) != 70:
		_fail("Boss cadence must follow the encounter budget, not the raw kill count")
		return
	var floor_population := int((scaled.get("floor_run") as Dictionary).get("population", 0))
	if int((scaled.get("respawn") as RefCounted).get("maximum_alive")) != int(ceil(float(floor_population) * 2.8)):
		_fail("Respawn capacity must follow the encounter budget")
		return
	var fighters := 0
	for _frame in range(int(REINFORCEMENT_SECONDS * 10.0)):
		scaled.call("step", 0.1)
		var population := int((scaled.get("respawn") as RefCounted).call("pending_count"))
		for enemy: Dictionary in scaled.get("enemies"):
			if String(enemy.get("encounter_class", "")) in ["common", "elite"]:
				population += 1
		fighters = maxi(fighters, population)
	if fighters < 11:
		_fail("Four players must face the full budget as reinforcements (got %d)" % fighters)
		return
	scaled.call("disconnect_player", 4)
	scaled.call("remove_player", 3)
	scaled.call("remove_player", 2)
	scaled.call("step", 0.01)
	if not is_equal_approx(float(boss["max_health"]), boss_solo) or float(boss["health"]) > boss_solo:
		_fail("Health must scale back when the party shrinks")
		return

	# Reserva de reconexão: personagem fica parada, protegida e volta ao mesmo perfil.
	var reserve: RefCounted = SimulationScript.new()
	reserve.call("setup", 9)
	reserve.call("add_player", 1)
	reserve.call("add_player", 7, &"sena", "perfil-sena")
	reserve.call("enter_tower", 7)
	var reserved := reserve.call("player", 7) as Dictionary
	reserved["carried_stone"] = 2
	reserve.call("disconnect_player", 7)
	var health_before := float(reserved["health"])
	reserve.call("take_damage", 7, 50.0)
	if float(reserved["health"]) != health_before or bool(reserve.call("is_connected_player", 7)):
		_fail("Reserved character must be protected and marked as disconnected")
		return
	if bool(reserve.call("add_player", 8, &"sena")) and String((reserve.call("player", 8) as Dictionary)["character_id"]) == "sena":
		_fail("A reserved character must stay unavailable to newcomers")
		return
	reserve.call("remove_player", 8)
	if not bool(reserve.call("reconnect_player", "perfil-sena", 9)) or (reserve.get("players") as Dictionary).has(7):
		_fail("Reconnection must move the reserved character to the new peer")
		return
	var returned := reserve.call("player", 9) as Dictionary
	if returned["character_id"] != &"sena" or int(returned["carried_stone"]) != 2 or returned["zone"] != &"tower":
		_fail("Reconnection must keep character, carried load and location")
		return
	reserve.call("disconnect_player", 9)
	for _frame in range(int((SimulationScript.RECONNECT_GRACE + 1.0) * 10.0)):
		reserve.call("step", 0.1)
	if (reserve.get("players") as Dictionary).has(9) or bool(reserve.call("is_character_taken", &"sena")):
		_fail("Expired reservation must remove the player and free the character")
		return

	sim.call("remove_player", 4)
	if (sim.get("players") as Dictionary).size() != 3 or bool(sim.call("is_character_taken", &"rui")):
		_fail("Removing a player must free the character")
		return
	print("WORLD_SIMULATION_OK: four players, gem loadouts, supports, evolutions, modifiers, charges, stability, reconnection, shared EXP and saves")
	quit(0)


func _peer_for(sim: RefCounted, character_key: String) -> int:
	for peer_id: int in (sim.get("players") as Dictionary):
		if String((sim.call("player", peer_id) as Dictionary)["character_id"]) == character_key:
			return peer_id
	return 1


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
