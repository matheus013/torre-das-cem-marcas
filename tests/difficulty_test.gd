extends SceneTree

## Épico E1, fase 2a (G8.5; decisões 597 e 600): cinco dificuldades do mundo. O host escolhe fora da
## Torre entre as liberadas; concluir o andar 100 libera a seguinte. Cada uma escala Vida, dano e
## resistências dos inimigos, tira das resistências da personagem, melhora saque e EXP e libera armas
## únicas a partir da 2. Na 4 e na 5 não há Nascentes, elites e chefes se adaptam e surgem bandos
## superiores com afixos. Andar mais fundo, entrada e recordes são guardados por dificuldade.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const MenuScript := preload("res://src/prototype/village/player_menu.gd")


func _init() -> void:
	_run.call_deferred()


func _world() -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5873)
	sim.add_player(1, &"cira")
	return sim


func _floor_enemy(sim: WorldSimulation) -> Dictionary:
	var definition := sim.content("enemies").filter(func(item: Dictionary) -> bool: return String(item.get("encounter_class", "")) == "common")[0] as Dictionary
	return sim._spawn_floor_enemy(definition, Vector2(400.0, 400.0), 1)


func _run() -> void:
	var sim := _world()
	if sim.difficulty != 1 or sim.set_difficulty(1, 2):
		return _fail("Worlds start at difficulty 1 and cannot pick a locked one")

	# Concluir o andar 100 libera a 2.
	sim.enter_tower(1)
	sim.start_floor(100)
	var boss: Dictionary = sim.enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("floor_boss", false)))[0]
	sim._register_floor_kill(boss)
	if sim.unlocked_difficulty != 2:
		return _fail("Beating floor 100 must unlock difficulty 2")
	if sim.set_difficulty(1, 2):
		return _fail("Difficulty can only change outside the Tower")
	sim.leave_tower(1)

	# Escala: Vida, dano e resistências dos inimigos; penalidade nas resistências da personagem.
	sim.start_floor(5)
	var base_enemy := _floor_enemy(sim)
	sim.unlocked_difficulty = 5
	sim.deepest_floor = 30
	if not sim.set_difficulty(1, 3):
		return _fail("An unlocked difficulty must be selectable in the village")
	if sim.deepest_floor != 1:
		return _fail("A new difficulty starts its own progress at floor 1")
	sim.start_floor(5)
	var hard_enemy := _floor_enemy(sim)
	if not is_equal_approx(float(hard_enemy["max_health"]) / float(base_enemy["max_health"]), 1000.0) or not is_equal_approx(float(hard_enemy["damage"]) / float(base_enemy["damage"]), 4.0):
		return _fail("Difficulty 3 must multiply health by 1000 and damage by 4")
	for kind: String in hard_enemy["resistances"]:
		if not is_equal_approx(float(hard_enemy["resistances"][kind]), clampf(float((base_enemy["resistances"] as Dictionary).get(kind, 0.0)) + 0.2, -0.5, 0.75)):
			return _fail("Difficulty 3 must add 20%% to every enemy resistance (%s)" % kind)
	if not is_equal_approx(sim.difficulty_resistance_penalty(), 0.2):
		return _fail("Difficulty 3 must cut player resistances by 20%")

	# Progresso por dificuldade: a 3 começa do andar 1; voltar à 1 recupera o andar 30.
	if not sim.set_difficulty(1, 1) or sim.deepest_floor != 30:
		return _fail("Deepest floor must be kept per difficulty")

	# Armas únicas só a partir da 2; EXP maior.
	for level in [1, 2]:
		var loot := _world()
		loot.unlocked_difficulty = 5
		loot.set_difficulty(1, level)
		loot.set_gem_slot(1, 0, "pulso_cicatriz")
		loot.enter_tower(1)
		var uniques := 0
		for attempt in range(300):
			loot.ground_items.clear()
			loot._grant_loot(1, {"encounter_class": "boss", "rank_id": "apice", "position": Vector2(300.0, 300.0)})
			uniques += loot.ground_items.filter(func(item: Dictionary) -> bool: return String(item["item_id"]).begins_with("unica_")).size()
		if (level == 1 and uniques > 0) or (level == 2 and uniques == 0):
			return _fail("Unique weapons must drop only from difficulty 2 (difficulty %d gave %d)" % [level, uniques])
	var veteran := _world()
	veteran.unlocked_difficulty = 2
	veteran.set_difficulty(1, 2)
	var key := "cira"
	var before := int(veteran.character_experience.get(key, 0))
	veteran._grant_experience(1, {"encounter_class": "common"})
	if int(veteran.character_experience.get(key, 0)) - before != 18:
		return _fail("Difficulty 2 must give 1.5x experience")

	# Dificuldade 4: sem Nascentes, elites adaptam e há bandos superiores com aura e afixos.
	var mythic := _world()
	mythic.unlocked_difficulty = 5
	mythic.set_difficulty(1, 4)
	var nascent := mythic.create_enemy({"id": "teste", "rank_id": "nascente", "race_id": "juntideo", "health": 50.0}, Vector2.ZERO, 0)
	var elite := mythic.create_enemy({"id": "teste_elite", "rank_id": "evoluido", "race_id": "juntideo", "health": 50.0, "encounter_class": "elite"}, Vector2.ZERO, 1)
	if String(nascent["rank_id"]) != "maduro" or not bool(elite["adaptive"]) or bool(nascent["adaptive"]):
		return _fail("Difficulty 4 must lift Nascent ranks and make elites adaptive")
	mythic.enter_tower(1)
	var superior_count := 0
	for floor_number in [5, 6, 9, 12]:
		mythic.start_floor(floor_number)
		for enemy in mythic.enemies:
			if bool(enemy.get("superior", false)):
				superior_count += 1
				if String(enemy.get("prefix_id", "")).is_empty() and String(enemy.get("suffix_id", "")).is_empty():
					return _fail("Superior pack members must carry affixes")
	if superior_count == 0:
		return _fail("Difficulty 4 must spawn superior packs")
	var snapshot_enemy: Dictionary = (mythic.view_snapshot()["enemies"] as Array).filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("superior", false)))[0] if superior_count > 0 else {}
	if snapshot_enemy.is_empty():
		return _fail("The snapshot must flag superior enemies for the aura")

	# Recordes por dificuldade e save.
	var records := _world()
	records.unlocked_difficulty = 3
	records.set_difficulty(1, 2)
	records.enter_tower(1)
	records.start_floor(4)
	records.floor_run["time"] = 42.0
	records.floor_run["boss_fight"] = true
	records._finish_floor_run()
	if not records.records.has("d2:4") or records.records.has("4") or not records.difficulty_records().has("4"):
		return _fail("Records must be stored per difficulty: %s" % [records.records.keys()])
	var restored := _world()
	if not restored.load_data(records.save_data(1), 1) or restored.difficulty != 2 or restored.unlocked_difficulty != 3:
		return _fail("Difficulty and unlocks must survive save and load")

	# Menu: seletor com as 5, as bloqueadas desabilitadas.
	var menu := MenuScript.new()
	root.add_child(menu)
	menu.call("refresh", records.menu_model(1))
	menu.call("open", "tower")
	await process_frame
	var picker := menu.find_child("DifficultyPicker", true, false)
	if picker == null or picker.get_child_count() != 5 or not (picker.get_child(4) as Button).disabled or (picker.get_child(1) as Button).text.find("VETERANA") < 0:
		return _fail("The tower tab must offer the 5 difficulties with locked ones disabled")
	menu.queue_free()
	await process_frame
	print("DIFFICULTY_OK: unlock at floor 100, village-only switch, scaling, penalty, per-difficulty progress and records, uniques from 2, EXP, no Nascent, adaptive elites, superior packs, save and picker")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
