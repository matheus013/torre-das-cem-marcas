extends SceneTree

## G0.6 (épico E1, fase 0): o host valida todo comando antes da simulação. Vetores não finitos ou
## fora do mundo, textos enormes, tipos estranhos e índices fora de faixa são descartados, e cada
## jogador remoto tem limite de comandos por segundo. Comandos legítimos seguem funcionando.

const Guard := preload("res://src/core/net/intent_guard.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# Argumentos.
	var nan := Vector2(NAN, 0.0)
	var cases := [[[nan], false], [[Vector2(INF, 1.0)], false], [[Vector2(1.0e7, 0.0)], false], [["x".repeat(65)], false],
		[[1, 2, 3, 4, 5], false], [[{}], false], [[10000000], false], [[Vector2(120.0, -40.0), 2, "elo_residual", true], true]]
	for case: Array in cases:
		if Guard.valid_args(case[0]) != case[1]:
			return _fail("valid_args(%s) must be %s" % [case[0], case[1]])

	# Frequência: rajada de até 1 s por tipo, depois recarrega com o tempo.
	var guard := Guard.new()
	var allowed := 0
	for _attempt in range(100):
		allowed += int(guard.allow(2, "skill", 10.0))
	if allowed != 20 or guard.allow(2, "skill", 10.0):
		return _fail("Skills must be limited to a 20-command burst, got %d" % allowed)
	if not guard.allow(2, "skill", 10.5) or not guard.allow(3, "skill", 10.0):
		return _fail("The bucket must refill with time and be per player")

	# Integração no host: um cliente (peer 2) mandando lixo e inundando comandos.
	var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	var sim: RefCounted = village.get("_sim")
	sim.call("add_player", 2, &"sena")
	sim.call("enter_tower", 1)
	sim.call("enter_tower", 2)
	var remote := sim.call("player", 2) as Dictionary
	var start_floor := int(sim.get("tower_start_floor"))
	village.call("_apply_intent", 2, "attack", [nan])
	village.call("_apply_intent", 2, "skill", [0, Vector2(INF, 0.0)])
	village.call("_apply_intent", 2, "start_floor", [999])
	village.call("_apply_intent", 2, "unequip", [-3, 99])
	village.call("_apply_intent", 2, "talk", ["x".repeat(500)])
	if float(remote["attack_request_timer"]) > 0.0 or int(sim.get("tower_start_floor")) != start_floor or not (remote["position"] as Vector2).is_finite():
		return _fail("Invalid client commands must not touch the simulation")
	sim.call("set_move_target", 2, nan)
	if not (remote["target"] as Vector2).is_finite():
		return _fail("A non-finite move target must be ignored")

	# Inundação: 200 vendas do cliente no mesmo instante passam no máximo uma rajada (15).
	var gear := sim.call("_gear", 2) as Dictionary
	var inventory := gear["inventory"] as ItemInventory
	var ids: Array[StringName] = []
	for _copy in range(40):
		ids.append(sim.call("_add_equipment_instance", &"sena", "anel_de_folego") as StringName)
	var before := inventory.items.size()
	var started := Time.get_ticks_msec() / 1000.0
	for index in range(200):
		village.call("_apply_intent", 2, "sell", [String(ids[index % ids.size()])])
	var elapsed := Time.get_ticks_msec() / 1000.0 - started
	var sold := before - inventory.items.size()
	# Rajada de 15 mais 15 por segundo do tempo que a inundação levou.
	if sold < 1 or float(sold) > 15.0 + elapsed * 15.0 + 1.0:
		return _fail("A flooding client must be rate limited: %d sales in %.2f s" % [sold, elapsed])

	# Comandos legítimos seguem valendo; o host local não tem limite.
	village.call("_apply_intent", 2, "attack", [(remote["position"] as Vector2) + Vector2(100.0, 0.0)])
	if float(remote["attack_request_timer"]) <= 0.0:
		return _fail("A valid client attack must still work")
	var host_gear := sim.call("_gear", 1) as Dictionary
	var host_inventory := host_gear["inventory"] as ItemInventory
	var host_ids: Array[StringName] = []
	for _copy in range(30):
		host_ids.append(sim.call("_add_equipment_instance", &"eloa", "anel_de_folego") as StringName)
	for instance_id in host_ids:
		village.call("_apply_intent", 1, "sell", [String(instance_id)])
	if host_ids.any(func(instance_id: StringName) -> bool: return host_inventory.has(instance_id)):
		return _fail("The local host must not be rate limited")
	village.queue_free()
	await process_frame
	print("HOST_INTENT_GUARD_OK: sane arguments, ranges, finite vectors and per-client rate limits")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
