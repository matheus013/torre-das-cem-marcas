extends SceneTree

const BetaCatalogScript := preload("res://src/gameplay/content/beta_content_catalog.gd")


func _init() -> void:
	var catalog: RefCounted = BetaCatalogScript.new()
	if not bool(catalog.call("load_from")):
		push_error("Beta catalog failed validation: %s" % catalog.call("validation_errors"))
		quit(1)
		return
	var expected_counts := {
		"playable_characters": 4,
		"active_gems": 8,
		"support_gems": 12,
		"summons": 1,
		"monster_races": 5,
		"enemy_ranks": 5,
		"enemies": 9,
		"loot_tables": 8,
		"major_encounters": 2,
		"special_boss_rooms": 1,
		"enemy_modifiers": 12,
		"items": 32,
	}
	for collection_name: String in expected_counts:
		var definitions: Array = catalog.call("collection", collection_name)
		if definitions.size() != int(expected_counts[collection_name]):
			push_error("Unexpected beta count for %s" % collection_name)
			quit(1)
			return
	var boss: Dictionary = catalog.call("find_definition", "enemies", "guardiao_de_enxerto")
	if boss.is_empty() or bool(boss.get("allow_affixes", true)):
		push_error("Beta boss definition or affix restriction is missing")
		quit(1)
		return
	var raid: Dictionary = catalog.call("find_definition", "enemies", "nucleo_de_renovacao")
	var raid_encounter: Dictionary = catalog.call("find_definition", "major_encounters", "cerco_do_nucleo")
	if raid.get("encounter_class", "") != "raid" or raid_encounter.get("encounter_type", "") != "raid":
		push_error("Raid enemy or authored encounter definition is missing")
		quit(1)
		return
	var summon_gem: Dictionary = catalog.call("find_definition", "active_gems", "molde_vigilante")
	var summon: Dictionary = catalog.call("find_definition", "summons", String(summon_gem.get("summon_definition_id", "")))
	if summon.is_empty() or int(summon.get("owner_limit", 0)) <= 0:
		push_error("Summon gem is not linked to a valid summon definition")
		quit(1)
		return
	var boss_room: Dictionary = catalog.call("find_definition", "special_boss_rooms", "camara_refeita")
	if not bool(boss_room.get("exclusive_enemy", false)) or float(boss_room.get("respawn_seconds", 0.0)) < 60.0:
		push_error("Exclusive special boss room or long respawn is missing")
		quit(1)
		return
	print("BETA_CONTENT_OK: lore profiles, multi-drop tables, special boss room and existing beta content validated")
	quit(0)
