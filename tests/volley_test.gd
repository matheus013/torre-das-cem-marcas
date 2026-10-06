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
	for _frame in range(60):
		sim.step(1.0 / 30.0)
		for event: Dictionary in sim.drain_events():
			if String(event.get("call", "")) == "travel" and String((event["args"] as Array)[0]) == "vfx/arrow":
				arrows += 1
				elements[String(event.get("theme", ""))] = true
				var args := event["args"] as Array
				directions[snappedf(((args[2] as Vector2) - (args[1] as Vector2)).angle(), 0.1)] = true
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
	print("VOLLEY_OK: %d arrows in %d directions, alternating elements, breath drain, toggle, exhaustion and breath on kill" % [arrows, directions.size()])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
