extends SceneTree

## Reset de atributos: devolve todos os pontos distribuídos (5 por nível comum) e mantém os
## atributos das evoluções escolhidas; botão com confirmação na aba Personagem.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const MenuScene := preload("res://src/prototype/village/player_menu.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(5866)
	sim.add_player(1, &"eloa")
	var build := sim.character_build(1)
	while build.level < 23:
		if build.has_pending_milestone():
			build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
		build.level_up()
	var bonus := build.milestone_stat_bonus()
	var earned := build.earned_stat_points()
	if earned != 105:
		return _fail("Level 23 earns 5 + 5 per non-evolution level = 105 points, got %d" % earned)
	for stat in CharacterBuild.PRIMARY_STATS:
		while build.unspent_stat_points > 0 and float(build.base_stats[stat]) < float(bonus.get(stat, 0.0)) + 15.0:
			sim.allocate_stat(1, stat)
	if build.unspent_stat_points == earned:
		return _fail("Points must have been spent before the reset")
	if not sim.reset_stats(1) or build.unspent_stat_points != earned:
		return _fail("Reset must free every earned point: %d of %d" % [build.unspent_stat_points, earned])
	for stat in CharacterBuild.PRIMARY_STATS:
		if not is_equal_approx(float(build.base_stats[stat]), float(bonus.get(stat, 0.0))):
			return _fail("After reset only milestone stats remain: %s has %.0f, milestones give %.0f" % [stat, float(build.base_stats[stat]), float(bonus.get(stat, 0.0))])
	sim.allocate_stat(1, &"wisdom")
	if build.unspent_stat_points != earned - 1:
		return _fail("Points must be spendable again after the reset")
	# Save e carga mantêm os pontos livres corretos.
	var restored := Simulation.new()
	restored.setup(5866)
	restored.add_player(1, &"eloa")
	if not restored.load_data(sim.save_data(1), 1) or restored.character_build(1).unspent_stat_points != earned - 1:
		return _fail("Reset points must survive save and load")

	var menu := MenuScene.new()
	root.add_child(menu)
	menu.call("refresh", sim.menu_model(1))
	menu.call("open", "character")
	await process_frame
	var button := menu.find_child("ResetStats", true, false) as Button
	if button == null:
		return _fail("Character tab must have a reset stats button")
	var requested := [false]
	menu.connect("stats_reset_requested", func() -> void: requested[0] = true)
	button.pressed.emit()
	var dialog := menu.find_child("ResetStatsDialog", true, false) as ConfirmationDialog
	if dialog == null or not dialog.visible or requested[0]:
		return _fail("Reset must ask for confirmation first")
	dialog.confirmed.emit()
	if not requested[0]:
		return _fail("Confirming must request the reset")
	menu.queue_free()
	await process_frame
	print("STAT_RESET_OK: frees %d points, keeps milestone stats, confirmation in the menu" % earned)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
