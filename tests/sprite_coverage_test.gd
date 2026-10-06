extends SceneTree

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
var _count := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _check_folder("res://assets/sprites"):
		return _fail("Unreadable or empty sprite")
	var beta := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	for collection in ["active_gems", "support_gems"]:
		for gem: Dictionary in beta[collection]:
			if Sprites.texture("icons/" + String(gem["id"])) == null:
				return _fail("Missing gem icon: " + String(gem["id"]))
	var village := JSON.parse_string(FileAccess.get_file_as_string("res://data/village/village_content.json")) as Dictionary
	for npc: Dictionary in village["npcs"]:
		if Sprites.texture(String(npc["sprite"])) == null:
			return _fail("Missing NPC sprite: " + String(npc["id"]))
	var tower := preload("res://src/gameplay/world/tower_content.gd")
	for collection in ["enemies", "bosses"]:
		for enemy: Dictionary in tower.collection(collection):
			if Sprites.texture("enemies/" + String(enemy["id"])) == null:
				return _fail("Missing tower sprite: " + String(enemy["id"]))
	for biome: Dictionary in tower.collection("biomes"):
		for key: String in [String(biome["tile"])] + (biome["props"] as Array):
			if Sprites.texture(key) == null:
				return _fail("Missing biome sprite in %s: %s" % [biome["id"], key])
	var item_ids := {}
	for item: Dictionary in beta["items"]:
		item_ids[String(item["id"])] = true
	for item: Dictionary in tower.collection("items"):
		item_ids[String(item["id"])] = true
	for name in DirAccess.get_files_at("res://assets/sprites/items"):
		if name.ends_with(".png") and not item_ids.has(name.trim_suffix(".png")):
			return _fail("Item icon without a catalog item: " + name)
	var seen_icons := {}
	for collection in ["active_gems", "support_gems"]:
		for gem: Dictionary in beta[collection]:
			var pixels := Sprites.texture("icons/" + String(gem["id"])).get_image().get_data()
			if seen_icons.has(pixels):
				return _fail("Gems %s and %s share the same icon" % [seen_icons[pixels], gem["id"]])
			seen_icons[pixels] = gem["id"]
	var aegis := Sprites.texture("icons/aegis_por_acerto").get_image().get_data()
	var stability := Sprites.texture("icons/estabilidade_solida").get_image().get_data()
	if aegis == stability:
		return _fail("Barrier and stability icons must be distinct")
	print("SPRITE_COVERAGE_OK: %d images, gems, NPCs and tower definitions" % _count)
	quit(0)


func _check_folder(folder: String) -> bool:
	for name in DirAccess.get_files_at(folder):
		if not name.ends_with(".png"):
			continue
		var key := folder.path_join(name).trim_prefix(Sprites.ROOT).trim_suffix(".png")
		var texture := Sprites.texture(key)
		if texture == null or texture.get_image().get_used_rect().size == Vector2i.ZERO:
			return false
		_count += 1
	for child in DirAccess.get_directories_at(folder):
		if not _check_folder(folder.path_join(child)):
			return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
