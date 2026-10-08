extends SceneTree

## Ataque normal no clique (ou tecla) e ataque automático que pode ser desligado, como a mira.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Bindings := preload("res://src/core/app/input_bindings.gd")
const Settings := preload("res://src/core/app/game_settings.gd")
const PATH := "user://aresta_manual_attack_test.cfg"


func _init() -> void:
	_run.call_deferred()


func _world() -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5863)
	sim.add_player(1, &"eloa")
	sim.enter_tower(1)
	var state := sim.player(1)
	sim.enemies.resize(2)
	var reach := float(sim.weapon_attack_model(1)["range"])
	for index in range(2):
		var enemy := sim.enemies[index]
		# Um à direita e outro à esquerda, ambos ao alcance da arma.
		enemy["position"] = (state["position"] as Vector2) + Vector2(reach * 0.5 * (1.0 if index == 0 else -1.0), 0.0)
		enemy["health"] = 1.0e6
		enemy["max_health"] = 1.0e6
		enemy["shield_hits"] = 0
		enemy["speed"] = 0.0
	return sim


func _step(sim: WorldSimulation, seconds: float) -> void:
	for _frame in range(int(round(seconds * 30.0))):
		sim.player(1)["health"] = 1.0e6
		sim.player(1)["breath"] = 200.0
		sim.step(1.0 / 30.0)
		sim.drain_events()


func _run() -> void:
	_clean()
	# Ligado (padrão): ataca o mais próximo sozinho.
	var auto := _world()
	if not bool(auto.player(1)["auto_attack"]):
		return _fail("Auto attack must start enabled")
	_step(auto, 2.0)
	if float(auto.enemies[0]["health"]) >= 1.0e6 and float(auto.enemies[1]["health"]) >= 1.0e6:
		return _fail("Auto attack did not hit a nearby enemy")

	# Desligado: nada acontece sem clique.
	var manual := _world()
	manual.set_auto_attack(1, false)
	_step(manual, 2.0)
	if float(manual.enemies[0]["health"]) < 1.0e6 or float(manual.enemies[1]["health"]) < 1.0e6:
		return _fail("With auto attack off nothing must be hit without a click")
	# Clique à esquerda: acerta o inimigo mais perto da mira, não o outro.
	var left := manual.enemies[1]["position"] as Vector2
	manual.request_attack(1, left + Vector2(-20.0, 0.0))
	_step(manual, 0.1)
	if float(manual.enemies[1]["health"]) >= 1.0e6 or float(manual.enemies[0]["health"]) < 1.0e6:
		return _fail("A click must hit the enemy nearest the aim point")
	# O pedido expira: sem segurar, não continua atacando.
	var after := float(manual.enemies[1]["health"])
	_step(manual, 2.0)
	if float(manual.enemies[1]["health"]) != after:
		return _fail("A single click must not keep attacking")
	# Segurar (pedidos renovados) respeita a cadência da arma.
	var interval := float(manual.weapon_attack_model(1)["interval"])
	var hits := 0
	var last := float(manual.enemies[1]["health"])
	for _frame in range(60):
		manual.request_attack(1, left)
		_step(manual, 1.0 / 30.0)
		if float(manual.enemies[1]["health"]) < last:
			hits += 1
			last = float(manual.enemies[1]["health"])
	if hits < 1 or hits > int(ceil(2.0 / interval)) + 1:
		return _fail("Holding the attack must follow the weapon rate: %d hits in 2 s (interval %.2f)" % [hits, interval])
	# Clique no vazio, sem inimigo ao alcance: não quebra e não acerta ninguém longe.
	manual.enemies[0]["position"] = (manual.player(1)["position"] as Vector2) + Vector2(5000.0, 0.0)
	manual.enemies[1]["position"] = (manual.player(1)["position"] as Vector2) + Vector2(-5000.0, 0.0)
	var far := [float(manual.enemies[0]["health"]), float(manual.enemies[1]["health"])]
	manual.request_attack(1, (manual.player(1)["position"] as Vector2) + Vector2(0.0, 100.0))
	_step(manual, 0.5)
	if float(manual.enemies[0]["health"]) != far[0] or float(manual.enemies[1]["health"]) != far[1]:
		return _fail("A click into empty space must not hit far enemies")

	# Preferência salva, alternável e com teclas próprias sem repetir nenhuma outra.
	var defaults := Bindings.defaults()
	if defaults["attack"] != KEY_SPACE or defaults["auto_attack"] != KEY_J or not Bindings.valid(defaults) or Bindings.PAD_BUTTONS.get("attack") != JOY_BUTTON_B:
		return _fail("Attack must be Space (B on pad) and auto attack toggle J, without conflicts")
	Settings.apply(Settings.DEFAULTS)
	if not Settings.auto_attack or Settings.toggle_auto_attack(PATH) != OK or Settings.auto_attack or bool(Settings.read(PATH)["auto_attack"]):
		return _fail("Auto attack toggle must persist off")

	# Na vila: clique esquerdo na Torre pede ataque; J desliga o automático no host.
	Settings.apply(Settings.DEFAULTS)
	Bindings.apply(defaults)
	var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(village)
	(village.get("_character_panel") as Control).hide()
	var sim: RefCounted = village.get("_sim")
	sim.call("enter_tower", 1)
	village.call("_physics_process", 1.0 / 60.0)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(400.0, 300.0)
	village.call("_unhandled_input", click)
	if float((sim.call("player", 1) as Dictionary)["attack_request_timer"]) <= 0.0:
		return _fail("Left click in the Tower did not request an attack")
	var toggle := InputEventKey.new()
	toggle.keycode = KEY_J
	toggle.pressed = true
	village.call("_toggle_auto_attack", PATH)
	if bool((sim.call("player", 1) as Dictionary)["auto_attack"]) or Settings.auto_attack:
		return _fail("Toggling auto attack in game did not reach the simulation")
	if not Bindings.pressed(toggle, "auto_attack"):
		return _fail("J must be the auto attack toggle")
	village.queue_free()
	await process_frame
	Settings.apply(Settings.DEFAULTS)
	_clean()
	print("MANUAL_ATTACK_OK: click/hold attack at the aim point, toggleable auto attack, persisted")
	quit(0)


func _fail(message: String) -> void:
	_clean()
	Settings.apply(Settings.DEFAULTS)
	push_error(message)
	quit(1)


func _clean() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(PATH + suffix)
