extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(9090)
	sim.add_player(1, &"sena")
	sim.grant_gem(1, "saraivada_de_flechas")
	sim.set_gem_slot(1, 0, "saraivada_de_flechas")
	sim.enter_tower(1)
	var state := sim.player(1)
	state["invulnerable"] = 999.0
	var breath_start := float(state["breath"])
	if not sim.use_skill(1, 0, state["position"] as Vector2):
		return _fail("Saraivada could not be activated")
	var arrows := 0
	var elements := {}
	var directions := {}
	var previous_direction := INF
	for _frame in range(60):
		sim.step(1.0 / 30.0)
		var frame_arrows := 0
		for event: Dictionary in sim.drain_events():
			if String(event.get("call", "")) == "travel" and String((event["args"] as Array)[0]) == "vfx/arrow":
				arrows += 1
				frame_arrows += 1
				elements[String(event.get("theme", ""))] = true
				var args := event["args"] as Array
				var angle := ((args[2] as Vector2) - (args[1] as Vector2)).angle()
				directions[snappedf(angle, 0.1)] = true
				if is_finite(previous_direction) and not is_equal_approx(wrapf(angle - previous_direction, -PI, PI), TAU / 24.0):
					return _fail("Arrows must follow successive angles of the spin")
				previous_direction = angle
		if frame_arrows < 1 or frame_arrows > 3:
			return _fail("Saraivada must stream shots, not emit radial bursts: %d" % frame_arrows)
		var spin := ((sim.view_snapshot()["players"] as Dictionary)[1] as Dictionary)["volley_spin"] as Dictionary
		if spin.is_empty() or not is_equal_approx(float(spin["elapsed"]), float(_frame + 1) / 30.0):
			return _fail("Snapshot must carry the owner's authoritative spin animation")
	if arrows < 72 or directions.size() < 24:
		return _fail("Saraivada must fire arrows in every direction over time (%d arrows, %d directions)" % [arrows, directions.size()])
	if not (elements.has("element:fire") and elements.has("element:ice") and elements.has("element:lightning")):
		return _fail("Volleys must alternate fire, ice and lightning: %s" % [elements.keys()])
	if float(state["breath"]) >= breath_start - 6.0:
		return _fail("Saraivada must drain Breath while active")

	# Usar de novo encerra (passada a recarga curta).
	(state["cooldowns"] as Array)[0] = 0.0
	(state["charges"] as Array)[0] = 1
	sim.use_skill(1, 0, state["position"] as Vector2)
	if (sim.get("persistent_effects") as Array).any(func(effect: Dictionary) -> bool: return effect["mechanic"] == "volley"):
		return _fail("Casting again must end the Saraivada")
	if not ((sim.view_snapshot()["players"] as Dictionary)[1]["volley_spin"] as Dictionary).is_empty():
		return _fail("Stopping Saraivada must restore the normal character animation")

	# Regressão (2026-10-08): a Saraivada acabava sozinha em 8 s. Agora só termina ao lançar de novo
	# ou sem Fôlego: com Fôlego sobrando, segue ativa por muito mais tempo, e o ícone mostra o Fôlego.
	(state["cooldowns"] as Array)[0] = 0.0
	(state["charges"] as Array)[0] = 1
	sim.use_skill(1, 0, state["position"] as Vector2)
	for _second in range(30):
		state["breath"] = sim.max_breath(1)
		for _frame in range(30):
			sim.step(1.0 / 30.0)
		sim.drain_events()
	if not (sim.get("persistent_effects") as Array).any(func(effect: Dictionary) -> bool: return effect["mechanic"] == "volley"):
		return _fail("Saraivada must not end by time while there is Breath")
	var icon: Array = sim.player_status_effects(1).filter(func(effect: Dictionary) -> bool: return String(effect["id"]) == "volley")
	if icon.is_empty() or not is_equal_approx(float(icon[0]["remaining"]), float(state["breath"]) / 9.0):
		return _fail("The Saraivada icon must show how long the Breath lasts: %s" % [icon])
	(state["cooldowns"] as Array)[0] = 0.0
	(state["charges"] as Array)[0] = 1
	sim.use_skill(1, 0, state["position"] as Vector2)

	# Sem Fôlego, ela se encerra sozinha.
	(state["cooldowns"] as Array)[0] = 0.0
	(state["charges"] as Array)[0] = 1
	sim.use_skill(1, 0, state["position"] as Vector2)
	state["breath"] = 0.1
	sim.step(0.1)
	if (sim.get("persistent_effects") as Array).any(func(effect: Dictionary) -> bool: return effect["mechanic"] == "volley"):
		return _fail("Running out of Breath must end the Saraivada")

	# Fôlego Predador: abate pelas flechas devolve Fôlego.
	var enemies := sim.get("enemies") as Array
	enemies[0]["health"] = 1.0
	state["breath"] = 10.0
	sim.damage_enemy(1, 0, 50.0, {"breath_on_kill": 3.0, "gem": true})
	if not is_equal_approx(float(state["breath"]), 13.0):
		return _fail("Kills by an arrow with Folego Predador must restore Breath (got %.1f)" % float(state["breath"]))
	for fps in [20, 60, 120]:
		var check := Simulation.new()
		check.setup(9090)
		check.add_player(1, &"sena")
		check.enter_tower(1)
		check.call("_toggle_volley", 1, {"gem_id": "saraivada_de_flechas", "power": 0.0}, {})
		for step in fps:
			check.call("_update_persistent_effects", 1.0 / float(fps))
		var effect := (check.get("persistent_effects") as Array)[0] as Dictionary
		if absi(int(effect["volley_index"]) - 60) > 1:
			return _fail("Cadence changes with frame rate: %d FPS, %d arrows" % [fps, effect["volley_index"]])
	print("VOLLEY_OK: %d arrows in %d directions, alternating elements, breath drain, no time limit, toggle, exhaustion and breath on kill" % [arrows, directions.size()])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
