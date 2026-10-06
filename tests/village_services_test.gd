extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Services := preload("res://src/gameplay/world/village_services.gd")
const Menu := preload("res://src/prototype/village/service_menu.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var sim := Simulation.new()
	sim.setup(9)
	sim.add_player(1)
	sim.add_player(2)
	var state := sim.player(1)
	var gear := sim._gear(1)
	var life := sim.village_life as VillageLife
	var merchant := life.find("cassio_rotavela")
	state["position"] = merchant["position"]
	state["target"] = state["position"]
	var before := int(gear["silver"])
	if not sim.use_village_service(1, "cassio_rotavela", "comprar_suprimento") or int(state["quick_items"]) != 3 or int(gear["silver"]) != before - 18:
		return _fail("Shop transaction failed")
	state["quick_items"] = 9
	if sim.use_village_service(1, "cassio_rotavela", "comprar_suprimento") or int(gear["silver"]) != before - 18:
		return _fail("Full bag charged silver")
	state["quick_items"] = 2
	gear["silver"] = 0
	if sim.use_village_service(1, "cassio_rotavela", "comprar_suprimento"):
		return _fail("Insufficient silver accepted")
	gear["silver"] = 120
	state["position"] = life.find("sira_botanica")["position"]
	life.economy.stock = {"madeira": 1, "minerio": 8, "alimentos": 6}
	if sim.use_village_service(1, "sira_botanica", "preparar_remedios") or int(life.economy.stock["alimentos"]) != 6 or int(gear["silver"]) != 120:
		return _fail("Partial recipe spent resources")
	life.economy.stock["madeira"] = 2
	if not sim.use_village_service(1, "sira_botanica", "preparar_remedios") or int(state["quick_items"]) != 5 or int(life.economy.stock["alimentos"]) != 0 or int(life.economy.stock["madeira"]) != 0:
		return _fail("Alchemy did not consume exact recipe")
	sim.player(2)["position"] = state["position"]
	if sim.use_village_service(2, "sira_botanica", "preparar_remedios"):
		return _fail("Two peers consumed the same reserves")
	state["position"] = life.find("maura_salvedra")["position"]
	state["health"] = 1.0
	state["breath"] = 1.0
	state["wounds"] = 2
	if not sim.use_village_service(1, "maura_salvedra", "tratamento") or float(state["health"]) != sim.max_health(1) or int(state["wounds"]) != 0:
		return _fail("Infirmary did not recover player")
	state["position"] = life.find("dalia_ferral")["position"]
	var weapon := (gear["equipment"] as EquipmentLoadout).get_equipped(EquipmentItemDefinition.Slot.WEAPON, 0)
	weapon.integrity = 0.25
	if not sim.use_village_service(1, "dalia_ferral", "reparar_equipamento") or weapon.integrity != 1.0 or int(life.economy.stock["minerio"]) != 4:
		return _fail("Forge repair failed")
	before = int(gear["silver"])
	if sim.use_village_service(1, "dalia_ferral", "reparar_equipamento") or before != int(gear["silver"]):
		return _fail("Unnecessary repair charged silver")
	state["zone"] = &"tower"
	if sim.use_village_service(1, "dalia_ferral", "reparar_equipamento") or sim.use_village_service(1, "cassio_rotavela", "comprar_suprimento"):
		return _fail("Remote purchase accepted")
	state["zone"] = &"village"
	state["position"] = Vector2.ZERO
	if sim.use_village_service(1, "cassio_rotavela", "comprar_suprimento") or sim.use_village_service(1, "cassio_rotavela", "forged_offer"):
		return _fail("Distance/offer validation missing")
	var menu := Menu.new()
	root.add_child(menu)
	await process_frame
	menu.open(merchant, sim.view_snapshot()["players"][1], life.economy.view())
	if not menu.visible or menu.get("_buttons").size() != 1:
		return _fail("Service UI did not expose shop")
	menu.close()
	menu.queue_free()
	await process_frame
	print("VILLAGE_SERVICES_OK: shop, bag cap, alchemy, shared stock, infirmary, forge, range validation and UI")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
