extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("Weapon test did not complete")
		quit(1)
	)


func _run() -> void:
	assert(WeaponCombat.validation_errors().is_empty())
	var expected := {"eloa":"focus", "sena":"spear", "cira":"gauntlets", "rui":"staff"}
	var sim := Simulation.new()
	sim.setup(9127)
	var peer := 0
	for character: String in expected:
		peer += 1
		sim.add_player(peer, StringName(character))
		var gear := sim.call("_gear", peer) as Dictionary
		var equipment := gear["equipment"] as EquipmentLoadout
		assert(String(equipment.weapon.definition.weapon_type) == expected[character])
		assert(float(sim.weapon_attack_model(peer)["affinity"]) == 115.0)
		var baseline := WeaponCombat.resolve(expected[character], character, {})
		var stats := {}
		for stat: String in baseline["scaling"] as Dictionary:
			stats[StringName(stat)] = 100.0
		assert(float(WeaponCombat.resolve(expected[character], character, stats)["damage"]) > float(baseline["damage"]))
		assert(is_equal_approx(float(baseline["damage"]), float(baseline["power"]) * 1.15))
		for type_id in ["focus", "spear", "gauntlets", "staff"]:
			assert(float(WeaponCombat.resolve(type_id, character, {})["damage"]) > 0.0)
	var factory := BetaItemFactory.new()
	var restored := Simulation.new()
	restored.setup(9127)
	restored.add_player(1, &"eloa")
	assert(restored.load_data(sim.save_data(1), 1))
	for id in range(1, 5):
		if id > 1:
			restored.add_player(id, StringName(expected.keys()[id - 1]))
		assert(restored.weapon_attack_model(id).get("name") == sim.weapon_attack_model(id).get("name"))
	var definition := factory.definition_from_data({"id":"metadata_probe", "slot":"weapon", "weapon_type":"spear", "two_handed":true, "tags":["long"], "incompatibility_tags":["heavy"]})
	assert(definition.two_handed and definition.weapon_type == &"spear")
	assert(&"long" in definition.tags and &"heavy" in definition.incompatibility_tags)
	var inventory := ItemInventory.new(&"tester")
	var loadout := EquipmentLoadout.new()
	var offhand := factory.instance_from_data({"id":"probe_offhand", "slot":"offhand"}, &"offhand", &"tester")
	var two_handed := factory.instance_from_data({"id":"probe_two_handed", "slot":"weapon", "two_handed":true}, &"two_handed", &"tester")
	assert(loadout.equip(offhand))
	assert(inventory.add(two_handed))
	assert(not EquipmentTransaction.equip_from_inventory(inventory, loadout, &"two_handed"))
	assert(inventory.has(&"two_handed"))
	# Probe real automatic attacks against durable targets without enemy movement.
	for character: String in expected:
		var world := Simulation.new()
		world.setup(9127)
		world.add_player(1, StringName(character))
		world.enter_tower(1)
		world.enemies.clear()
		var origin := Vector2(600, 400)
		world.player(1)["position"] = origin
		world.player(1)["target"] = origin
		var profile := world.weapon_attack_model(1)
		var near := minf(80.0, float(profile["range"]) * 0.5)
		for position in [origin + Vector2(near, 0), origin + Vector2(near + 20, 0), origin + Vector2(-80, 0)]:
			var enemy := world.create_enemy({"id":"weapon_probe", "health":10000, "damage":0, "rank_id":"maduro", "allow_affixes":false}, position, world.enemies.size() + 1)
			enemy["health"] = 10000.0
			enemy["shield_hits"] = 0
			enemy["race_trait"] = ""
			world.enemies.append(enemy)
		world.player(1)["attack_timer"] = 0.0
		world.call("_step_player", 1, 0.01)
		assert(float(world.enemies[0]["health"]) < 10000.0)
		assert(float(world.enemies[2]["health"]) == 10000.0)
		assert((float(world.enemies[1]["health"]) < 10000.0) == (character in ["sena", "rui"]))
		assert(is_equal_approx(float(world.player(1)["attack_timer"]), float(profile["interval"])))
		# Pele de Pedra virou resistência da raça (E1 fase 1): calcário resiste 30% a físico.
		world.enemies[0]["resistances"] = {"physical": 0.3}
		world.enemies[0]["vulnerable"] = 0.0
		world.enemies[0]["health"] = 10000.0
		world.damage_enemy(1, 0, 100.0, {"crit_add":-1.0, "damage_type":"physical"})
		var physical := 10000.0 - float(world.enemies[0]["health"])
		world.enemies[0]["health"] = 10000.0
		world.damage_enemy(1, 0, 100.0, {"crit_add":-1.0, "damage_type":"arcane"})
		var arcane := 10000.0 - float(world.enemies[0]["health"])
		assert(is_equal_approx(physical / arcane, 0.7))
	print("WEAPON_COMBAT_OK: distinct starters, attribute scaling, affinities, factory metadata and attack geometry")
	quit(0)
