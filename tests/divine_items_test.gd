extends SceneTree

## Épico E1, fase 5 (G8.9; decisões 600 e 608): itens divinos. Raridade acima de lendário, 12 peças
## com 1 ou 2 linhas de passiva que quebram regras; cada peça sai Magistral, com o afixo fixo do
## encaixe e 7 aleatórios distintos, todos no máximo. Só caem da dificuldade 4 em diante, por sorteio
## individual; a receita de ascensão troca 3 armas únicas da mesma gema e Pólen Lunar por um divino.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Affixes := preload("res://src/gameplay/items/item_affixes.gd")
const Catalog := preload("res://src/gameplay/content/beta_content_catalog.gd")
const ShopMenu := preload("res://src/prototype/village/shop_menu.gd")


func _init() -> void:
	_run.call_deferred()


func _world(level: int = 4, character: StringName = &"eloa") -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(6081)
	sim.add_player(1, character)
	sim.unlocked_difficulty = 5
	sim.set_difficulty(1, level)
	return sim


func _equip(sim: WorldSimulation, item_id: String) -> EquipmentItemInstance:
	var instance_id := sim._add_equipment_instance(sim.player(1)["character_id"] as StringName, item_id, "regular", 50)
	var item := (sim._gear(1)["inventory"] as ItemInventory).items[instance_id] as EquipmentItemInstance
	sim.equip_item(1, instance_id)
	sim._passive_cache.clear()
	return item


func _run() -> void:
	var sim := _world()
	var divines := sim.divine_ids()
	if divines.size() != 12:
		return _fail("The first wave must have 12 divine items")
	var catalog: RefCounted = Catalog.new()
	if catalog.has_method("validate") and not (catalog.call("validate") as Array).is_empty():
		return _fail("The catalog must validate divine passives: %s" % [catalog.call("validate")])
	var styles := {}
	for item_id in divines:
		var data := sim.item_data(item_id)
		var lines := data.get("passives", []) as Array
		if lines.is_empty() or lines.size() > 2 or String(data["tier"]) != "divine":
			return _fail("%s must have 1 or 2 divine passive lines" % item_id)
		styles[String(data.get("style", ""))] = true
	for style in ["eloa", "sena", "cira", "rui", "veneno", "invocacao", "autoataque", "defesa", "elementos"]:
		if not styles.has(style):
			return _fail("A divine item must cover the %s style" % style)

	# Composição: Magistral, afixo fixo do encaixe e 7 aleatórios distintos, todos no máximo.
	var boots := _equip(sim, "divino_botas_da_obra_infinita")
	if String(boots.quality) != "masterwork" or boots.affixes.size() != 8 or String(boots.affixes[0]["id"]) != "velocidade":
		return _fail("Divine boots must be masterwork with movement speed first and 8 affixes: %s" % [boots.affixes])
	var ids := {}
	for affix: Dictionary in boots.affixes:
		var spec := Affixes.POOL[String(affix["id"])] as Dictionary
		var expected := Affixes._round(spec, float(spec["max"]) * float(Affixes.SCALE["divine"]) * Affixes.affix_level_factor(spec, 50))
		if not is_equal_approx(float(affix["value"]), expected) or ids.has(affix["id"]):
			return _fail("Every divine affix must be distinct and at its maximum: %s" % [affix])
		ids[affix["id"]] = true
	if Affixes.sanitize(boots.affixes).size() != 8:
		return _fail("Saves must keep all 8 divine affixes")

	# Regras: Coroa Sem Fim (sem recarga, 5% da Vida por lançamento).
	var crown := _world()
	_equip(crown, "divino_coroa_sem_fim")
	crown.unlock_all_gems(1)
	crown.set_gem_slot(1, 0, "bola_de_fogo")
	crown.enter_tower(1)
	crown.player(1)["breath"] = 999.0
	var health := float(crown.player(1)["health"])
	var target := (crown.player(1)["position"] as Vector2) + Vector2(200.0, 0.0)
	if not crown.use_skill(1, 0, target) or not crown.use_skill(1, 0, target):
		return _fail("The Endless Crown must remove cooldowns")
	if not is_equal_approx(health - float(crown.player(1)["health"]), crown.max_health(1) * 0.1):
		return _fail("Each cast must cost 5%% of max health: %s" % (health - float(crown.player(1)["health"])))
	# Gemas de personagem: Elo Residual salta 6 vezes a mais.
	var chain := _world()
	chain.unlock_all_gems(1)
	chain.set_gem_slot(1, 0, "elo_residual")
	var before := int(chain.resolve_slot(1, 0).get("chain_count", 0))
	_equip(chain, "divino_filamento_do_circuito_eterno")
	if int(chain.resolve_slot(1, 0).get("chain_count", 0)) != before + 6:
		return _fail("The Eternal Circuit must add 6 chains to Elo Residual")
	# Lança das Nove Marés: alterna os elementos e quebra cada um; assume a forma da arma inicial.
	var tides := _world()
	var spear := _equip(tides, "divino_lanca_das_nove_mares")
	if tides.weapon_type_for(1, spear) != "focus":
		return _fail("Divine weapons take the shape of the starter weapon")
	tides.enter_tower(1)
	tides.start_floor(5)
	tides.enemies.clear()
	var dummy := tides.create_enemy(tides.content("enemies")[0], (tides.player(1)["position"] as Vector2) + Vector2(60.0, 0.0), 1)
	dummy["max_health"] = 1.0e9
	dummy["health"] = 1.0e9
	dummy["shield_hits"] = 0
	tides.enemies.append(dummy)
	for hit in range(2):
		tides.damage_enemy(1, 0, 10.0, {"crit_add": -1.0})
	var broken := (dummy.get("breaks", {}) as Dictionary).keys()
	if broken.size() < 2:
		return _fail("Each hit must cycle elements and break them: %s" % [dummy.get("breaks", {})])
	# Égide Imóvel: teto de 10% da Vida por golpe; barreira não expira.
	var shield := _world()
	_equip(shield, "divino_egide_imovel")
	shield.enter_tower(1)
	var full := float(shield.player(1)["health"])
	shield.take_damage(1, 1.0e9)
	if float(shield.player(1)["health"]) < full - shield.max_health(1) * 0.1 - 0.01:
		return _fail("The Unmoving Aegis must cap each hit at 10% of max health")
	shield.player(1)["barrier"] = 20.0
	shield.player(1)["barrier_timer"] = 1.0
	shield._step_barrier(1, 5.0)
	if float(shield.player(1)["barrier"]) <= 0.0:
		return _fail("Barriers must not expire with the Aegis")
	# Peste Eterna: o veneno não acaba.
	var plague := _world()
	_equip(plague, "divino_manto_da_peste_eterna")
	plague.enter_tower(1)
	plague.start_floor(5)
	plague.enemies.clear()
	var sick := plague.create_enemy(plague.content("enemies")[0], Vector2(900.0, 900.0), 1)
	sick["max_health"] = 1.0e9
	sick["health"] = 1.0e9
	sick["poisons"] = {"toxina": {"peer": 1, "remaining": 1.0, "timer": 0.5, "interval": 0.5, "growth": 0.0, "stack": 1.0, "cap": 1.0, "gem_id": "", "base": 1.0, "damage": 1.0}}
	plague.enemies.append(sick)
	plague._step_poisons(3.0)
	if not (sick.get("poisons", {}) as Dictionary).has("toxina"):
		return _fail("Eternal Plague poisons must not expire")

	# Fontes: nunca abaixo da 4; sorteio individual; ascensão.
	var low := _world(3)
	low.enter_tower(1)
	low._roll_divines(1.0, "teste")
	if _count_divines(low) != 0:
		return _fail("Divine items only from difficulty 4")
	var duo := _world(4)
	duo.add_player(2, &"cira")
	duo.enter_tower(1)
	duo.enter_tower(2)
	duo._roll_divines(1.0, "teste")
	if _count_divines(duo, 1) != 1 or _count_divines(duo, 2) != 1:
		return _fail("Each player must roll their own divine")
	var forge := _world(4)
	var npc := forge.village_life.call("find", "dalia_ferral") as Dictionary
	forge.player(1)["position"] = (npc["position"] as Vector2) + Vector2(20.0, 0.0)
	for copy in range(3):
		forge._add_equipment_instance(&"eloa", "unica_elo_residual", "regular", 10)
	if not forge.ascend(1, "elo_residual").is_empty():
		return _fail("Ascension needs Lunar Pollen in the storage")
	forge.banked_loot["polen_lunar"] = 6
	var options := forge.ascension_options(1)
	if options.size() != 1 or not bool(options[0]["ready"]):
		return _fail("The forge must list ready ascensions")
	var made := forge.ascend(1, "elo_residual")
	if made.is_empty() or _count_divines(forge) != 1 or int(forge.banked_loot["polen_lunar"]) != 1 or forge.ascension_options(1).size() != 0:
		return _fail("Ascension must turn 3 uniques and 5 pollen into a divine")
	var shop := ShopMenu.new()
	root.add_child(shop)
	shop.call("open", forge.shop_model(1))
	await process_frame
	if shop.find_child("Ascension", true, false) == null:
		return _fail("The forge window must show the ascension recipe")
	shop.queue_free()
	await process_frame
	print("DIVINE_ITEMS_OK: 12 divines covering every style, masterwork with fixed slot affix and 7 max affixes, rule-breaking lines, difficulty 4 gate, individual rolls and ascension recipe")
	quit(0)


func _count_divines(sim: WorldSimulation, peer_id: int = 1) -> int:
	var total := 0
	for item: EquipmentItemInstance in (sim._gear(peer_id)["inventory"] as ItemInventory).items.values():
		if ItemTier.key(item.tier) == "divine":
			total += 1
	return total


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
