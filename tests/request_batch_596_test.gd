extends SceneTree

## Decisão 596: dois anéis, respawn duas vezes mais rápido, escada após 10 minutos sobrevivendo,
## monstros com 10x Vida e +50% de velocidade, e quatro lendários novos (Botas do Vendaval, Anel da
## Corda Infinita, Anel do Furor e Sino do Fôlego Leve).

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _world(items: Array[String] = []) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5869)
	sim.add_player(1, &"sena")
	sim.unlock_all_gems(1)
	sim.set_gem_slot(1, 0, "saraivada_de_flechas")
	sim.set_gem_slot(1, 1, "lanca_ferral")
	for item_id in items:
		sim.equip_item(1, sim._add_equipment_instance(&"sena", item_id))
	sim.enter_tower(1)
	sim.enemies.clear()
	var state := sim.player(1)
	state["health"] = 1.0e9
	state["invulnerable"] = 999.0
	return sim


func _volley_turns(sim: WorldSimulation, turns: int) -> void:
	var state := sim.player(1)
	# Liga a Saraivada só se ainda não estiver ativa (lançar de novo a encerraria).
	if not sim.persistent_effects.any(func(effect: Dictionary) -> bool: return effect["mechanic"] == "volley"):
		(state["cooldowns"] as Array)[0] = 0.0
		(state["charges"] as Array)[0] = 1
		sim.use_skill(1, 0, state["position"] as Vector2)
	for _frame in range(int(round(turns * 0.4 * 60.0)) + 2):
		state["breath"] = sim.max_breath(1)
		sim.step(1.0 / 60.0)
		sim.drain_events()


func _run() -> void:
	# Dois anéis; anéis de saves antigos acima do segundo voltam para a mochila.
	if EquipmentLoadout.RING_SLOT_COUNT != 2:
		return _fail("There must be 2 ring slots")
	var rings := _world()
	var gear := rings._gear(1)
	var ring_ids: Array[StringName] = []
	for _copy in range(3):
		ring_ids.append(rings._add_equipment_instance(&"sena", "anel_de_folego"))
	var data := rings.save_data(1)
	var items := (data["character_gear"]["sena"]["items"] as Array)
	for entry: Dictionary in items:
		if StringName(String(entry["instance_id"])) == ring_ids[2]:
			entry["location"] = "equipped"
			entry["slot"] = EquipmentItemDefinition.Slot.RING
			entry["index"] = 7
	var restored := Simulation.new()
	restored.setup(5869)
	restored.add_player(1, &"sena")
	if not restored.load_data(data, 1) or not (restored._gear(1)["inventory"] as ItemInventory).has(ring_ids[2]):
		return _fail("A ring saved in an old 8th slot must come back to the backpack")

	# Respawn duas vezes mais rápido, com a mesma aceleração.
	var floor := _world()
	if not is_equal_approx(floor.respawn_interval(), 7.0):
		return _fail("Respawn must start at 7 s (was 14 s): %.2f" % floor.respawn_interval())
	floor.floor_run["time"] = 120.0
	if not is_equal_approx(floor.respawn_interval(), 3.5):
		return _fail("Respawn acceleration must stay: 3.5 s after 2 minutes, got %.2f" % floor.respawn_interval())

	# Escada: abates não abrem mais; só 10 minutos sobrevivendo no andar comum.
	floor.floor_run["time"] = 0.0
	floor.floor_run["kills"] = int(floor.floor_run.get("quota", 0)) + 50
	floor.step(1.0 / 60.0)
	if bool(floor.floor_run["stairs_open"]):
		return _fail("Kills must not open the stairs anymore")
	floor.floor_run["time"] = 599.0
	floor.step(0.5)
	if bool(floor.floor_run["stairs_open"]) or not is_equal_approx(float(floor.view_snapshot()["floor"]["survival_left"]), 0.5):
		return _fail("Stairs must stay closed before 10 minutes, with the countdown in the view")
	floor.step(0.6)
	if not bool(floor.floor_run["stairs_open"]):
		return _fail("Surviving 10 minutes must open the stairs")

	# Monstros: 10x Vida e +50% de velocidade.
	var definition := floor.content("enemies")[0]
	var plain := floor.create_enemy({"id": "teste", "health": 100.0, "speed": 40.0, "race_id": "", "rank_id": ""}, Vector2.ZERO, 0)
	if not is_equal_approx(float(plain["max_health"]), 1000.0) or not is_equal_approx(float(plain["speed"]), 60.0):
		return _fail("Enemies must have 10x health and +50%% speed: %s" % [plain])
	if definition.is_empty():
		return _fail("Enemy catalog missing")

	# Botas do Vendaval: +60% de velocidade.
	var walker := _world()
	var before := float(walker.derived_stats(1)["movement_speed_multiplier"])
	walker.equip_item(1, walker._add_equipment_instance(&"sena", "lendario_botas_do_vendaval"))
	walker._passive_cache.clear()
	if float(walker.derived_stats(1)["movement_speed_multiplier"]) < before * 1.6:
		return _fail("Vendaval boots must give at least +60%% move speed")

	# Sino do Fôlego Leve: gemas e o custo por segundo da Saraivada pela metade.
	var plain_cost := _world()
	var bell := _world(["lendario_sino_do_folego_leve"])
	var plain_state := plain_cost.player(1)
	var bell_state := bell.player(1)
	plain_state["breath"] = 100.0
	bell_state["breath"] = 100.0
	plain_cost.use_skill(1, 1, plain_state["position"] as Vector2)
	bell.use_skill(1, 1, bell_state["position"] as Vector2)
	var full_cost := 100.0 - float(plain_state["breath"])
	if full_cost <= 0.0 or not is_equal_approx(100.0 - float(bell_state["breath"]), full_cost * 0.5):
		return _fail("The bell must halve gem costs: %.1f vs %.1f" % [full_cost, 100.0 - float(bell_state["breath"])])
	for sim: WorldSimulation in [plain_cost, bell]:
		var state: Dictionary = sim.player(1)
		(state["cooldowns"] as Array)[0] = 0.0
		sim.use_skill(1, 0, state["position"] as Vector2)
		state["breath"] = 100.0
		sim.step(1.0)
		sim.drain_events()
	if not is_equal_approx(100.0 - float(bell_state["breath"]), (100.0 - float(plain_state["breath"])) * 0.5):
		return _fail("The bell must halve the Saraivada per-second cost")

	# Anel da Corda Infinita: cada volta da Saraivada lança a gema do W, mesmo em recarga.
	var cord := _world(["lendario_anel_da_corda_infinita"])
	var origin := cord.player(1)["position"] as Vector2
	var far := cord.create_enemy(definition, origin + Vector2(450.0, 0.0), 0)
	far["speed"] = 0.0
	far["shield_hits"] = 0
	cord.enemies.append(far)
	(cord.player(1)["cooldowns"] as Array)[1] = 99.0
	var health := float(far["health"])
	_volley_turns(cord, 2)
	if float(far["health"]) >= health or float((cord.player(1)["cooldowns"] as Array)[1]) < 90.0:
		return _fail("Each Saraivada turn must cast the W gem on the nearest enemy, ignoring its cooldown")
	var control := _world()
	var untouched := control.create_enemy(definition, (control.player(1)["position"] as Vector2) + Vector2(450.0, 0.0), 0)
	untouched["speed"] = 0.0
	control.enemies.append(untouched)
	var control_health := float(untouched["health"])
	_volley_turns(control, 2)
	if float(untouched["health"]) < control_health:
		return _fail("Without the ring, arrows must not reach an enemy at 450")

	# Anel do Furor: 1 acúmulo por volta, até 25, por 10 s renovados a cada novo.
	var fury := _world(["lendario_anel_do_furor"])
	var speed_before := float(fury.derived_stats(1)["movement_speed_multiplier"])
	var taken_before := fury._mod(1, "damage_taken_mult")
	var power_before := fury._mod(1, "power_mult")
	_volley_turns(fury, 5)
	var buffs := (fury.player(1)["item_passive"] as Dictionary)["buffs"] as Dictionary
	var stacks := int((buffs.get("furor_do_arqueiro", {}) as Dictionary).get("stacks", 0))
	if stacks < 5 or stacks > 6 or not is_equal_approx(float(buffs["furor_do_arqueiro"]["duration"]), 10.0):
		return _fail("Each turn must add one 10 s stack: %d stacks" % stacks)
	if not is_equal_approx(float(fury.derived_stats(1)["movement_speed_multiplier"]), speed_before * (1.0 + 0.02 * stacks)):
		return _fail("Stacks must add 2%% move speed each")
	if not is_equal_approx(fury._mod(1, "damage_taken_mult"), taken_before * (1.0 - 0.015 * stacks)) or not is_equal_approx(fury._mod(1, "power_mult"), power_before * (1.0 + 0.04 * stacks)):
		return _fail("Stacks must add 4%% damage and cut 1.5%% damage taken each")
	_volley_turns(fury, 30)
	if int((buffs.get("furor_do_arqueiro", {}) as Dictionary).get("stacks", 0)) != 25:
		return _fail("Stacks must cap at 25: %s" % [buffs.get("furor_do_arqueiro", {})])
	# Sem novas voltas, todos os acúmulos somem juntos 10 s depois do último.
	fury.use_skill(1, 0, fury.player(1)["position"] as Vector2)
	for _frame in range(int(10.5 * 60.0)):
		fury.step(1.0 / 60.0)
	if buffs.has("furor_do_arqueiro"):
		return _fail("Stacks must expire 10 s after the last one")
	print("REQUEST_BATCH_596_OK: 2 rings with migration, 2x respawn, 10 min stairs, 10x HP and +50% speed, 4 new legendaries")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
