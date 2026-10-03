extends SceneTree

const PassiveScript := preload("res://src/gameplay/passives/passive_runtime.gd")


func _init() -> void:
	var eloa: RefCounted = PassiveScript.new()
	eloa.call("setup", &"luz_residual", "Luz Residual")
	for index in range(5):
		eloa.call("on_enemy_hit", Vector2(index * 10, 0), false)
	if int(eloa.call("residue_count")) != 3:
		_fail("Luz Residual must keep at most three residues")
		return
	var conducted: Dictionary = eloa.call("on_skill_used", 0)
	var conduct_requests: Array = conducted["requests"]
	if conduct_requests.size() != 1 or (conduct_requests[0]["origins"] as Array).size() != 3 or int(eloa.call("residue_count")) != 0:
		_fail("Using a gem must conduct and consume every residue")
		return
	eloa.call("on_enemy_hit", Vector2.ZERO, false)
	eloa.call("tick", 5.0)
	if int(eloa.call("residue_count")) != 0:
		_fail("Residues must expire")
		return

	var sena: RefCounted = PassiveScript.new()
	sena.call("setup", &"duas_correntes", "Duas Correntes")
	sena.call("on_skill_used", 0)
	var repeated: Dictionary = sena.call("on_skill_used", 0)
	if not is_equal_approx(float(repeated["power_multiplier"]), 1.12):
		_fail("Repeating a planned action must build Tracado")
		return
	sena.call("on_skill_used", 1)
	sena.call("on_skill_used", 2)
	if sena.call("currents") != Vector2i(0, 2) or float(sena.call("move_speed_multiplier")) <= 1.0:
		_fail("Improvising must build Desvio and reduce Tracado")
		return

	var cira: RefCounted = PassiveScript.new()
	cira.call("setup", &"placas_adaptativas", "Placas Adaptativas")
	cira.call("on_damage_taken", 20.0)
	var coated: Dictionary = cira.call("on_damage_taken", 20.0)
	if not bool(cira.call("has_sample")) or not is_equal_approx(float(coated["amount"]), 17.0):
		_fail("A stored sample must coat Cira against the next hit")
		return
	var infused: Dictionary = cira.call("on_skill_used", 0)
	if not is_equal_approx(float(infused["power_multiplier"]), 1.35) or bool(cira.call("has_sample")):
		_fail("The next gem must consume the sample for extra power")
		return
	var overload: Dictionary = cira.call("on_damage_taken", 200.0)
	if (overload["requests"] as Array).is_empty() or float(cira.call("instability")) != 0.0:
		_fail("Maximum instability must discharge in an area")
		return

	var rui: RefCounted = PassiveScript.new()
	rui.call("setup", &"oportunidade_estrutural", "Oportunidade Estrutural")
	rui.call("on_enemy_hit", Vector2(100, 100), true)
	for index in range(4):
		rui.call("on_enemy_hit", Vector2(300, 300), false)
	if int(rui.call("opportunity_count")) != 2:
		_fail("Obstacles and every fourth hit must reveal opportunities")
		return
	var pickup: Array = rui.call("on_player_moved", Vector2(104, 100))
	if pickup.size() != 2 or int(rui.call("opportunity_count")) != 1:
		_fail("Stepping on an opportunity must convert it into cover and impact")
		return
	print("PASSIVE_RUNTIME_OK: residues, two currents, adaptive plates and structural opportunities")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
