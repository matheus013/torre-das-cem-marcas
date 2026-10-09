extends SceneTree


func _init() -> void:
	var loadout := EquipmentLoadout.new()
	var inventory := ItemInventory.new(&"eloa")
	var weapon := EquipmentItemDefinition.new(&"tower_blade", EquipmentItemDefinition.Slot.WEAPON)
	weapon.stat_modifiers = {&"strength": 12.0}
	var offhand := EquipmentItemDefinition.new(&"memory_lantern", EquipmentItemDefinition.Slot.OFFHAND)
	var amulet := EquipmentItemDefinition.new(&"first_ligature", EquipmentItemDefinition.Slot.AMULET)
	var armor := EquipmentItemDefinition.new(&"ferral_plate", EquipmentItemDefinition.Slot.ARMOR)
	var gloves := EquipmentItemDefinition.new(&"conductor_gloves", EquipmentItemDefinition.Slot.GLOVES)
	var boots := EquipmentItemDefinition.new(&"route_boots", EquipmentItemDefinition.Slot.BOOTS)
	var pants := EquipmentItemDefinition.new(&"warden_pants", EquipmentItemDefinition.Slot.PANTS)
	var fixed_definitions := [weapon, offhand, amulet, armor, gloves, boots, pants]
	for index in fixed_definitions.size():
		var item := EquipmentItemInstance.new(
			StringName("fixed_%d" % index), fixed_definitions[index], &"eloa"
		)
		inventory.add(item)
		if not EquipmentTransaction.equip_from_inventory(inventory, loadout, item.instance_id):
			_fail("Loadout rejected a valid fixed-slot item")
			return

	for index in EquipmentLoadout.RING_SLOT_COUNT:
		var ring := EquipmentItemDefinition.new(
			StringName("ring_%d" % index), EquipmentItemDefinition.Slot.RING
		)
		ring.stat_modifiers = {&"fortune": 1.0}
		var ring_item := EquipmentItemInstance.new(StringName("ring_i_%d" % index), ring, &"eloa")
		inventory.add(ring_item)
		if not EquipmentTransaction.equip_from_inventory(inventory, loadout, ring_item.instance_id, index):
			_fail("Loadout rejected ring slot %d" % index)
			return

	for index in EquipmentLoadout.RELIC_SLOT_COUNT:
		var relic := EquipmentItemDefinition.new(
			StringName("relic_%d" % index), EquipmentItemDefinition.Slot.RELIC
		)
		relic.mechanic_changes = [StringName("spell_rule_%d" % index)]
		var relic_item := EquipmentItemInstance.new(StringName("relic_i_%d" % index), relic, &"eloa")
		relic_item.tier = ItemTier.Value.EPIC
		inventory.add(relic_item)
		if not EquipmentTransaction.equip_from_inventory(inventory, loadout, relic_item.instance_id, index):
			_fail("Loadout rejected relic slot %d" % index)
			return

	if loadout.equipped_count() != 13:
		_fail("Complete equipment layout did not contain exactly 13 slots (7 + 2 rings + 4 relics)")
		return
	if float(loadout.combined_stat_modifiers()[&"fortune"]) != float(EquipmentLoadout.RING_SLOT_COUNT):
		_fail("Both rings must contribute to the combined build")
		return
	if loadout.active_mechanic_changes().size() != 4:
		_fail("Four relic mechanics were not exposed to the build")
		return

	var invalid_relic := EquipmentItemDefinition.new(&"flat_relic", EquipmentItemDefinition.Slot.RELIC)
	var invalid_item := EquipmentItemInstance.new(&"flat_relic_i", invalid_relic, &"eloa")
	invalid_item.tier = ItemTier.Value.EPIC
	inventory.add(invalid_item)
	if EquipmentTransaction.equip_from_inventory(inventory, loadout, invalid_item.instance_id, 0):
		_fail("Relic without a mechanical change was accepted")
		return

	var two_handed := EquipmentItemDefinition.new(&"great_hammer", EquipmentItemDefinition.Slot.WEAPON)
	two_handed.two_handed = true
	var two_handed_item := EquipmentItemInstance.new(&"great_hammer_i", two_handed, &"eloa")
	inventory.add(two_handed_item)
	if EquipmentTransaction.equip_from_inventory(inventory, loadout, two_handed_item.instance_id):
		_fail("Two-handed weapon ignored the occupied offhand")
		return
	if not inventory.has(&"great_hammer_i") or not inventory.has(&"flat_relic_i"):
		_fail("Failed equipment transaction removed an item from inventory")
		return
	if not EquipmentTransaction.unequip_to_inventory(
		inventory, loadout, EquipmentItemDefinition.Slot.RING, 0
	):
		_fail("Could not atomically return an equipped ring to inventory")
		return

	print("EQUIPMENT_OK: seven fixed slots, two rings and four mechanical relics")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
