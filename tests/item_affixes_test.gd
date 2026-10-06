extends SceneTree

## Decisão 583: afixos aleatórios por raridade (comum 1, incomum 2, raro 3, épico 3, lendário 3 a 4)
## com valores que crescem com a raridade e o nível do item (andar onde a peça foi obtida).
## Regressão (2026-10-06): armaduras, luvas, botas, calças e manoplas não tinham ícone.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Affixes := preload("res://src/gameplay/items/item_affixes.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# Todo item do catálogo (equipamento e material) tem ícone.
	for path in ["res://data/beta/beta_content.json", "res://data/tower/tower_content.json"]:
		var catalog := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
		for item: Dictionary in catalog["items"]:
			if not ResourceLoader.exists("res://assets/sprites/items/%s.png" % item["id"]):
				return _fail("Item without icon: %s" % item["id"])

	# Quantidade por raridade, sem afixo repetido.
	var random := RandomNumberGenerator.new()
	random.seed = 583
	var expected := {"common": [1, 1], "uncommon": [2, 2], "rare": [3, 3], "epic": [3, 3], "legendary": [3, 4]}
	var legendary_counts := {}
	for tier: String in expected:
		for attempt in range(200):
			var rolled := Affixes.roll(tier, random)
			var ids := {}
			for affix: Dictionary in rolled:
				ids[affix["id"]] = true
			if rolled.size() < int(expected[tier][0]) or rolled.size() > int(expected[tier][1]) or ids.size() != rolled.size():
				return _fail("%s rolled %d affixes (or a duplicate)" % [tier, rolled.size()])
			if tier == "legendary":
				legendary_counts[rolled.size()] = true
	if legendary_counts.size() != 2:
		return _fail("Legendary items must roll both 3 and 4 affixes")

	# Valor cresce com raridade e nível: mesma semente, mesmo afixo, só muda a escala.
	var low := _first_value("common", 1)
	var rare := _first_value("rare", 1)
	var deep := _first_value("common", 100)
	if not is_equal_approx(snappedf(rare / low, 0.01), 1.5) and absf(rare / low - 1.5) > 0.2:
		return _fail("Rare affixes must be ~1.5x common, got %.2f" % (rare / low))
	if deep / low < 2.5:
		return _fail("Level 100 affixes must be ~3x level 1, got %.2f" % (deep / low))

	# Peça criada na Torre leva o nível do andar; atributos e afixos entram nos atributos derivados.
	var sim := Simulation.new()
	sim.setup(5830)
	sim.add_player(1, &"cira")
	var before := sim.derived_stats(1)
	var shallow := sim._add_equipment_instance(&"cira", "calca_de_carga", "regular", 1)
	var item := (sim._gear(1)["inventory"] as ItemInventory).get_item(shallow)
	if item.item_level != 1 or item.affixes.size() != 2:
		return _fail("Uncommon pants must have 2 affixes and level 1")
	sim.set("current_floor", 60)
	sim._receive_item(1, "calca_de_carga", 1, "regular")
	var deep_item: EquipmentItemInstance = null
	for candidate: EquipmentItemInstance in (sim._gear(1)["inventory"] as ItemInventory).items.values():
		if candidate.instance_id != shallow and String(candidate.definition.id) == "calca_de_carga":
			deep_item = candidate
	if deep_item == null or deep_item.item_level != 60:
		return _fail("Items received on floor 60 must be item level 60")
	sim.set("current_floor", 0)
	sim.equip_item(1, deep_item.instance_id)
	var after := sim.derived_stats(1)
	var base_health := 24.0 * Affixes.level_factor(60)
	var affix_health := float(Affixes.stats(deep_item.affixes).get(&"health", 0.0))
	if float(after["max_health"]) - float(before["max_health"]) < base_health + affix_health - 0.5:
		return _fail("Level-scaled base stats and affixes must raise max health")

	# Afixo de modificador entra em _mod (ex.: dano de fogo).
	var modded := Simulation.new()
	modded.setup(5831)
	modded.add_player(1, &"eloa")
	var ring_id := modded._add_equipment_instance(&"eloa", "anel_de_precisao", "regular", 10)
	var ring := (modded._gear(1)["inventory"] as ItemInventory).get_item(ring_id)
	ring.affixes = [{"id": "dano_fogo", "value": 0.1}] as Array[Dictionary]
	var fire_before := modded._mod(1, "power_fire_mult")
	modded.equip_item(1, ring_id)
	if not is_equal_approx(modded._mod(1, "power_fire_mult") / fire_before, 1.1):
		return _fail("Fire damage affix must multiply power_fire_mult by 1.1, got %.3f" % (modded._mod(1, "power_fire_mult") / fire_before))

	# Save guarda afixos e nível; save antigo sem afixos sorteia os seus ao carregar.
	var saved := sim.save_data(1)
	var restored := Simulation.new()
	restored.setup(5830)
	restored.add_player(1, &"cira")
	if not restored.load_data(JSON.parse_string(JSON.stringify(saved)) as Dictionary, 1):
		return _fail("Save with affixes must load")
	var restored_item := (restored._gear(1)["equipment"] as EquipmentLoadout).get_equipped(EquipmentItemDefinition.Slot.PANTS, 0)
	if restored_item == null or restored_item.item_level != 60 or restored_item.affixes != deep_item.affixes:
		return _fail("Affixes and item level must survive save/load")
	for entry: Dictionary in saved["character_gear"]["cira"]["items"]:
		entry.erase("affixes")
		entry.erase("item_level")
	var legacy := Simulation.new()
	legacy.setup(5832)
	legacy.add_player(1, &"cira")
	legacy.load_data(saved, 1)
	for legacy_item: EquipmentItemInstance in (legacy._gear(1)["inventory"] as ItemInventory).items.values():
		if legacy_item.affixes.size() < 1 or legacy_item.item_level != 1:
			return _fail("Old items without affixes must roll them on load at level 1")
	print("ITEM_AFFIXES_OK: icons for every item, 1/2/3/3/3-4 affixes, tier and level scaling, stats, mods, save and legacy roll")
	quit(0)


func _first_value(tier: String, level: int) -> float:
	var random := RandomNumberGenerator.new()
	random.seed = 99
	return absf(float(Affixes.roll(tier, random, level)[0]["value"]))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
