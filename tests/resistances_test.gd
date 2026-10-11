extends SceneTree

## Épico E1, fase 1 (G8.3 e G8.13): resistências por raça e bioma (-50% a +75%), penetração só sobre
## resistência positiva, Quebra elemental com duração, Adaptação ao tipo dominante, resistência da
## personagem por afixos até 75%, dano inimigo com tipo, números de dano resistido e de fraqueza,
## leitura no bestiário e nos status, e números grandes abreviados.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Res := preload("res://src/gameplay/combat/resistances.gd")
const Format := preload("res://src/core/text/number_format.gd")


func _init() -> void:
	_run.call_deferred()


func _world() -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5872)
	sim.add_player(1, &"cira")
	sim.set("deepest_floor", 3)
	sim.set("tower_start_floor", 3)
	sim.enter_tower(1)
	sim.enemies.clear()
	for item: EquipmentItemInstance in (sim._gear(1)["equipment"] as EquipmentLoadout)._all_items():
		item.affixes = []
	sim._passive_cache.clear()
	return sim


func _calcario(sim: WorldSimulation) -> Dictionary:
	var enemy := sim.create_enemy({"id": "teste_calcario", "race_id": "calcario", "rank_id": "", "health": 100.0}, (sim.player(1)["position"] as Vector2) + Vector2(80.0, 0.0), 0)
	enemy["health"] = 1.0e9
	enemy["max_health"] = 1.0e9
	enemy["shield_hits"] = 0
	enemy["modifier_mechanics"] = []
	sim.enemies.append(enemy)
	return enemy


func _damage(sim: WorldSimulation, hit: Dictionary) -> float:
	var enemy := sim.enemies[0]
	var before := float(enemy["health"])
	enemy["vulnerable_amount"] = 0.0
	enemy["vulnerable_timer"] = 0.0
	hit["crit_add"] = -1.0
	sim.damage_enemy(1, 0, 100.0, hit)
	return before - float(enemy["health"])


func _equip_affix(sim: WorldSimulation, affix: String, value: float) -> void:
	var instance := sim._add_equipment_instance(&"cira", "anel_de_folego")
	var item := (sim._gear(1)["inventory"] as ItemInventory).get_item(instance)
	item.affixes = [{"id": affix, "value": value}]
	sim.equip_item(1, instance)
	sim._passive_cache.clear()


func _run() -> void:
	# Tabela: raça + bioma (Galerias soma Terra +10%), limitada à faixa.
	var profile := Res.enemy_profile("calcario", "galerias", 0.0)
	if not is_equal_approx(float(profile["physical"]), 0.3) or not is_equal_approx(float(profile["earth"]), 0.4) or not is_equal_approx(float(profile["acid"]), -0.25):
		return _fail("Calcario in the galleries must resist physical 30%%, earth 40%% and be weak to acid: %s" % [profile])
	if not is_equal_approx(float(Res.enemy_profile("carregado", "ermo", 0.5)["lightning"]), Res.MAXIMUM):
		return _fail("Resistances must cap at 75%")
	if not is_equal_approx(Res.after_penetration(0.3, 0.5), 0.0) or not is_equal_approx(Res.after_penetration(-0.25, 0.5), -0.25):
		return _fail("Penetration only removes positive resistance")

	# Dano real: físico resistido, ácido na fraqueza.
	var sim := _world()
	var enemy := _calcario(sim)
	if not (enemy["resistances"] as Dictionary).has("physical") or String(enemy["damage_type"]) != "earth":
		return _fail("Enemies must carry their resistance profile and damage type")
	var physical := _damage(sim, {"damage_type": "physical"})
	var acid := _damage(sim, {"gem": true, "gem_id": "bolha_corrosiva", "damage_type": "arcane"})
	if not is_equal_approx(physical, 70.0) or not is_equal_approx(acid, 125.0):
		return _fail("Physical must deal 70 and acid 125 against calcario, got %.1f and %.1f" % [physical, acid])
	var numbers := sim.drain_events().filter(func(event: Dictionary) -> bool: return String(event.get("call", "")) == "number")
	if numbers.is_empty() or String((numbers[-1]["args"] as Array)[3]) != "weak":
		return _fail("Weakness hits must use the weak number style")

	# Penetração de 10%: físico 30% vira 20%.
	var pierce := _world()
	_calcario(pierce)
	_equip_affix(pierce, "penetracao", 0.1)
	if not is_equal_approx(_damage(pierce, {"damage_type": "physical"}), 80.0):
		return _fail("10% penetration must lower physical resistance to 20%")

	# Quebra elemental: -30% de terra por 2 s, depois volta.
	var shatter := _world()
	var stone := _calcario(shatter)
	Res.apply_break(stone, "earth", 0.3, 2.0)
	if not is_equal_approx(_damage(shatter, {"element": "earth", "damage_type": "physical"}), 90.0):
		return _fail("An elemental break must lower resistance while active")
	for _frame in range(150):
		shatter.step(1.0 / 60.0)
	if not is_equal_approx(_damage(shatter, {"element": "earth", "damage_type": "physical"}), 60.0):
		return _fail("The break must expire")

	# Adaptação: o tipo que mais feriu ganha +30%.
	var adapt := _world()
	var learner := _calcario(adapt)
	learner["adaptive"] = true
	_damage(adapt, {"element": "fire"})
	if not is_equal_approx(_damage(adapt, {"element": "fire"}), 70.0):
		return _fail("Adaptive enemies must resist the element that hurt them most")

	# Personagem: resistência por afixo, teto de 75%, dano inimigo tipado.
	var tank := _world()
	tank.player(1)["health"] = 1.0e6
	_equip_affix(tank, "resistencia_terra", 1.0)
	tank.player(1)["barrier"] = 0.0
	var before := float(tank.player(1)["health"])
	tank.take_damage(1, 100.0, "earth")
	var earth_loss := before - float(tank.player(1)["health"])
	tank.player(1)["barrier"] = 0.0
	before = float(tank.player(1)["health"])
	tank.take_damage(1, 100.0, "fire")
	var fire_loss := before - float(tank.player(1)["health"])
	# A resistência entra antes da defesa e da passiva da personagem (que têm parte fixa), então a
	# conferência exata é no valor da resistência; no dano, terra precisa doer bem menos que fogo.
	if not is_equal_approx(tank.player_resistance(1, "earth"), 0.75) or not is_zero_approx(tank.player_resistance(1, "fire")) or earth_loss >= fire_loss * 0.35:
		return _fail("Player resistance must cap at 75%%: %.2f vs %.2f" % [earth_loss, fire_loss])
	if not String(tank.detailed_stats(1)["combat"].filter(func(row: Array) -> bool: return String(row[0]) == "Resistencias")[0][1]).contains("Terra 75%"):
		return _fail("Detailed stats must list player resistances")

	# Bestiário: resistências e fraquezas da raça e do bioma.
	var book := _world()
	var calcario_entry := {}
	for record in book._bestiary_catalog():
		if String((record["definition"] as Dictionary).get("race_id", "")) == "calcario":
			calcario_entry = record
			break
	if not calcario_entry.is_empty():
		var sections := book._bestiary_sections(calcario_entry["definition"], calcario_entry["boss"], calcario_entry["biome"], {"kills": 99}, 3)
		var rows: Array = sections[2]["rows"]
		var text := " ".join(rows.map(func(row: Array) -> String: return "%s:%s" % [row[0], row[1]]))
		if not text.contains("Fisico +") or not text.contains("Fraquezas:Acido"):
			return _fail("Bestiary must show resistances and weaknesses: %s" % text)

	# Números grandes.
	for case: Array in [[1234.0, "1234"], [12400.0, "12,4 mil"], [3.2e6, "3,2 mi"], [1.7e9, "1,7 bi"], [2.0e12, "2 tri"]]:
		if Format.short(float(case[0])) != String(case[1]):
			return _fail("NumberFormat.short(%s) must be %s, got %s" % [case[0], case[1], Format.short(float(case[0]))])

	print("RESISTANCES_OK: race and biome profiles, penetration, breaks, adaptation, capped player resistance, typed enemy damage, readouts and big numbers")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
