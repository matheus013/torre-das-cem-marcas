extends SceneTree

const CatalogScript := preload("res://src/gameplay/content/beta_content_catalog.gd")
const FactoryScript := preload("res://src/gameplay/content/beta_item_factory.gd")


func _init() -> void:
	var catalog: RefCounted = CatalogScript.new()
	if not bool(catalog.call("load_from")):
		push_error("Could not load beta items")
		quit(1)
		return
	var factory: RefCounted = FactoryScript.new()
	var equipment_count := 0
	var relic_count := 0
	var items: Array = catalog.call("collection", "items")
	for item_value: Variant in items:
		var item := item_value as Dictionary
		var instance: EquipmentItemInstance = factory.call(
			"instance_from_data", item, StringName("test_%s" % item["id"]), &"tester"
		)
		if String(item.get("slot", "none")) == "none":
			if instance != null:
				push_error("Non-equipment beta item created an equipment instance")
				quit(1)
				return
			continue
		equipment_count += 1
		if instance == null or not instance.definition.is_valid_definition():
			push_error("Invalid beta equipment definition: %s" % item.get("id", ""))
			quit(1)
			return
		if instance.definition.slot == EquipmentItemDefinition.Slot.RELIC:
			relic_count += 1
			if not ItemTier.is_at_least(instance.tier, ItemTier.Value.EPIC):
				push_error("Beta relic tier is below epic")
				quit(1)
				return
	if equipment_count != 24 or relic_count != 3:
		push_error("Unexpected beta equipment composition")
		quit(1)
		return
	print("BETA_ITEMS_OK: 24 equipment definitions and 3 mechanical relics instantiated")
	quit(0)
