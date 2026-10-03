extends SceneTree

## Cena de Aresta em modo solo sobre WorldSimulation (ADR 0018): interface, zonas, combate,
## consequência, troca de personagem, gemas pelo menu e ciclo de salvamento.

const PEER := 1


func _init() -> void:
	_run()


func _run() -> void:
	var scene := load("res://src/prototype/village/village_exploration.tscn") as PackedScene
	if scene == null:
		return _fail("Village exploration scene could not be loaded")
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	for path in ["Interface/TopBar/Location", "Interface/CombatHud", "Interface/PlayerMenu", "Interface/CharacterPanel"]:
		if instance.get_node_or_null(path) == null:
			return _fail("Interface node missing: %s" % path)
	var sim: RefCounted = instance.get("_sim")
	if sim == null or (sim.get("players") as Dictionary).size() != 1:
		return _fail("Solo session did not create the authoritative simulation")
	var gear := sim.call("_gear", PEER) as Dictionary
	var equipment := gear["equipment"] as EquipmentLoadout
	var inventory := gear["inventory"] as ItemInventory
	if equipment.equipped_count() != 2 or inventory.items.size() != 2:
		return _fail("Starter equipment was not split between loadout and inventory")
	if not is_equal_approx(float(sim.call("max_health", PEER)), 118.0):
		return _fail("Equipped armor did not affect derived health")

	# Intenções passam pelo mesmo caminho validado usado pela rede.
	instance.call("_send_intent", "equip", ["botas_de_rota_antiga_3"])
	instance.call("_send_intent", "equip", ["anel_de_folego_4"])
	for tab in ["inventory", "character", "skills"]:
		instance.call("_open_player_menu", tab)
		await process_frame
	(instance.get("_player_menu") as Control).call("close")
	if equipment.equipped_count() != 4 or inventory.has(&"anel_de_folego_4"):
		return _fail("Inventory action did not atomically equip starter items")
	instance.call("_send_intent", "unequip", [EquipmentItemDefinition.Slot.RING, 0])
	if not inventory.has(&"anel_de_folego_4"):
		return _fail("Equipped ring could not return to inventory")
	instance.call("_send_intent", "equip", ["anel_de_folego_4"])
	instance.call("_send_intent", "gem_slot", [3, "elo_residual"])
	instance.call("_send_intent", "support_add", [0, "projeteis_gemeos"])
	var skills := (sim.call("menu_model", PEER) as Dictionary)["skills"] as Array
	if String((skills[3] as Dictionary)["id"]) != "elo_residual" or ((skills[0] as Dictionary)["supports"] as Array).size() != 1:
		return _fail("Skills menu intents did not reach the gem loadout")
	instance.call("_send_intent", "skill", [9, Vector2.ZERO])
	instance.call("_send_intent", "character", ["nao_existe"])

	var state := sim.call("player", PEER) as Dictionary
	sim.call("enter_house", PEER)
	if state["zone"] != &"house":
		return _fail("House entrance did not change the active location")
	sim.call("leave_house", PEER)
	if state["zone"] != &"village" or not (state["position"] as Vector2).is_equal_approx(Vector2(850.0, 555.0)):
		return _fail("House exit did not restore the world return point")

	sim.call("enter_tower", PEER)
	await physics_frame
	await physics_frame
	if instance.call("_local_zone") != &"tower":
		return _fail("Tower entrance did not reach the presentation")
	var enemies := sim.get("enemies") as Array
	var layout := sim.get("floor_layout") as Dictionary
	if int(sim.get("current_floor")) != 1 or (layout["size"] as Vector2).x < 3000.0 or enemies.size() < 30:
		return _fail("Floor 1 must be a large explorable map with packs spread across it")
	var nascent := {}
	var evolved := {}
	for enemy: Dictionary in enemies:
		if enemy.get("rank_id", "") == "nascente" and nascent.is_empty():
			nascent = enemy
		if enemy.get("rank_id", "") == "evoluido" and evolved.is_empty():
			evolved = enemy
	if nascent.is_empty() or nascent.get("race_id", "") != "juntideo":
		return _fail("Enemy race and rank were not resolved from the beta catalog")
	if float(nascent.get("speed", 0.0)) <= 62.0 or float(nascent.get("max_health", 0.0)) >= 35.0:
		return _fail("Race and hierarchy did not compose lore-consistent enemy attributes")
	if nascent.get("prefix_id", "") != "" or nascent.get("suffix_id", "") != "":
		return _fail("Nascent enemies must not receive random affixes")
	if not evolved.is_empty() and evolved.get("prefix_id", "") == "" and evolved.get("suffix_id", "") == "":
		return _fail("Evolved enemies must receive at least one random affix")
	var wanderer := enemies[0] as Dictionary
	var start_position := wanderer["position"] as Vector2
	for _frame in range(240):
		sim.call("step", 1.0 / 60.0)
	if (wanderer["position"] as Vector2).is_equal_approx(start_position) and (wanderer.get("wander_target", start_position) as Vector2).is_equal_approx(start_position):
		return _fail("Idle monsters must patrol instead of waiting in place")
	if bool(sim.call("set_gem_slot", PEER, 0, "pulso_cicatriz")):
		return _fail("Gem loadout must be locked inside the Tower")

	sim.call("execute_gem_effect", PEER, {
		"mechanic": "summon", "summon_definition_id": "molde_vigilante", "summon_count": 3,
		"power": 16, "duration": 10.0, "attack_interval": 0.8, "range": 300.0,
	}, Vector2(300.0, 300.0))
	var summons := sim.get("persistent_effects") as Array
	if summons.size() != 2:
		return _fail("Summon execution did not enforce the per-owner definition limit")
	for summon: Dictionary in summons:
		if String(summon.get("instance_id", "")).is_empty() or int(summon.get("owner_peer", 0)) != PEER or summon.get("team_id", "") != "heroes":
			return _fail("Runtime summon is missing identity, ownership or team")
	summons.clear()
	var modified := {
		"display_name": "Raspador", "health": 100.0, "max_health": 100.0,
		"speed": 40.0, "damage": 10.0, "attack_interval": 1.0, "loot_value": 2,
		"prefix_id": "", "suffix_id": "",
	}
	sim.call("apply_enemy_modifier", modified, {
		"id": "robusto", "name": "Robusto", "position": "prefix",
		"health_multiplier": 1.5, "speed_multiplier": 0.8, "damage_multiplier": 1.2,
		"attack_interval_multiplier": 1.0, "loot_multiplier": 2.0,
	})
	if not is_equal_approx(float(modified["max_health"]), 150.0) or int(modified["loot_value"]) != 4 or modified["prefix_id"] != "robusto":
		return _fail("Enemy affix did not apply deterministic stat modifiers")

	state["health"] = 40.0
	instance.call("_send_intent", "quick", [])
	if not is_equal_approx(float(state["health"]), 75.0) or int(state["quick_items"]) != 1:
		return _fail("Quick item did not heal or consume its item")
	var victim := (sim.get("enemies") as Array)[0] as Dictionary
	victim["health"] = 1.0
	sim.call("damage_enemy", PEER, 0, 100.0)
	var dropped := sim.get("ground_items") as Array
	if dropped.is_empty() or int(state["carried_stone"]) != 0:
		return _fail("Defeated enemy must leave its loot on the ground")
	for item: Dictionary in dropped.duplicate():
		state["position"] = item["position"]
		sim.call("_collect_ground_items", PEER)
	if (state["carried_loot"] as Dictionary).is_empty():
		return _fail("Defeated tower enemy did not grant expedition loot")
	state["position"] = (layout["entry"] as Vector2)
	var alive_before := (sim.get("enemies") as Array).size()
	if int((sim.get("respawn") as RefCounted).call("pending_count")) < 1:
		return _fail("Defeated common enemy was not queued for respawn")
	sim.call("tick_respawns", 20.0)
	if (sim.get("enemies") as Array).size() != alive_before + 1:
		return _fail("Tower did not restore a defeated enemy after the respawn interval")
	(sim.get("floor_run") as Dictionary)["time"] = 600.0
	if float(sim.call("respawn_interval")) >= 5.0:
		return _fail("Respawn must speed up the longer the party stays on the floor")

	# Andar de chefe: arena pequena, saida selada, escada e recorde depois da vitoria.
	sim.call("leave_tower", PEER)
	sim.set("deepest_floor", 4)
	if not bool(sim.call("set_start_floor", PEER, 4)):
		return _fail("Reached floors must be selectable as the starting floor")
	sim.call("enter_tower", PEER)
	var arena := sim.get("floor_layout") as Dictionary
	var boss_enemies := sim.get("enemies") as Array
	if not arena.has("arena_radius") or (arena["size"] as Vector2).x > 1600.0 or boss_enemies.size() != 1 or not bool((boss_enemies[0] as Dictionary).get("floor_boss", false)):
		return _fail("Boss floors must be small arenas holding only their guardian")
	state["position"] = (arena["return_portal"] as Rect2).get_center()
	state["transition_cooldown"] = 0.0
	sim.call("_check_transition", PEER)
	if state["zone"] != &"tower":
		return _fail("The arena exit must stay sealed while the boss lives")
	for _frame in range(300):
		state["health"] = 1000.0
		sim.call("step", 1.0 / 60.0)
	if (sim.get("telegraphs") as Array).is_empty() and (sim.get("enemy_projectiles") as Array).is_empty() and (sim.get("hazard_zones") as Array).is_empty():
		var casted := false
		for _frame in range(300):
			state["health"] = 1000.0
			sim.call("step", 1.0 / 60.0)
			casted = casted or not (sim.get("telegraphs") as Array).is_empty()
		if not casted:
			return _fail("Bosses must telegraph area abilities")
	sim.call("damage_enemy", PEER, 0, 1000000.0)
	var eloa := (sim.get("character_builds") as Dictionary)["eloa"] as CharacterBuild
	if eloa.level < 2:
		return _fail("Boss experience did not advance the active character")
	var floor_state := sim.get("floor_run") as Dictionary
	if not bool(floor_state["stairs_open"]) or float(sim.call("best_time", 4, "solo")) <= 0.0:
		return _fail("Boss victory must open the stairs and record the solo time")
	if float((sim.get("boss_cooldowns") as Dictionary).get(4, 0.0)) < 1199.0:
		return _fail("Defeated floor boss must start its long cooldown")
	instance.call("_send_intent", "stat", ["strength"])
	if int(eloa.base_stats.get(&"strength", 0)) != 1:
		return _fail("Character panel could not allocate a stat point")
	var menu := sim.call("menu_model", PEER) as Dictionary
	if (menu.get("equipment_slots", []) as Array).size() != 21 or (menu.get("skills", []) as Array).size() != 4 or (menu.get("floors", []) as Array).size() != 4:
		return _fail("Player menu does not expose equipment, skills and the tower map")
	sim.call("descend", PEER)
	if int(sim.get("current_floor")) != 5 or int(sim.get("deepest_floor")) != 5:
		return _fail("Stairs must lead the party to the next floor")

	if bool(sim.call("select_character", PEER, &"cira")):
		return _fail("Character change must be refused inside the Tower")
	var banked_before := int(sim.get("banked_stone"))
	state["carried_stone"] = 3
	sim.call("leave_tower", PEER)
	if int(sim.get("banked_stone")) != banked_before + 3 or int(sim.get("village_progress")) != 1:
		return _fail("Expedition return did not apply village progress")
	instance.call("_send_intent", "character", ["cira"])
	if state["character_id"] != &"cira":
		return _fail("Character selection did not switch identity")
	sim.call("enter_tower", PEER)
	state["invulnerable"] = 0.0
	state["damage_cooldown"] = 0.0
	state["barrier"] = 0.0
	sim.call("take_damage", PEER, 10.0)
	if not bool((state["passive"] as RefCounted).call("has_sample")):
		return _fail("Cira did not store a hostile sample after taking damage")
	sim.call("leave_tower", PEER)

	var save_path := "user://village_exploration_test_save.json"
	if not bool(instance.call("_save_world", save_path)):
		return _fail("World state could not be saved")
	sim.set("banked_stone", 0)
	sim.set("village_progress", 0)
	state["quick_items"] = 0
	if not bool(instance.call("_load_world", save_path)):
		return _fail("World state could not be loaded")
	state = sim.call("player", PEER) as Dictionary
	if int(sim.get("banked_stone")) != banked_before + 3 or int(sim.get("village_progress")) != 1 or int(state["quick_items"]) != 1 or state["character_id"] != &"cira":
		return _fail("Loaded world did not restore expedition consequences")
	if float((sim.get("boss_cooldowns") as Dictionary).get(4, 0.0)) <= 0.0 or int(sim.get("deepest_floor")) != 5:
		return _fail("Boss cooldown and deepest floor did not survive save and load")
	eloa = (sim.get("character_builds") as Dictionary)["eloa"] as CharacterBuild
	if eloa.level != 2 or int(eloa.base_stats.get(&"strength", 0)) != 1:
		return _fail("Character experience and allocated stats did not survive save and load")
	var eloa_gear := (sim.get("character_gear") as Dictionary)["eloa"] as Dictionary
	if (eloa_gear["equipment"] as EquipmentLoadout).equipped_count() != 4 or (eloa_gear["inventory"] as ItemInventory).has(&"anel_de_folego_4"):
		return _fail("Equipment locations did not survive save and load")
	var eloa_gems := (sim.get("character_gems") as Dictionary)["eloa"] as Dictionary
	if String((eloa_gems["slots"] as Array)[3]) != "elo_residual":
		return _fail("Gem loadout did not survive save and load")

	sim.call("enter_tower", PEER)
	state["carried_stone"] = 2
	state["health"] = 10.0
	state["invulnerable"] = 0.0
	state["damage_cooldown"] = 0.0
	state["barrier"] = 0.0
	(state["carried_loot"] as Dictionary)["pedra_regenerativa"] = 2
	var ground_before := (sim.get("ground_items") as Array).size()
	sim.call("take_damage", PEER, 10.0)
	if state["zone"] != &"village" or int(state["carried_stone"]) != 0:
		return _fail("Defeat did not return to the village and drop carried loot")
	if (sim.get("ground_items") as Array).size() <= ground_before:
		return _fail("Carried load must stay on the Tower floor after defeat")
	await physics_frame
	# Agente cuida da build: pontos, marco, evolução de gema e suportes em área segura.
	var agent_build := sim.call("character_build", PEER) as CharacterBuild
	while agent_build.level < 10:
		sim.call("add_experience", PEER, int(sim.call("experience_required", agent_build.level)))
	var points_before := agent_build.unspent_stat_points
	var supports_before := 0
	for skill: Dictionary in (sim.call("menu_model", PEER) as Dictionary)["skills"]:
		supports_before += int(skill["support_count"])
	instance.call("_agent_manage_build")
	var supports_after := 0
	var pending_after := 0
	for skill: Dictionary in (sim.call("menu_model", PEER) as Dictionary)["skills"]:
		supports_after += int(skill["support_count"])
		pending_after += (skill["pending_choices"] as Array).size()
	if agent_build.unspent_stat_points >= points_before or not agent_build.selected_milestones.has(10):
		return _fail("Agent must spend stat points and choose the level 10 milestone")
	if supports_after <= supports_before and pending_after > 0:
		return _fail("Agent must attach supports or choose gem evolutions in Aresta")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("VILLAGE_EXPLORATION_OK: solo session on WorldSimulation, menus, combat, consequence and save cycle")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
