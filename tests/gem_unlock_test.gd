extends SceneTree

## Decisão 579: cada personagem começa com autoataque e uma gema; chefes até o andar 72 entregam
## conjuntos de gemas; gemas sobem de nível pelo uso e cada nível libera uma evolução.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var all_gems: Array[String] = []
	for gem: Dictionary in catalog["active_gems"]:
		all_gems.append(String(gem["id"]))

	# Conjuntos: cada gema ativa sai de exatamente um chefe, todos até o andar 72.
	var seen := {}
	var bosses_with_sets := 0
	for boss: Dictionary in TowerContent.collection("bosses"):
		var gem_set := boss.get("gem_set", []) as Array
		if gem_set.is_empty():
			continue
		bosses_with_sets += 1
		if int(boss["floor"]) > 72:
			return _fail("Gem sets must end by floor 72, found one on %d" % int(boss["floor"]))
		for gem_id: Variant in gem_set:
			if seen.has(gem_id) or String(gem_id) not in all_gems:
				return _fail("Gem %s repeated or unknown in boss sets" % gem_id)
			seen[gem_id] = true
	if seen.size() != all_gems.size():
		return _fail("Every active gem must come from a boss set: %d of %d" % [seen.size(), all_gems.size()])

	# Início: só a gema da personagem, em Q; os outros encaixes vazios não lançam nada.
	for character_id in Simulation.CHARACTER_IDS:
		var fresh := Simulation.new()
		fresh.setup(61)
		fresh.add_player(1, character_id)
		var state := fresh._gem_state(1)
		var starter := String(Simulation.STARTER_GEMS[character_id])
		if (state["gems"] as Dictionary).keys() != [starter] or state["slots"] != [starter, "", "", ""]:
			return _fail("%s must start with only %s in Q, got %s" % [character_id, starter, state["slots"]])
	var sim := Simulation.new()
	sim.setup(62)
	sim.add_player(1, &"eloa")
	sim.enter_tower(1)
	if sim.use_skill(1, 1, Vector2(900, 500)) or not sim.resolve_slot(1, 1).is_empty():
		return _fail("An empty slot must not cast")

	# EXP só pelo uso: lançar dá EXP à gema lançada; abate feito por ela dá a EXP do inimigo;
	# abate do autoataque não alimenta gema nenhuma.
	var progress := sim._gem_state(1)["gems"]["elo_residual"] as Dictionary
	sim.player(1)["breath"] = 100.0
	if not sim.use_skill(1, 0, Vector2(900, 500)) or int(progress["experience"]) != Simulation.GEM_CAST_EXPERIENCE:
		return _fail("Casting grants the cast gem %d experience, got %d" % [Simulation.GEM_CAST_EXPERIENCE, int(progress["experience"])])
	var before := int(progress["experience"])
	sim.damage_enemy(1, 0, 1.0e9)
	if int(progress["experience"]) != before:
		return _fail("Auto attack kills must not feed gems")
	var reward := int(Simulation.EXPERIENCE_REWARDS[String(sim.enemies[0].get("encounter_class", "common"))])
	sim.damage_enemy(1, 0, 1.0e9, {"gem_id": "elo_residual", "gem": true})
	if int(progress["experience"]) - before != reward:
		return _fail("A kill by the gem grants the enemy experience (%d) to that gem, got %d" % [reward, int(progress["experience"]) - before])
	sim.leave_tower(1)
	if sim.set_gem_slot(1, 1, "bola_de_fogo"):
		return _fail("A gem the character does not own cannot be slotted")

	# Chefe do andar 4 (decisão 585): cada vitória dá uma gema do conjunto ou nenhuma; depois de
	# uma vitória sem gema, a próxima garante. Eloa já tinha o Elo Residual.
	sim.set("deepest_floor", 4)
	sim.set("tower_start_floor", 4)
	sim.enter_tower(1)
	var boss_index := -1
	for index in range(sim.enemies.size()):
		if bool(sim.enemies[index].get("floor_boss", false)):
			boss_index = index
	if boss_index < 0:
		return _fail("Floor 4 must spawn its boss")
	var owned := sim._gem_state(1)["gems"] as Dictionary
	sim.damage_enemy(1, boss_index, 1.0e9)
	if owned.size() > 2:
		return _fail("A boss victory grants at most one gem, owned %d" % owned.size())
	var last := owned.size()
	var empty_streak := 1 if last == 1 else 0
	var victories := 1
	while last < 6 and victories < 40:
		sim._grant_boss_gems(4)
		victories += 1
		var gained := owned.size() - last
		if gained > 1:
			return _fail("A boss victory grants at most one gem")
		empty_streak = empty_streak + 1 if gained == 0 else 0
		if empty_streak > 1:
			return _fail("After a victory without gem the next one must grant one")
		last = owned.size()
	for gem_id in Simulation.boss_gem_set(4):
		if not owned.has(gem_id):
			return _fail("Repeated victories must complete the set of floor 4: missing %s" % gem_id)
	if victories > 11:
		return _fail("Completing 5 gems took %d victories; pity must cap it at 10" % victories)
	if owned.has("bola_de_fogo"):
		return _fail("Gems of later bosses stay locked")
	var slots := sim._gem_state(1)["slots"] as Array
	if slots[0] != "elo_residual" or slots.has(""):
		return _fail("New gems fill the empty slots, got %s" % [slots])

	if int(progress["level"]) != 1:
		return _fail("Starter gem must still be level 1 before enough use")
	progress["experience"] = 0

	# Maestria (decisão 588): 21 níveis; nível 5 pede 1 de 3 modificadores, escolhido só em Aresta;
	# cada nível soma 5% aos números; requisitos de atributo limitam o nível em que a gema age.
	var build := sim.character_build(1)
	build.base_stats[&"intelligence"] = 300.0
	build.base_stats[&"fortune"] = 300.0
	var to_five := 0
	for level in range(1, 5):
		to_five += sim.gem_experience_required(level)
	sim.gain_gem_experience(1, "elo_residual", to_five)
	if int(progress["level"]) != 5 or Simulation.pending_evolution_tier(progress) != 5:
		return _fail("Level 5 must ask for the first mastery modifier, got level %d" % int(progress["level"]))
	var offered := sim.gem_definition("elo_residual")["evolutions"]["5"] as Array
	if offered.size() != 3:
		return _fail("Mastery levels offer three modifiers")
	var option := offered[2] as Dictionary
	if sim.choose_gem_evolution(1, "elo_residual", String(option["id"])):
		return _fail("Mastery modifiers are chosen in Aresta only")
	sim.leave_tower(1)
	var base_power := float(sim.gem_definition("elo_residual")["power"])
	var before_choice := float(sim.resolve_slot(1, 0)["power"])
	if not is_equal_approx(before_choice, base_power * 1.2):
		return _fail("Each gem level adds 5%% to its numbers (level 5 = x1.2), got %.2f" % (before_choice / base_power))
	if not sim.choose_gem_evolution(1, "elo_residual", String(option["id"])):
		return _fail("Pending modifier must be selectable in Aresta")
	var power_multiplier := float((option["modifiers"] as Dictionary).get("power_multiplier", 1.0))
	if not is_equal_approx(float(sim.resolve_slot(1, 0)["power"]), before_choice * power_multiplier):
		return _fail("Chosen modifier must apply to the gem")
	build.base_stats[&"intelligence"] = 0.0
	if sim.gem_effective_level(1, "elo_residual") >= 5 or is_equal_approx(float(sim.resolve_slot(1, 0)["power"]), before_choice * power_multiplier):
		return _fail("Without the attribute requirements the gem acts at a lower level")
	build.base_stats[&"intelligence"] = 300.0
	sim.gain_gem_experience(1, "elo_residual", 100000000)
	if int(progress["level"]) != Simulation.GEM_MAX_LEVEL_BETA or int(progress["experience"]) != 0 or Simulation.pending_evolution_tier(progress) != 10:
		return _fail("Experience stops at level 21 and leaves mastery 10 pending, got level %d" % int(progress["level"]))
	if (sim.gem_definition("elo_residual")["evolutions"]["21"] as Array).size() != 2 or not bool(sim.gem_definition("elo_residual")["evolutions"]["21"][0].get("capstone", false)):
		return _fail("Level 21 offers two great modifiers")
	if (sim.menu_model(1)["skills"] as Array)[0]["pending_tier"] != 10:
		return _fail("Skill card must show the pending mastery level")
	var requirement := sim.gem_requirements("elo_residual", 21)
	if float(requirement["intelligence"]) != 150.0 or float(requirement["fortune"]) != 90.0 or sim.gem_requirements("elo_residual", 1)["intelligence"] != 0.0:
		return _fail("Requirements go from 0 to 150 (primary) and 90 (secondary): %s" % [requirement])
	# Curva: levar a gema ao 21 custa GEM_EXPERIENCE_SHARE da EXP que a personagem gasta até o 95.
	var gem_total := 0
	for level in range(1, Simulation.GEM_MAX_LEVEL_BETA):
		gem_total += sim.gem_experience_required(level)
	var player_total := 0
	for level in range(1, Simulation.GEM_PLAYER_LEVEL_EQUIVALENT):
		player_total += sim.experience_required(level)
	if absf(float(gem_total) / float(player_total) - Simulation.GEM_EXPERIENCE_SHARE) > 0.01:
		return _fail("Gem level 21 must cost the share of player level 95: %d vs %d" % [gem_total, player_total])

	# Encaixe pode ficar vazio de novo e o save guarda posse, níveis e vazios.
	if not sim.set_gem_slot(1, 3, ""):
		return _fail("A slot can be emptied in Aresta")
	var saved := sim.save_data(1)
	var restored := Simulation.new()
	restored.setup(62)
	restored.add_player(1, &"eloa")
	if not restored.load_data(saved, 1):
		return _fail("Save with owned gems must load")
	var restored_state := restored._gem_state(1)
	if restored_state["slots"] != (sim._gem_state(1)["slots"] as Array) or (restored_state["gems"] as Dictionary).size() != 6 or int(restored_state["gems"]["elo_residual"]["level"]) != 21:
		return _fail("Owned gems, levels and empty slots must survive save/load, got %s" % [restored_state["slots"]])

	# Save antigo (versão 7, todas as gemas): fica com a inicial, as gemas com progresso e os
	# conjuntos dos chefes já ultrapassados; quem escolhera a evolução do nível atual sobe um nível.
	var legacy := saved.duplicate(true)
	legacy["version"] = 7
	legacy["deepest_floor"] = 8
	var legacy_gems := {}
	for gem_id in all_gems:
		legacy_gems[gem_id] = {"level": 1, "experience": 0, "choices": {}}
	var agulha_choice := "agulha_lastro_e1_0"
	legacy_gems["agulha_lastro"] = {"level": 1, "experience": 20, "choices": {"1": agulha_choice}}
	legacy_gems["prisao_gravitica"] = {"level": 2, "experience": 5, "choices": {"1": "prisao_gravitica_e1_0"}}
	legacy["character_gems"] = {"eloa": {"slots": ["agulha_lastro", "passo_vetorial", "pulso_cicatriz", "cometa_de_vidro"], "supports": [[], [], [], []], "auto_supports": [], "gems": legacy_gems}}
	var migrated := Simulation.new()
	migrated.setup(63)
	migrated.add_player(1, &"eloa")
	if not migrated.load_data(legacy, 1):
		return _fail("Version 7 save must still load")
	var migrated_state := migrated._gem_state(1)
	var migrated_gems := migrated_state["gems"] as Dictionary
	if migrated_state["slots"] != ["agulha_lastro", "passo_vetorial", "pulso_cicatriz", ""]:
		return _fail("Legacy slots keep owned gems and empty the rest, got %s" % [migrated_state["slots"]])
	# Saves antigos: a EXP da curva antiga (150 x nível) vira nível na curva nova e as escolhas somem.
	var agulha := migrated_gems["agulha_lastro"] as Dictionary
	if int(agulha["level"]) != 1 or int(agulha["experience"]) != 170 or not (agulha["choices"] as Dictionary).is_empty() or migrated_gems.has("cometa_de_vidro"):
		return _fail("Legacy gem experience converts to the new curve and old choices are cleared: %s" % [agulha])
	if not migrated_gems.has("bola_de_fogo") or migrated_gems.has("arco_voltaico"):
		return _fail("Legacy saves receive the sets of bosses already passed (floors 4 and 7)")

	print("GEM_UNLOCK_OK: %d bosses share %d gems, starter-only start, boss sets, usage experience, 21-level mastery with requirements, save and migration" % [bosses_with_sets, seen.size()])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
