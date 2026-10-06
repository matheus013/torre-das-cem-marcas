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

	# Chefe do andar 4: quem está na arena recebe o conjunto (Eloa já tinha o Elo Residual).
	sim.set("deepest_floor", 4)
	sim.set("tower_start_floor", 4)
	sim.enter_tower(1)
	var boss_index := -1
	for index in range(sim.enemies.size()):
		if bool(sim.enemies[index].get("floor_boss", false)):
			boss_index = index
	if boss_index < 0:
		return _fail("Floor 4 must spawn its boss")
	sim.damage_enemy(1, boss_index, 1.0e9)
	var owned := sim._gem_state(1)["gems"] as Dictionary
	for gem_id in Simulation.boss_gem_set(4):
		if not owned.has(gem_id):
			return _fail("Boss of floor 4 must grant %s" % gem_id)
	if owned.size() != 6 or sim._gem_state(1)["slots"] != ["elo_residual", "agulha_lastro", "passo_vetorial", "estilhacos_lunares"]:
		return _fail("New gems fill the empty slots in order, got %s" % [sim._gem_state(1)["slots"]])
	if owned.has("bola_de_fogo"):
		return _fail("Gems of later bosses stay locked")

	if int(progress["level"]) != 1:
		return _fail("Starter gem must still be level 1 before enough use")
	progress["experience"] = 0

	# Níveis: 2, 3 e 4 liberam as evoluções 1, 2 e 3; escolha só em Aresta; nível máximo trava a EXP.
	sim.gain_gem_experience(1, "elo_residual", sim.gem_experience_required(1))
	if int(progress["level"]) != 2 or Simulation.pending_evolution_tier(progress) != 1:
		return _fail("Level 2 must unlock evolution tier 1")
	var option := (sim.gem_definition("elo_residual")["evolutions"]["1"] as Array)[0] as Dictionary
	if sim.choose_gem_evolution(1, "elo_residual", String(option["id"])):
		return _fail("Evolutions are chosen in Aresta only")
	sim.leave_tower(1)
	var base_power := float(sim.gem_definition("elo_residual")["power"])
	if not sim.choose_gem_evolution(1, "elo_residual", String(option["id"])):
		return _fail("Pending evolution must be selectable in Aresta")
	var power_multiplier := float((option["modifiers"] as Dictionary).get("power_multiplier", 1.0))
	if not is_equal_approx(float(sim.resolve_slot(1, 0)["power"]), base_power * power_multiplier):
		return _fail("Chosen evolution must apply to the gem")
	sim.gain_gem_experience(1, "elo_residual", 100000)
	if int(progress["level"]) != Simulation.GEM_MAX_LEVEL_BETA or int(progress["experience"]) != 0 or Simulation.pending_evolution_tier(progress) != 2:
		return _fail("Experience stops at max level and leaves tiers 2 and 3 pending, got level %d" % int(progress["level"]))
	if (sim.menu_model(1)["skills"] as Array)[0]["pending_tier"] != 2:
		return _fail("Skill card must show the pending tier")

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
	if restored_state["slots"] != ["elo_residual", "agulha_lastro", "passo_vetorial", ""] or (restored_state["gems"] as Dictionary).size() != 6 or int(restored_state["gems"]["elo_residual"]["level"]) != 4:
		return _fail("Owned gems, levels and empty slots must survive save/load, got %s" % [restored_state["slots"]])

	# Save antigo (versão 7, todas as gemas): fica com a inicial, as gemas com progresso e os
	# conjuntos dos chefes já ultrapassados; quem escolhera a evolução do nível atual sobe um nível.
	var legacy := saved.duplicate(true)
	legacy["version"] = 7
	legacy["deepest_floor"] = 8
	var legacy_gems := {}
	for gem_id in all_gems:
		legacy_gems[gem_id] = {"level": 1, "experience": 0, "choices": {}}
	var agulha_choice := String((sim.gem_definition("agulha_lastro")["evolutions"]["1"] as Array)[0]["id"])
	legacy_gems["agulha_lastro"] = {"level": 1, "experience": 20, "choices": {"1": agulha_choice}}
	legacy_gems["prisao_gravitica"] = {"level": 2, "experience": 5, "choices": {"1": String((sim.gem_definition("prisao_gravitica")["evolutions"]["1"] as Array)[0]["id"])}}
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
	if int(migrated_gems["agulha_lastro"]["level"]) != 2 or int(migrated_gems["prisao_gravitica"]["level"]) != 2 or migrated_gems.has("cometa_de_vidro"):
		return _fail("Legacy levels shift by the chosen evolution and untouched later gems stay locked")
	if not migrated_gems.has("bola_de_fogo") or migrated_gems.has("arco_voltaico"):
		return _fail("Legacy saves receive the sets of bosses already passed (floors 4 and 7)")

	print("GEM_UNLOCK_OK: %d bosses share %d gems, starter-only start, boss sets, usage experience, tiered evolutions, save and migration" % [bosses_with_sets, seen.size()])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
