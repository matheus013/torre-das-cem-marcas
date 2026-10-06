extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(5150)
	sim.add_player(1, &"eloa")
	sim.unlock_all_gems(1, true)
	if not sim.set_gem_slot(1, 0, "pulso_cicatriz"):
		return _fail("Nova gem could not be slotted")
	var before := sim.derived_stats(1)
	if not is_equal_approx(float(before["area_multiplier"]), 1.0):
		return _fail("Area must start neutral without gear")

	# Anel de Área (+10) e Amuleto da Primeira Marca (+4 recuperação de recarga), fabricação regular.
	for item_id in ["anel_de_area", "amuleto_da_primeira_marca"]:
		sim.equip_item(1, sim._add_equipment_instance(&"eloa", item_id, "regular"))
	var after := sim.derived_stats(1)
	if not is_equal_approx(float(after["area_multiplier"]), 1.10):
		return _fail("Ring of Area must grant +10%% area, got %.3f" % float(after["area_multiplier"]))
	if float(after["cooldown_recovery_multiplier"]) <= float(before["cooldown_recovery_multiplier"]):
		return _fail("Amulet must improve cooldown recovery")
	if not is_equal_approx(float(after["cooldown_reduction"]), 1.0 - 1.0 / float(after["cooldown_recovery_multiplier"])):
		return _fail("Cooldown reduction must mirror recovery")

	sim.enter_tower(1)
	var base_radius := float(sim.resolve_slot(1, 0)["radius"])
	sim.drain_events()
	if not sim.use_skill(1, 0, sim.player(1)["position"] as Vector2):
		return _fail("Nova could not be cast")
	var cast_radius := -1.0
	for event: Dictionary in sim.drain_events():
		if String(event.get("call", "")) == "ring":
			cast_radius = float((event["args"] as Array)[1])
	if not is_equal_approx(cast_radius, base_radius * 1.10):
		return _fail("Nova radius must grow with area: base %.1f, cast %.1f" % [base_radius, cast_radius])
	var recharge := float((sim.player(1)["cooldowns"] as Array)[0])
	if not is_equal_approx(recharge, 5.0 / float(after["cooldown_recovery_multiplier"])):
		return _fail("Cooldown must shrink with recovery, got %.3f" % recharge)

	# Tetos: marcos extremos somados ao equipamento não passam de 60% de redução e +100% de área.
	var effects := sim.milestone_effects(1)
	effects["modifiers"] = {"cooldown_mult": 0.5, "radius_mult": 3.0}
	sim.character_build(1).base_stats[&"wisdom"] = 100000.0
	var capped := sim.derived_stats(1)
	if float(capped["area_multiplier"]) < 2.0 - 0.0001 or float(capped["cooldown_reduction"]) < 0.6 - 0.0001:
		return _fail("Extreme modifiers must reach the caps")
	if float(capped["cooldown_reduction"]) > 0.6 + 0.0001 or float(capped["area_multiplier"]) > 2.0 + 0.0001:
		return _fail("Caps exceeded: reduction %.2f, area %.2f" % [float(capped["cooldown_reduction"]), float(capped["area_multiplier"])])
	print("COOLDOWN_AREA_OK: area x%.2f widens gems, cooldown -%.0f%%, caps hold" % [float(after["area_multiplier"]), float(after["cooldown_reduction"]) * 100.0])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
