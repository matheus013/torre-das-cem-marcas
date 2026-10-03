extends SceneTree


func _init() -> void:
	var scene := load("res://src/prototype/build_lab/build_lab.tscn") as PackedScene
	if scene == null:
		push_error("Build lab scene could not be loaded")
		quit(1)
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	if instance.get_node_or_null("RootColumn/Content/ProgressionTab") == null:
		push_error("Build lab did not initialize the progression interface")
		quit(1)
		return
	instance.call("_allocate_stat", &"vitality")
	var build := instance.get("_build") as CharacterBuild
	if int(build.base_stats[&"vitality"]) != 1 or build.unspent_stat_points != 4:
		push_error("Progression interface did not allocate a stat point")
		quit(1)
		return
	instance.call("_advance_to_milestone")
	if build.level != 10 or not build.has_pending_milestone():
		push_error("Progression interface did not stop at the first milestone")
		quit(1)
		return
	var first_choice := (build.milestone_choices[10] as Array)[0] as EvolutionChoice
	instance.call("_choose_milestone", first_choice.id)
	if build.has_pending_milestone():
		push_error("Progression interface did not resolve its milestone choice")
		quit(1)
		return
	var selector := instance.get_node_or_null("RootColumn/HeaderMargin/HeaderRow/CharacterSelector")
	if selector == null:
		selector = instance.find_child("CharacterSelector", true, false)
	if selector == null or (selector as OptionButton).item_count != 4:
		push_error("Build lab did not expose the four beta characters")
		quit(1)
		return
	instance.call("_select_character", 2, false)
	var cira_build := instance.get("_build") as CharacterBuild
	if cira_build.character_id != &"cira" or cira_build.max_level != 100 or cira_build.level != 1:
		push_error("Build lab did not switch to Cira's independent beta build")
		quit(1)
		return
	instance.call("_select_character", 0, false)
	build = instance.get("_build") as CharacterBuild
	if build.character_id != &"eloa" or not build.selected_milestones.has(10):
		push_error("Build lab did not preserve Eloa's progression when switching characters")
		quit(1)
		return
	instance.call("_show_tab", 1)
	await process_frame
	if instance.get_node_or_null("RootColumn/Content/GemsTab") == null:
		push_error("Build lab did not initialize the gems interface")
		quit(1)
		return
	instance.call("_add_support", 0)
	var gems := instance.get("_gem_loadout") as SkillGemLoadout
	if gems.active_slots[0].support_gems.size() != 1:
		push_error("Gems interface did not attach a support")
		quit(1)
		return
	instance.call("_show_tab", 2)
	await process_frame
	if instance.get_node_or_null("RootColumn/Content/EquipmentTab") == null:
		push_error("Build lab did not initialize the equipment interface")
		quit(1)
		return
	var equipment := instance.get("_equipment") as EquipmentLoadout
	var inventory := instance.get("_inventory") as ItemInventory
	instance.call(
		"_toggle_equipment", EquipmentItemDefinition.Slot.RING, 4, &"instance_ring_4"
	)
	if equipment.get_equipped(EquipmentItemDefinition.Slot.RING, 4) == null:
		push_error("Equipment interface did not equip the fifth ring")
		quit(1)
		return
	if inventory.has(&"instance_ring_4"):
		push_error("Equipped ring remained duplicated in inventory")
		quit(1)
		return
	print("BUILD_LAB_OK: progression, gems and equipment interface initialized")
	quit(0)
