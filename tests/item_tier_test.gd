extends SceneTree


func _init() -> void:
	var ordered: Array[ItemTier.Value] = [
		ItemTier.Value.COMMON,
		ItemTier.Value.UNCOMMON,
		ItemTier.Value.RARE,
		ItemTier.Value.EPIC,
		ItemTier.Value.LEGENDARY,
	]
	for index in ordered.size() - 1:
		if not ItemTier.is_at_least(ordered[index + 1], ordered[index]):
			_fail("Item tiers are not strictly ordered")
			return
		if ItemTier.is_at_least(ordered[index], ordered[index + 1]):
			_fail("Lower item tier satisfied a higher requirement")
			return

	var relic_definition := EquipmentItemDefinition.new(
		&"world_vein", EquipmentItemDefinition.Slot.RELIC
	)
	relic_definition.mechanic_changes = [&"repeat_last_spell"]
	var rare_relic := EquipmentItemInstance.new(&"rare_world_vein", relic_definition, &"eloa")
	rare_relic.tier = ItemTier.Value.RARE
	if EquipmentLoadout.new().equip(rare_relic, 0):
		_fail("Rare relic entered a slot reserved for epic or legendary items")
		return

	print("ITEM_TIER_OK: common through legendary order and relic minimum enforced")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
