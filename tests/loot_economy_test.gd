extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(808)
	sim.add_player(1, &"eloa")
	var model := sim.menu_model(1)
	if int(model["silver"]) != 120:
		return _fail("Characters start with 120 P")

	# Venda manual: preço por raridade e fabricação; peça equipada não é vendida.
	var ring := sim._add_equipment_instance(&"eloa", "anel_de_area", "refined")
	var price := int(round(45.0 * 1.15))
	if sim.sell_item(1, ring) != price or int(sim.menu_model(1)["silver"]) != 120 + price:
		return _fail("Rare refined ring must sell for %d P" % price)
	var equipped := sim._add_equipment_instance(&"eloa", "anel_de_precisao", "regular")
	sim.equip_item(1, equipped)
	if sim.sell_item(1, equipped) != 0:
		return _fail("Equipped items must not be sold")

	# Filtro: equipamento abaixo do limite vira prata ao entrar no raio de coleta (2026-10-12: antes
	# ficava no chão para sempre e acumulava); material é recolhido.
	if not sim.set_loot_filter(1, "rare") or sim.set_loot_filter(1, "legendary"):
		return _fail("Loot filter accepts common..epic only")
	sim.enter_tower(1)
	var spot := sim.player(1)["position"] as Vector2
	(sim.get("ground_items") as Array).clear()
	sim.drop_item(&"tower", spot, "botas_de_rota_antiga", 1, "regular")
	sim.drop_item(&"tower", spot + Vector2(4.0, 0.0), "musgo_de_orientacao", 2)
	var silver_before := int(sim._gear(1)["silver"])
	sim._collect_ground_items(1)
	var left := sim.get("ground_items") as Array
	if not left.is_empty() or int(sim._gear(1)["silver"]) <= silver_before or int((sim.player(1)["carried_loot"] as Dictionary).get("musgo_de_orientacao", 0)) != 2:
		return _fail("Filtered equipment must turn into silver while materials are collected")

	# Autovenda ao voltar: abaixo de raro vende incomum; raro e arma única ficam.
	if not sim.set_auto_sell(1, "rare") or sim.set_auto_sell(1, "legendary"):
		return _fail("Auto-sell accepts off, uncommon, rare or epic")
	var cheap := sim._add_equipment_instance(&"eloa", "luvas_de_junta", "regular")
	var keep := sim._add_equipment_instance(&"eloa", "anel_de_partilha", "regular")
	var unique := sim._add_equipment_instance(&"eloa", "unica_agulha_lastro", "improvised")
	var before := int(sim.menu_model(1)["silver"])
	# Esperado: toda peça não equipada abaixo de raro (inclui o kit inicial guardado), exceto únicas.
	var expected_count := 0
	var expected_silver := 0
	var gear := sim._gear(1)
	for raw_id: Variant in (gear["inventory"] as ItemInventory).items:
		var item := (gear["inventory"] as ItemInventory).items[raw_id] as EquipmentItemInstance
		if int(item.tier) < int(ItemTier.Value.RARE) and not sim._is_equipped(gear, item) and not String(item.definition.id).begins_with("unica_"):
			expected_count += 1
			expected_silver += sim.item_sell_price(item)
	sim.leave_tower(1)
	var inventory := sim._gear(1)["inventory"] as ItemInventory
	if inventory.has(cheap) or not inventory.has(keep) or not inventory.has(unique):
		return _fail("Auto-sell must sell only items below the limit and spare unique weapons")
	var report := ""
	for event: Dictionary in sim.drain_events():
		if String(event.get("type", "")) == "status":
			report = String(event.get("text", ""))
	var summary := "Autovenda: %d %s por %d P" % [expected_count, "peca" if expected_count == 1 else "pecas", expected_silver]
	if expected_count < 1 or int(sim.menu_model(1)["silver"]) != before + expected_silver or not report.contains(summary):
		return _fail("Auto-sell must pay and report the sale: " + report)

	# Persistência da bolsa e das preferências.
	var saved := sim.save_data(1)
	var restored := Simulation.new()
	restored.setup(808)
	restored.add_player(1, &"eloa")
	if not restored.load_data(saved, 1):
		return _fail("Save could not be loaded")
	var after := restored.menu_model(1)
	if int(after["silver"]) != before + expected_silver or String(after["loot_filter"]) != "rare" or String(after["auto_sell"]) != "rare":
		return _fail("Silver and loot preferences must survive save and load")
	print("LOOT_ECONOMY_OK: selling, filter, auto-sell on return and persistence")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
