extends SceneTree

## Decisão 582 e regressão (2026-10-06): JOGAR começava um mundo novo e, ao sair, gravava por
## cima do save, perdendo o progresso. Agora há salvamento automático, CONTINUAR na tela inicial
## e NOVO JOGO pede confirmação quando já existe save.

const VILLAGE := "res://src/prototype/village/village_exploration.tscn"
const TITLE := "res://src/game/title_screen.tscn"
const TEST_PATH := "user://autosave_test_save.json"


func _init() -> void:
	_run.call_deferred()


func _clear() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(TEST_PATH + suffix)


func _run() -> void:
	SaveSlot.path = TEST_PATH
	_clear()

	# Sem save: só JOGAR, sem CONTINUAR.
	var title := (load(TITLE) as PackedScene).instantiate()
	root.add_child(title)
	await process_frame
	if title.get_node_or_null("Menu/Continue") != null or (title.get_node("Menu/Play") as Button).text != "JOGAR":
		return _fail("Without a save the title shows only JOGAR")
	title.queue_free()

	# Testes sem janela nunca gravam sozinhos: o save real do jogador fica protegido.
	var village := (load(VILLAGE) as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	if bool(village.call("autosave_enabled")):
		return _fail("Headless runs must not autosave unless a test forces it")

	# Entrar na Torre grava; o relógio de 60 s também grava.
	village.set("autosave_forced", true)
	var sim: RefCounted = village.get("_sim")
	sim.set("deepest_floor", 7)
	var peer := int(village.get("_local_peer"))
	for _frame in range(3):
		await physics_frame
	if SaveSlot.exists():
		return _fail("Autosave must wait for a zone change or the timer")
	sim.call("enter_tower", peer)
	for _frame in range(3):
		await physics_frame
	if not SaveSlot.exists():
		return _fail("Entering the tower must autosave")
	_clear()
	village.set("_autosave_timer", float(village.get("AUTOSAVE_INTERVAL")))
	await physics_frame
	await physics_frame
	if not SaveSlot.exists():
		return _fail("Autosave must run every AUTOSAVE_INTERVAL seconds")
	sim.call("leave_tower", peer)
	for _frame in range(3):
		await physics_frame
	village.queue_free()
	await process_frame

	# Com save: CONTINUAR primeiro, com resumo; NOVO JOGO pede confirmação antes de começar.
	title = (load(TITLE) as PackedScene).instantiate()
	root.add_child(title)
	await process_frame
	var menu := title.get_node("Menu")
	if menu.get_child(0).name != "Continue" or (title.get_node("Menu/Play") as Button).text != "NOVO JOGO":
		return _fail("With a save the title starts with CONTINUAR and renames JOGAR to NOVO JOGO")
	if not (title.get_node("Menu/SaveSummary") as Label).text.contains("andar 7"):
		return _fail("Continue summary must show the deepest floor: %s" % (title.get_node("Menu/SaveSummary") as Label).text)
	title.call("_play")
	await process_frame
	if not (title.get_node("NewGameDialog") as ConfirmationDialog).visible:
		return _fail("NOVO JOGO with a save must ask before replacing the progress")
	title.queue_free()
	await process_frame

	# CONTINUAR abre a vila com o mundo salvo, sem a escolha de personagem.
	SessionLaunch.request(&"solo", "127.0.0.1", SessionLaunch.DEFAULT_PORT, true)
	var resumed := (load(VILLAGE) as PackedScene).instantiate()
	root.add_child(resumed)
	await process_frame
	var resumed_sim: RefCounted = resumed.get("_sim")
	if int(resumed_sim.get("deepest_floor")) != 7 or (resumed.get("_character_panel") as Control).visible:
		return _fail("Continue must load the saved world and skip character selection")
	resumed.queue_free()
	await process_frame
	_clear()
	SaveSlot.path = SaveSlot.DEFAULT_PATH
	print("AUTOSAVE_OK: zone and timer autosave, headless guard, continue button with summary, new game confirmation and resume")
	quit(0)


func _fail(message: String) -> void:
	_clear()
	push_error(message)
	quit(1)
