extends SceneTree

## Épico E1, fase 5 (G8.8; decisão 607): Paragon da conta. Depois do nível 100, a EXP das
## dificuldades 3 a 5 (x1, x1,5 e x2) vira níveis Paragon até 200; o tabuleiro é por personagem, com
## todos os pontos da conta; trilhas dão bônus por ponto e nós notáveis a cada 10; respec em prata
## na vila; o perfil fica fora do save do mundo, vai pela rede e é gravado no disco do jogador.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Paragon := preload("res://src/gameplay/progression/paragon.gd")
const ParagonStore := preload("res://src/core/persistence/paragon_store.gd")
const MenuScript := preload("res://src/prototype/village/player_menu.gd")


func _init() -> void:
	_run.call_deferred()


func _world(level: int) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(6071)
	sim.add_player(1, &"rui")
	sim.unlocked_difficulty = 5
	sim.set_difficulty(1, level)
	return sim


func _level_to(sim: WorldSimulation, target: int) -> void:
	var build := sim.character_build(1)
	while build.level < target:
		if build.has_pending_milestone():
			build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
		build.level_up()
	sim.character_experience["rui"] = 0


func _run() -> void:
	# Antes do nível 100 ou abaixo da dificuldade 3, nada de Paragon.
	var early := _world(5)
	early._grant_experience(1, {"encounter_class": "boss"})
	var below := _world(2)
	_level_to(below, 100)
	below._grant_experience(1, {"encounter_class": "boss"})
	if int(early.paragon(1)["experience"]) != 0 or int(below.paragon(1)["experience"]) != 0:
		return _fail("Paragon needs level 100 and difficulty 3+")
	# Nível 100: EXP x1 na 3, x1,5 na 4, x2 na 5.
	var gains: Array[int] = []
	for level in [3, 4, 5]:
		var sim := _world(level)
		_level_to(sim, 100)
		sim._grant_experience(1, {"encounter_class": "common"})
		gains.append(int(sim.paragon(1)["experience"]))
	# A EXP do abate já cresce com a dificuldade (x2, x3, x4); o Paragon multiplica por 1, 1,5 e 2.
	if gains != [24, 54, 96]:
		return _fail("Paragon EXP must scale x1/x1.5/x2: %s" % [gains])
	# Níveis e teto.
	var data := Paragon.empty()
	if Paragon.gain(data, Paragon.required(0) + Paragon.required(1)) != 2 or int(data["level"]) != 2:
		return _fail("Paragon levels must follow the curve")
	Paragon.gain(data, 100000000)
	if int(data["level"]) != Paragon.MAX_LEVEL or int(data["experience"]) != 0:
		return _fail("Paragon caps at 200")

	# Tabuleiro: pontos da conta em cada personagem, bônus por ponto e notáveis.
	var board := _world(3)
	board.set_paragon(1, {"level": 25, "experience": 10, "boards": {}})
	var power := board._mod(1, "power_mult")
	for point in range(10):
		if not board.allocate_paragon(1, "ofensiva"):
			return _fail("Unspent points must be allocatable")
	if not is_equal_approx(board._mod(1, "power_mult") / power, 1.15):
		return _fail("Offense must give +1.5%% power per point: %s" % (board._mod(1, "power_mult") / power))
	if not is_equal_approx(board._mod(1, "crit_chance_add"), 0.05):
		return _fail("10 points must open the first notable (+5% crit)")
	for point in range(15):
		board.allocate_paragon(1, "utilidade")
	if board.allocate_paragon(1, "defensiva") or board.paragon_unspent(1) != 0:
		return _fail("The board cannot spend more than the account level")
	board._light_radii.clear()
	# 15 pontos em Utilidade: +15% de luz e o primeiro notável (Fôlego Fundo, +30); a Lanterna é o de 30.
	if not is_equal_approx(board.light_radius(1), board.LIGHT_RADIUS * 1.15) or not is_equal_approx(board._mod(1, "max_breath_add"), 45.0):
		return _fail("Utility points and its first notable must apply: light %s, breath %s" % [board.light_radius(1), board._mod(1, "max_breath_add")])
	# Outra personagem usa os mesmos pontos num tabuleiro próprio.
	board.select_character(1, &"cira")
	if board.paragon_unspent(1) != 25 or not is_equal_approx(board._mod(1, "crit_chance_add"), 0.0):
		return _fail("Each character has its own board with every account point")
	board.select_character(1, &"rui")
	# Respec: só na vila e pago em prata.
	board._gear(1)["silver"] = 5000
	board.enter_tower(1)
	if board.respec_paragon(1):
		return _fail("Paragon respec only in the village")
	board.leave_tower(1)
	var cost := board.paragon_respec_cost(1)
	if cost != 25 * Paragon.RESPEC_SILVER_PER_POINT or not board.respec_paragon(1) or int(board._gear(1)["silver"]) != 5000 - cost or board.paragon_unspent(1) != 25:
		return _fail("Respec must refund points for silver")

	# Rede: nível, EXP e tabuleiro chegam em comandos curtos e são saneados.
	var host := _world(3)
	host.set_paragon_progress(1, 999, 999999)
	host.set_paragon_board(1, "rui", "300,5,0,0")
	if int(host.paragon(1)["level"]) != Paragon.MAX_LEVEL or Paragon.spent(host.paragon_board(1)) > Paragon.MAX_LEVEL:
		return _fail("Paragon from clients must be clamped")
	if not (host.view_snapshot()["players"][1] as Dictionary).has("paragon_data"):
		return _fail("The snapshot must carry the player's Paragon for the owner to save")
	# Perfil fora do save do mundo, gravado e lido do disco.
	ParagonStore.path = "user://paragon_test.json"
	var saved := {"level": 12, "experience": 40, "boards": {"rui": {"ofensiva": 10, "defensiva": 2, "utilidade": 0, "elemental": 0}}}
	if ParagonStore.save_data(saved) != OK or ParagonStore.load_data() != Paragon.sanitize(saved):
		return _fail("The Paragon profile must round-trip on disk")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://paragon_test.json"))
	if host.save_data(1).has("paragon"):
		return _fail("Paragon must stay out of the world save")
	# Menu: trilhas com botões e notáveis.
	var menu := MenuScript.new()
	root.add_child(menu)
	board.set_paragon(1, {"level": 12, "experience": 0, "boards": {}})
	menu.call("refresh", board.menu_model(1))
	menu.call("open", "character")
	await process_frame
	var rows := menu.find_child("ParagonBoard", true, false)
	if rows == null or rows.get_child_count() != Paragon.TRACKS.size() or (rows.get_child(0).find_child("Add", true, false) as Button).disabled:
		return _fail("The character tab must show the four Paragon tracks")
	menu.queue_free()
	await process_frame
	print("PARAGON_OK: level 100 and difficulty 3+, EXP x1/x1.5/x2, cap 200, per-character boards, track bonuses, notables, respec in silver, network clamp, profile on disk and menu")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
