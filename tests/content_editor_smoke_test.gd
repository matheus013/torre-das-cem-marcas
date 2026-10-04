extends SceneTree


func _init() -> void:
	var scene := load("res://src/prototype/dev_tools/content_editor.tscn") as PackedScene
	if scene == null:
		push_error("Content editor scene could not be loaded")
		quit(1)
		return
	var instance := scene.instantiate()
	var test_path := "user://content_editor_test.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	instance.set("storage_path", test_path)
	root.add_child(instance)
	await process_frame
	if instance.get_node_or_null("RootColumn/Body/Browser/Entries") == null:
		push_error("Content browser did not initialize")
		quit(1)
		return
	var fields := instance.get("_fields") as Dictionary
	(fields[&"id"] as LineEdit).text = "raspador_teste"
	(fields[&"name"] as LineEdit).text = "Raspador de Teste"
	instance.call("_save_entry")
	var enemies := instance.get("_enemies") as Array
	if enemies.size() < 9 or enemies.back().get("id", "") != "raspador_teste":
		push_error("Enemy editor did not create a stable definition")
		quit(1)
		return
	instance.call("_show_mode", &"item")
	await process_frame
	fields = instance.get("_fields") as Dictionary
	(fields[&"id"] as LineEdit).text = "pedra_teste"
	(fields[&"name"] as LineEdit).text = "Pedra de Teste"
	instance.call("_save_entry")
	var items := instance.get("_items") as Array
	if items.size() < 33 or items.back().get("id", "") != "pedra_teste":
		push_error("Item editor did not create a stable definition")
		quit(1)
		return
	instance.call("_show_mode", &"modifier")
	await process_frame
	fields = instance.get("_fields") as Dictionary
	(fields[&"id"] as LineEdit).text = "robusto_teste"
	(fields[&"name"] as LineEdit).text = "Robusto"
	(fields[&"health_multiplier"] as SpinBox).value = 1.5
	instance.call("_save_entry")
	var modifiers := instance.get("_enemy_modifiers") as Array
	if modifiers.size() < 13 or not is_equal_approx(float(modifiers.back().get("health_multiplier", 0.0)), 1.5):
		push_error("Enemy modifier editor did not create an affix definition")
		quit(1)
		return
	instance.call("_show_mode", &"support_gem")
	await process_frame
	fields = instance.get("_fields") as Dictionary
	(fields[&"id"] as LineEdit).text = "suporte_teste"
	(fields[&"name"] as LineEdit).text = "Suporte de Teste"
	(fields[&"requires"] as LineEdit).text = "projectile, area"
	(fields[&"modifiers"] as TextEdit).text = "{\"power_multiplier\": 1.1}"
	instance.call("_save_entry")
	var supports := instance.get("_support_gems") as Array
	if supports.size() < 13 or supports.back().get("requires", []).size() != 2:
		push_error("Support gem editor did not parse tags and modifiers")
		quit(1)
		return
	instance.call("_show_mode", &"active_gem")
	await process_frame
	var active_gems := instance.get("_active_gems") as Array
	if active_gems.size() != 36 or instance.get_node_or_null("RootColumn/Body/EditorScroll/Editor/Form/Evolutions") == null:
		push_error("Active gem editor did not load the beta catalog")
		quit(1)
		return
	instance.call("_show_mode", &"summon")
	await process_frame
	fields = instance.get("_fields") as Dictionary
	(fields[&"id"] as LineEdit).text = "vigia_teste"
	(fields[&"name"] as LineEdit).text = "Vigia de Teste"
	instance.call("_save_entry")
	var summons := instance.get("_summons") as Array
	if summons.size() < 2 or summons.back().get("id", "") != "vigia_teste":
		push_error("Summon editor did not create a stable definition")
		quit(1)
		return
	instance.call("_show_mode", &"encounter")
	await process_frame
	fields = instance.get("_fields") as Dictionary
	(fields[&"id"] as LineEdit).text = "boss_teste"
	(fields[&"name"] as LineEdit).text = "Boss de Teste"
	(fields[&"enemy_definition_id"] as LineEdit).text = "guardiao_de_enxerto"
	(fields[&"player_scaling"] as TextEdit).text = "{\"health_per_extra_player\":0.5,\"damage_per_extra_player\":0.1}"
	(fields[&"break"] as TextEdit).text = "{\"maximum\":100,\"stagger_duration\":4}"
	(fields[&"objectives"] as TextEdit).text = "[]"
	(fields[&"phases"] as TextEdit).text = "[{\"id\":\"inicio\",\"health_threshold\":1.0,\"mechanics\":[\"sweep\"]},{\"id\":\"final\",\"health_threshold\":0.4,\"mechanics\":[\"collapse\"]}]"
	instance.call("_save_entry")
	var encounters := instance.get("_major_encounters") as Array
	if encounters.size() < 3 or encounters.back().get("id", "") != "boss_teste":
		push_error("Major encounter editor did not create a valid boss definition")
		quit(1)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	print("CONTENT_EDITOR_OK: enemies, items, affixes, gems, summons, bosses and raids persisted")
	quit(0)
