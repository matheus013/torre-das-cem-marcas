extends SceneTree

## Épico E1, fase 3 (G8.1 e G8.2; decisão 605): relógio do mundo de 2 h (manhã 30, tarde 30,
## entardecer 20, noite 40) com avisos, Lua da Cicatriz a cada 3 noites, bônus da noite (EXP +25%,
## saque +30%, inimigos +10%), luz como atributo, inimigos fora da luz fora do ataque automático,
## variantes noturnas por bioma (sombra que salta, bebe-luz), elites caçadores, Coletor de Âmbar da
## manhã, materiais por horário, vila dirigida pelo relógio, snapshot, menu e save.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const WorldClock := preload("res://src/gameplay/world/world_clock.gd")


func _init() -> void:
	_run.call_deferred()


func _world() -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(6051)
	sim.add_player(1, &"sena")
	return sim


func _run() -> void:
	# Relógio: 2 h por dia, períodos na ordem, avisos antes da noite e do dia.
	var clock := WorldClock.new()
	if clock.period() != "manha" or clock.day != 1 or not is_equal_approx(WorldClock.DAY_SECONDS, 7200.0):
		return _fail("The world starts on day 1 in the morning, with 2-hour days")
	var seen: Array[String] = []
	var warnings: Array[String] = []
	for second in range(int(WorldClock.DAY_SECONDS) + 1):
		for event: Dictionary in clock.step(1.0):
			if String(event["type"]) == "period":
				seen.append(String(event["period"]))
			else:
				warnings.append(String(event["period"]))
	if seen != ["tarde", "entardecer", "noite", "manha"] or warnings != ["noite", "manha"] or clock.day != 2:
		return _fail("One day must run morning > afternoon > dusk > night with warnings: %s %s day %d" % [seen, warnings, clock.day])
	clock.day = 3
	clock.set_period("noite")
	if not clock.is_scar_moon() or not is_equal_approx(float(clock.bonuses()["exp"]), 1.5):
		return _fail("Every third night is a Scar Moon with doubled bonuses")
	clock.day = 4
	if clock.is_scar_moon() or not is_equal_approx(float(clock.bonuses()["loot"]), 1.3):
		return _fail("Ordinary nights give +30% loot")
	if not WorldClock.describe(clock.view()).contains("NOITE"):
		return _fail("The clock text must show the period")

	# Vila: o relógio dirige a rotina; voltar da Torre não muda mais o período.
	var sim := _world()
	sim.clock.call("set_period", "tarde")
	sim.step(0.1)
	sim.dev_advance_period()
	if String(sim.village_life.call("period")) != "entardecer":
		return _fail("The village period must follow the clock")
	sim.enter_tower(1)
	sim.leave_tower(1)
	if String(sim.village_life.call("period")) != "entardecer":
		return _fail("Returning from the Tower must not advance the period anymore")

	# EXP e Vida dos inimigos à noite.
	var day_exp := _exp_for_kill(false)
	var night_exp := _exp_for_kill(true)
	if day_exp != 12 or night_exp != 15:
		return _fail("Night must give +25%% EXP (%d -> %d)" % [day_exp, night_exp])
	var day_sim := _world()
	day_sim.clock.call("set_period", "tarde")
	day_sim.enter_tower(1)
	day_sim.start_floor(5)
	var night_sim := _world()
	night_sim.clock.call("set_period", "noite")
	night_sim.enter_tower(1)
	night_sim.start_floor(5)
	var definition := day_sim.content("enemies").filter(func(item: Dictionary) -> bool: return String(item["id"]) == "larva_de_junta")[0] as Dictionary
	var day_enemy := day_sim._spawn_floor_enemy(definition, Vector2(500.0, 500.0), 3)
	var night_enemy := night_sim._spawn_floor_enemy(definition, Vector2(500.0, 500.0), 3)
	if not is_equal_approx(float(night_enemy["max_health"]) / float(day_enemy["max_health"]), 1.1) or not is_equal_approx(float(night_enemy["damage"]) / float(day_enemy["damage"]), 1.1):
		return _fail("Night enemies must have +10% health and damage")

	# Monstros de horário: variantes noturnas do bioma na população da noite e nenhuma de dia.
	if day_sim.enemies.any(func(enemy: Dictionary) -> bool: return not String(enemy.get("time_of_day", "")).is_empty()):
		return _fail("Afternoon floors must have no time-of-day monsters")
	var night_variants := night_sim.enemies.filter(func(enemy: Dictionary) -> bool: return String(enemy.get("time_of_day", "")) == "night")
	if night_variants.is_empty() or String(night_variants[0]["definition_id"]) != "sombra_de_lastro":
		return _fail("Night floors must spawn the biome night variant")
	# Amanhecer: as variantes se recolhem e chegam os Coletores de Âmbar.
	night_sim.dev_advance_period()
	if night_sim.enemies.any(func(enemy: Dictionary) -> bool: return String(enemy.get("time_of_day", "")) == "night"):
		return _fail("Night variants must retreat at dawn")
	var collectors := night_sim.enemies.filter(func(enemy: Dictionary) -> bool: return String(enemy.get("definition_id", "")) == "coletor_de_ambar")
	if collectors.size() != night_sim.DAWN_COLLECTORS:
		return _fail("Dawn must bring the Amber Collectors")
	# O Coletor foge e nunca fere.
	var collector := collectors[0] as Dictionary
	night_sim.enemies.clear()
	night_sim.enemies.append(collector)
	night_sim.player(1)["position"] = (collector["position"] as Vector2) + Vector2(150.0, 0.0)
	var start_distance := (collector["position"] as Vector2).distance_to(night_sim.player(1)["position"] as Vector2)
	var health := float(night_sim.player(1)["health"])
	for frame in range(20):
		night_sim._update_enemies(0.1)
	if (collector["position"] as Vector2).distance_to(night_sim.player(1)["position"] as Vector2) <= start_distance or float(night_sim.player(1)["health"]) < health:
		return _fail("The Amber Collector must flee and never attack")
	var amber := night_sim._find(night_sim.content("loot_tables"), "saque_coletor_de_ambar")
	if (amber.get("entries", []) as Array).is_empty() or String(amber["entries"][0]["item_id"]) != "ambar_solar":
		return _fail("The Amber Collector must drop Solar Amber")

	# Luz: de noite só o que está na luz entra no ataque automático; de dia, tudo.
	var dark := _world()
	dark.clock.call("set_period", "noite")
	dark.enter_tower(1)
	dark.start_floor(5)
	dark.enemies.clear()
	var me := dark.player(1)["position"] as Vector2
	var far := dark.create_enemy(definition, me + Vector2(dark.LIGHT_RADIUS + 60.0, 0.0), 1)
	dark.enemies.append(far)
	if dark.enemy_lit(far) or dark.nearest_lit_enemy_to(me, 2000.0) >= 0 or dark.nearest_enemy_to(me, 2000.0) != 0:
		return _fail("Out of the light, enemies must leave auto-attack targeting")
	var view_enemy := (dark.view_snapshot()["enemies"] as Array)[0] as Dictionary
	if bool(view_enemy["lit"]) or not (dark.view_snapshot()["clock"] as Dictionary).get("night", false):
		return _fail("The snapshot must carry the clock and the lit flag")
	far["position"] = me + Vector2(dark.LIGHT_RADIUS - 20.0, 0.0)
	dark._light_radii.clear()
	if not dark.enemy_lit(far) or dark.nearest_lit_enemy_to(me, 2000.0) != 0:
		return _fail("Enemies inside the light must be targetable")
	# Gemas sagradas iluminam mais; o afixo "raio de luz" também.
	dark.player(1)["holy_light_timer"] = 3.0
	dark._light_radii.clear()
	if not is_equal_approx(dark.light_radius(1), dark.LIGHT_RADIUS * dark.HOLY_LIGHT_MULT):
		return _fail("Holy gems must widen the light")
	dark.player(1)["holy_light_timer"] = 0.0
	var ring_id := dark._add_equipment_instance(&"sena", "anel_de_precisao", "refined", 10)
	var ring := (dark._gear(1)["inventory"] as ItemInventory).items[ring_id] as EquipmentItemInstance
	ring.affixes = [{"id": "luz", "value": 0.2}]
	dark.equip_item(1, ring_id)
	dark._passive_cache.clear()
	dark._light_radii.clear()
	if not is_equal_approx(dark.light_radius(1), dark.LIGHT_RADIUS * 1.2):
		return _fail("The light radius affix must widen the light: %s" % dark.light_radius(1))
	# Bebe-luz por perto corta a luz pela metade.
	var eater_definition := dark.content("enemies").filter(func(item: Dictionary) -> bool: return String(item.get("mechanic", "")) == "light_eater")[0] as Dictionary
	dark.enemies.append(dark.create_enemy(eater_definition, me + Vector2(0.0, 100.0), 2))
	dark._light_radii.clear()
	if not is_equal_approx(dark.light_radius(1), dark.LIGHT_RADIUS * 1.2 * dark.LIGHT_EATER_FACTOR):
		return _fail("Light eaters must halve the light nearby")
	# De dia tudo está iluminado.
	dark.clock.call("set_period", "tarde")
	if not dark.enemy_lit(far):
		return _fail("By day every enemy is lit")

	# Sombra de Lastro reaparece atrás de quem persegue.
	var blink := _world()
	blink.clock.call("set_period", "noite")
	blink.enter_tower(1)
	blink.start_floor(5)
	blink.enemies.clear()
	var hunter_spot := blink.player(1)["position"] as Vector2
	blink.player(1)["facing_direction"] = Vector2.RIGHT
	var shadow_definition := blink.content("enemies").filter(func(item: Dictionary) -> bool: return String(item["id"]) == "sombra_de_lastro")[0] as Dictionary
	var shadow := blink.create_enemy(shadow_definition, hunter_spot + Vector2(300.0, 0.0), 3)
	shadow["action_timer"] = 0.0
	blink.enemies.append(shadow)
	blink._update_enemies(0.05)
	if (shadow["position"] as Vector2).distance_to(hunter_spot + Vector2(-blink.BLINK_BEHIND, 0.0)) > 1.0:
		return _fail("The shadow must reappear behind its target: %s" % shadow["position"])

	# Elites caçadores: à noite percebem de mais longe.
	var elite_definition := blink.content("enemies").filter(func(item: Dictionary) -> bool: return String(item.get("encounter_class", "")) == "elite")[0] as Dictionary
	for period in ["tarde", "noite"]:
		var hunt := _world()
		hunt.clock.call("set_period", period)
		hunt.enter_tower(1)
		hunt.start_floor(5)
		hunt.enemies.clear()
		var elite := hunt.create_enemy(elite_definition, (hunt.player(1)["position"] as Vector2) + Vector2(hunt.AGGRO_RADIUS + 200.0, 0.0), 4)
		elite["home"] = elite["position"]
		hunt.enemies.append(elite)
		hunt._update_enemies(0.05)
		if bool(elite["chasing"]) != (period == "noite"):
			return _fail("Elites must hunt from farther away only at night (%s)" % period)

	# Materiais da noite: Orvalho Negro nos abates; nada de dia.
	var dew := 0
	var loot := _world()
	loot.clock.call("set_period", "noite")
	for kill in range(200):
		loot.loot_kill_sequence = kill
		dew += loot._night_drops({"encounter_class": "common"}).size()
	loot.clock.call("set_period", "manha")
	if dew == 0 or not loot._night_drops({"encounter_class": "elite"}).is_empty():
		return _fail("Black Dew must drop only at night")
	for material in ["orvalho_negro", "polen_lunar", "ambar_solar"]:
		if loot.item_data(material).is_empty():
			return _fail("Time-of-day material %s must exist" % material)

	# Save e menu.
	var saved := _world()
	saved.clock.set("day", 3)
	saved.clock.call("set_period", "noite")
	var restored := _world()
	if not restored.load_data(saved.save_data(1), 1) or not bool(restored.clock.call("is_scar_moon")) or String(restored.village_life.call("period")) != "noite":
		return _fail("The clock must survive save and load")
	if not (restored.menu_model(1).get("clock", {}) as Dictionary).get("scar_moon", false):
		return _fail("The tower map must show the clock")
	print("DAY_NIGHT_OK: 2-hour clock, warnings, Scar Moon, night bonuses, light and targeting, night variants, hunters, Amber Collector, time materials, village routine, snapshot, menu and save")
	quit(0)


func _exp_for_kill(night: bool) -> int:
	var sim := _world()
	sim.clock.call("set_period", "noite" if night else "tarde")
	var before := int(sim.character_experience.get("sena", 0))
	sim._grant_experience(1, {"encounter_class": "common"})
	return int(sim.character_experience.get("sena", 0)) - before


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
