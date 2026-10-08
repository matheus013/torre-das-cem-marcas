extends SceneTree

## Decisão 594: loja de equipamentos na Forja da Dália. Vitrine de 8 peças (até épico) com afixos
## já sorteados, preço 5x o de venda, compra entrega a mesma peça, renovação paga e a cada volta da
## Torre, estoque melhor com o andar mais fundo, tudo no save; botão no menu de serviço.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const ServiceMenu := preload("res://src/prototype/village/service_menu.gd")
const ShopMenu := preload("res://src/prototype/village/shop_menu.gd")


func _init() -> void:
	_run.call_deferred()


func _world() -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5868)
	sim.add_player(1, &"eloa")
	var npc := sim.village_life.call("find", "dalia_ferral") as Dictionary
	sim.player(1)["position"] = (npc["position"] as Vector2) + Vector2(20.0, 0.0)
	sim._gear(1)["silver"] = 100000
	return sim


func _tier_average(sim: WorldSimulation) -> float:
	var total := 0.0
	var count := 0
	for round_index in range(12):
		sim.shop_sequence = round_index
		for item in sim.shop_stock():
			total += float(int(item.tier))
			count += 1
	return total / float(maxi(1, count))


func _run() -> void:
	var sim := _world()
	var stock := sim.shop_stock()
	if stock.size() != Simulation.SHOP_SIZE:
		return _fail("The shop must show %d pieces, got %d" % [Simulation.SHOP_SIZE, stock.size()])
	for item in stock:
		if ItemTier.key(item.tier) == "legendary" or item.affixes.is_empty():
			return _fail("Shop pieces go up to epic and come with rolled affixes")
	var twin := _world()
	if twin.shop_stock().map(func(item: EquipmentItemInstance) -> String: return String(item.definition.id)) != stock.map(func(item: EquipmentItemInstance) -> String: return String(item.definition.id)):
		return _fail("Same world and round must show the same stock")
	var offer := stock[0]
	var price := sim.shop_price(offer)
	if price != sim.item_sell_price(offer) * 5 or int((sim.shop_model(1)["items"] as Array)[0]["price"]) != price:
		return _fail("Buying costs 5x the sale price")

	# Compra: a mesma peça vai para a mochila; a vaga fica vendida.
	var inventory := sim._gear(1)["inventory"] as ItemInventory
	var before := inventory.items.keys()
	var silver := int(sim._gear(1)["silver"])
	if not sim.buy_shop_item(1, 0):
		return _fail("Buying next to Dalia with enough silver must work")
	var bought: EquipmentItemInstance = null
	for instance_id: StringName in inventory.items:
		if instance_id not in before:
			bought = inventory.items[instance_id]
	if bought == null or bought.definition.id != offer.definition.id or bought.affixes != offer.affixes or bought.quality != offer.quality or bought.item_level != offer.item_level:
		return _fail("The bought piece must be exactly the one on display")
	if int(sim._gear(1)["silver"]) != silver - price or sim.buy_shop_item(1, 0) or not bool((sim.shop_model(1)["items"] as Array)[0]["sold"]):
		return _fail("Buying must charge once and mark the slot as sold")

	# Longe da forja ou sem prata, nada acontece.
	var far := _world()
	far.player(1)["position"] = (far.player(1)["position"] as Vector2) + Vector2(800.0, 0.0)
	if far.buy_shop_item(1, 1):
		return _fail("Buying requires being next to Dalia")
	var poor := _world()
	poor._gear(1)["silver"] = 0
	if poor.buy_shop_item(1, 1) or poor.reroll_shop(1):
		return _fail("Without silver nothing is bought or renewed")

	# Renovar: custa prata, troca a rodada e libera as vagas; voltar da Torre também renova.
	var sequence := sim.shop_sequence
	silver = int(sim._gear(1)["silver"])
	if not sim.reroll_shop(1) or sim.shop_sequence != sequence + 1 or not sim.shop_sold.is_empty() or int(sim._gear(1)["silver"]) != silver - Simulation.SHOP_REROLL_PRICE:
		return _fail("Renewing must cost silver, change the round and clear sold slots")
	sim.buy_shop_item(1, 2)
	sim.enter_tower(1)
	sim.leave_tower(1)
	if sim.shop_sequence != sequence + 2 or not sim.shop_sold.is_empty():
		return _fail("Returning from the Tower must restock the shop")

	# Mais fundo, peças melhores.
	var shallow := _world()
	var deep := _world()
	deep.deepest_floor = 100
	if _tier_average(deep) <= _tier_average(shallow) + 0.5:
		return _fail("Deeper progress must improve the stock: %.2f vs %.2f" % [_tier_average(deep), _tier_average(shallow)])

	# Save: mesma rodada, mesmas vagas vendidas, mesma vitrine.
	sim.player(1)["position"] = ((sim.village_life.call("find", "dalia_ferral") as Dictionary)["position"] as Vector2) + Vector2(20.0, 0.0)
	sim.buy_shop_item(1, 3)
	var restored := Simulation.new()
	restored.setup(5868)
	restored.add_player(1, &"eloa")
	if not restored.load_data(sim.save_data(1), 1) or restored.shop_sequence != sim.shop_sequence or restored.shop_sold != sim.shop_sold:
		return _fail("Shop round and sold slots must survive save and load")
	if restored.shop_stock()[4].affixes != sim.shop_stock()[4].affixes:
		return _fail("The restored shop must show the same pieces")

	# Interface: botão na Dália e vitrine com 8 ofertas.
	var service := ServiceMenu.new()
	root.add_child(service)
	service.call("open", sim.village_life.call("find", "dalia_ferral"), sim.player(1), {})
	var opened := [false]
	service.connect("shop_requested", func() -> void: opened[0] = true)
	var shop_button := service.find_child("OpenShop", true, false) as Button
	if shop_button == null:
		return _fail("Dalia's service menu must offer the shop")
	shop_button.pressed.emit()
	if not opened[0]:
		return _fail("The shop button must request the shop")
	service.queue_free()
	var shop := ShopMenu.new()
	root.add_child(shop)
	shop.call("open", sim.shop_model(1))
	await process_frame
	var grid := shop.find_child("ShopGrid", true, false)
	var sold_card := shop.find_child("Offer_3", true, false)
	if grid == null or grid.get_child_count() != Simulation.SHOP_SIZE or sold_card == null or (sold_card.find_child("Buy", true, false) as Button).text != "VENDIDO":
		return _fail("The shop window must list every offer and mark sold ones")
	shop.queue_free()
	await process_frame
	print("VILLAGE_SHOP_OK: 8 rolled pieces up to epic, 5x price, exact purchase, reroll, restock on return, deeper is better, saved")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
