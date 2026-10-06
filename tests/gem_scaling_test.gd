extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(2024)
	sim.add_player(1, &"eloa")
	sim.unlock_all_gems(1, true)
	sim.set_gem_slot(1, 0, "pulso_cicatriz")
	var build := sim.character_build(1)
	for stat in CharacterBuild.PRIMARY_STATS:
		build.base_stats[stat] = 0.0
	var weak := (sim.menu_model(1)["skills"] as Array)[0] as Dictionary
	if not is_equal_approx(float(weak["power"]), float(weak["base_power"])):
		return _fail("Without attributes the gem must show its base power")
	build.base_stats[&"intelligence"] = 100.0
	build.base_stats[&"vitality"] = 50.0
	var strong := (sim.menu_model(1)["skills"] as Array)[0] as Dictionary
	# Pulso de Cicatriz: Inteligência 0,6%/ponto e Vitalidade 0,4%/ponto.
	var expected := 1.0 + 100.0 * 0.006 + 50.0 * 0.004
	if not is_equal_approx(float(strong["power_multiplier"]), expected) or not is_equal_approx(float(strong["power"]), float(strong["base_power"]) * expected):
		return _fail("Gem card must show attribute-scaled power, got x%.3f" % float(strong["power_multiplier"]))
	var scaling := strong["scaling"] as Array
	if scaling.size() != 2 or String(scaling[0]["stat"]) != "intelligence" or not is_equal_approx(float(scaling[0]["points"]), 100.0):
		return _fail("Gem card must list its scaling attributes")
	if not is_equal_approx(float(sim._skill_power_multiplier(1, sim.resolve_slot(1, 0))), float(strong["power_multiplier"])):
		return _fail("Shown multiplier must be the one applied when casting")
	var tooltip := String((sim.skill_tooltips(1))[0])
	if not tooltip.contains("Escala com: Inteligencia") or not tooltip.contains("Potencia: %.0f" % float(strong["power"])):
		return _fail("Skill tooltip must show scaled power and scaling: " + tooltip)
	print("GEM_SCALING_OK: gem power x%.2f from attributes, shown in card and tooltip" % expected)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
