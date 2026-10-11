extends SceneTree

## Decisão 580: todo item lendário (genérico ou arma única) tem uma passiva exclusiva, e o motor
## de passivas executa gatilhos e ações sem cadeias infinitas.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Passives := preload("res://src/gameplay/items/item_passives.gd")


func _init() -> void:
	_run.call_deferred()


func _world(character: StringName, items: Array[String], gems: Array[String] = []) -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5800)
	sim.add_player(1, character)
	sim.unlock_all_gems(1)
	for slot in range(gems.size()):
		sim.set_gem_slot(1, slot, gems[slot])
	for item_id in items:
		sim.equip_item(1, sim._add_equipment_instance(character, item_id, "regular"))
	sim.enter_tower(1)
	var state := sim.player(1)
	state["health"] = sim.max_health(1)
	state["breath"] = 100.0
	# Um alvo resistente e controlado bem na frente da personagem.
	sim.enemies.resize(1)
	var enemy := sim.enemies[0]
	enemy["position"] = (state["position"] as Vector2) + Vector2(60.0, 0.0)
	enemy["health"] = 1.0e6
	enemy["max_health"] = 1.0e6
	enemy["shield_hits"] = 0
	return sim


func _gem_hit(gem_id: String) -> Dictionary:
	return {"gem": true, "gem_id": gem_id, "damage_type": "arcane"}


func _run() -> void:
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var names := {}
	var legendaries := 0
	for item: Dictionary in catalog["items"]:
		if String(item["tier"]) != "legendary":
			continue
		legendaries += 1
		var passive := item.get("passive", {}) as Dictionary
		var problems := Passives.validate(passive)
		if passive.is_empty() or not problems.is_empty():
			return _fail("%s needs a valid exclusive passive: %s" % [item["id"], problems])
		if names.has(passive["name"]):
			return _fail("Passive %s is not exclusive" % passive["name"])
		names[passive["name"]] = true
		var unique_gem := String(item.get("unique_gem", ""))
		for trigger: Dictionary in passive.get("triggers", []):
			if trigger.has("gem") and String(trigger["gem"]) != unique_gem:
				return _fail("%s passive must focus on its own gem" % item["id"])

	# Elemento: a Coroa de Brasa soma +40% às gemas de fogo e só a elas.
	var plain := _world(&"eloa", [], ["bola_de_fogo", "esfera_de_gelo"])
	var crowned := _world(&"eloa", ["lendario_coroa_de_brasa"], ["bola_de_fogo", "esfera_de_gelo"])
	var fire_ratio := crowned._skill_power_multiplier(1, crowned.resolve_slot(1, 0)) / plain._skill_power_multiplier(1, plain.resolve_slot(1, 0))
	var ice_ratio := crowned._skill_power_multiplier(1, crowned.resolve_slot(1, 1)) / plain._skill_power_multiplier(1, plain.resolve_slot(1, 1))
	if not is_equal_approx(fire_ratio * 1.0, 1.4 * _stat_ratio(plain, crowned, "bola_de_fogo")) or ice_ratio > _stat_ratio(plain, crowned, "esfera_de_gelo") + 0.001:
		return _fail("Fire mods must boost fire gems by 40%% only, got fire %.3f ice %.3f" % [fire_ratio, ice_ratio])

	# Queimadura: acerto de fogo acende e o fogo continua causando dano sozinho.
	crowned.damage_enemy(1, 0, 100.0, _gem_hit("bola_de_fogo"))
	var enemy := crowned.enemies[0]
	if float(enemy.get("burn_timer", 0.0)) <= 0.0 or float(enemy.get("burn_dps", 0.0)) <= 0.0:
		return _fail("Fire hit must ignite the target")
	var before_burn := float(enemy["health"])
	for _frame in range(40):
		crowned.step(1.0 / 30.0)
	if float(enemy["health"]) >= before_burn:
		return _fail("Burning must keep damaging the target")

	# Imobilizar (decisão 598): o Anel único prende por completo; chefes sentem metade.
	var frozen := _world(&"eloa", ["unica_anel_de_geada"], ["anel_de_geada"])
	var root_hit := _gem_hit("anel_de_geada")
	root_hit["root"] = true
	frozen.damage_enemy(1, 0, 5.0, root_hit)
	if not is_equal_approx(float(frozen.enemies[0].get("slow_amount", 0.0)), 1.0):
		return _fail("Unique frost ring must fully root")
	frozen.enemies[0]["floor_boss"] = true
	frozen.enemies[0]["slow_timer"] = 0.0
	frozen.enemies[0]["slow_amount"] = 0.0
	frozen.damage_enemy(1, 0, 5.0, root_hit)
	if not is_equal_approx(float(frozen.enemies[0]["slow_amount"]), 0.5):
		return _fail("Bosses feel half of the root")

	# Recusa da Morte: golpe fatal devolve 60% da Vida uma vez; o segundo golpe derruba.
	var immortal := _world(&"cira", ["lendario_coracao_imortal"])
	var state := immortal.player(1)
	immortal.take_damage(1, 1.0e6)
	if immortal.player(1)["zone"] != &"tower" or float(state["health"]) < immortal.max_health(1) * 0.59 or float(state["invulnerable"]) < 2.9:
		return _fail("Immortal heart must revive at 60%% health with invulnerability, health %.0f" % float(state["health"]))
	var revive_status := immortal.player_status_effects(1).filter(func(effect: Dictionary) -> bool: return String(effect["id"]).begins_with("cooldown:"))
	if revive_status.size() != 1 or float(revive_status[0]["duration"]) != 90.0 or String(revive_status[0]["kind"]) != "cooldown":
		return _fail("Revive cooldown must show in the effect strip")
	state["invulnerable"] = 0.0
	immortal.take_damage(1, 1.0e6)
	if immortal.player(1)["zone"] == &"tower":
		return _fail("Revive has a 90 s cooldown")

	# Frenesi: cada abate acumula +8% de potência, até 6 vezes.
	var hunter := _world(&"sena", ["lendario_botas_do_cacador"])
	for kill in range(8):
		hunter.enemies[0]["health"] = 1.0
		hunter.damage_enemy(1, 0, 10.0, _gem_hit("agulha_lastro"))
		hunter.enemies.append({"position": hunter.player(1)["position"] + Vector2(60.0, 0.0), "health": 1.0, "max_health": 1.0})
	if not is_equal_approx(Passives.modifier(hunter, 1, "power_mult"), 1.48):
		return _fail("Hunter frenzy must stack to +48%%, got %.3f" % Passives.modifier(hunter, 1, "power_mult"))
	# Faixa de efeitos (decisão 581): bônus com acúmulos e duração; recarga longa da passiva visível.
	var frenzy := hunter.player_status_effects(1).filter(func(effect: Dictionary) -> bool: return String(effect["id"]) == "buff:frenesi")
	if frenzy.size() != 1 or int(frenzy[0]["stacks"]) != 6 or int(frenzy[0]["max_stacks"]) != 6 or float(frenzy[0]["duration"]) != 6.0 or String(frenzy[0]["kind"]) != "buff":
		return _fail("Frenzy must show as a 6-stack buff with its duration: %s" % [frenzy])
	if not String(PrototypeCombatHud.effect_tooltip(frenzy[0])).contains("6 de 6"):
		return _fail("Buff tooltip must show stacks")

	# Executar: o Fio único abate comuns abaixo de 30% da Vida, mas nunca chefes.
	var executor := _world(&"eloa", ["unica_fio_desintegrador"])
	executor.enemies[0]["health"] = 2.9e5
	executor.damage_enemy(1, 0, 1.0, _gem_hit("fio_desintegrador"))
	if not executor.enemies.is_empty():
		return _fail("Unique beam must execute enemies below 30%")

	# Repetição: cada Mina única agenda mais duas.
	var miner := _world(&"rui", ["unica_mina_de_lastro"], ["mina_de_lastro"])
	var scheduled := miner._scheduled.size()
	if not miner.use_skill(1, 0, miner.enemies[0]["position"]) or miner._scheduled.size() - scheduled != 2:
		return _fail("Unique mine must schedule two extra mines")

	# Recarga: a Ampulheta adianta todas as gemas a cada abate.
	var hourglass := _world(&"eloa", ["lendario_ampulheta_partida"], ["elo_residual"])
	(hourglass.player(1)["cooldowns"] as Array[float])[0] = 3.0
	hourglass.enemies[0]["health"] = 1.0
	hourglass.damage_enemy(1, 0, 10.0, _gem_hit("elo_residual"))
	if not is_equal_approx((hourglass.player(1)["cooldowns"] as Array[float])[0], 2.65):
		return _fail("Hourglass kill must refund 0.35 s on every gem")

	# Gatilho Ancestral: o quarto autoataque dispara a gema de Q de graça.
	var trigger := _world(&"eloa", ["lendario_gatilho_ancestral"], ["elo_residual"])
	trigger.drain_events()
	for hit in range(4):
		trigger.damage_enemy(1, 0, 5.0, {"damage_type": "arcane"})
	var casts := trigger.drain_events().filter(func(event: Dictionary) -> bool: return String(event.get("call", "")) == "cast").size()
	if casts != 1:
		return _fail("Every 4th auto attack must cast the Q gem, got %d casts" % casts)

	# Intervalo: o Molde único se invoca sozinho em combate.
	var matrix := _world(&"rui", ["unica_molde_vigilante"])
	var summons_before := matrix.persistent_effects.size()
	for _frame in range(30):
		matrix.step(1.0 / 30.0)
	if matrix.persistent_effects.size() <= summons_before:
		return _fail("Unique mold must summon on its own")

	# Sem cadeias infinitas: o Elo Infinito abate em sequência, mas o dano da passiva não realimenta.
	var chain := _world(&"eloa", ["unica_elo_residual"], ["elo_residual"])
	for index in range(12):
		chain.enemies.append({"position": chain.player(1)["position"] + Vector2(40.0 + index * 25.0, 20.0), "health": 1.0, "max_health": 1.0})
	chain.enemies[0]["health"] = 1.0
	chain.damage_enemy(1, 0, 10.0, _gem_hit("elo_residual"))
	if chain._damage_depth != 0 or not chain._passive_events.is_empty():
		return _fail("Passive event queue must drain after a hit")

	print("ITEM_PASSIVES_OK: %d legendary items with exclusive passives; burn, freeze, revive, stacks, execute, recast, refund, auto trigger, interval and bounded chains" % legendaries)
	quit(0)


## Razão que só vem dos atributos do item (a Coroa também dá Inteligência e Sabedoria).
func _stat_ratio(plain: WorldSimulation, crowned: WorldSimulation, gem_id: String) -> float:
	var model := {"gem_id": gem_id, "tags": []}
	var base_plain := plain._skill_power_multiplier(1, model) / plain._mod(1, "power_fire_mult" if gem_id == "bola_de_fogo" else "power_ice_mult")
	var base_crowned := crowned._skill_power_multiplier(1, model) / crowned._mod(1, "power_fire_mult" if gem_id == "bola_de_fogo" else "power_ice_mult")
	return base_crowned / base_plain


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
