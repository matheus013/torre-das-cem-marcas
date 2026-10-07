extends RefCounted

const DevModeScript := preload("res://src/core/app/dev_mode.gd")
const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")


static func run(tree: SceneTree) -> void:
	if OS.is_debug_build():
		_fail(tree, "Run this check with an exported release executable")
		return
	if not FileAccess.file_exists("res://VERSION"):
		_fail(tree, "Missing packaged VERSION")
		return
	for args in [PackedStringArray(), PackedStringArray(["--dev"]), PackedStringArray(["--server"]), PackedStringArray(["--client=127.0.0.1"])]:
		if DevModeScript.enabled() or DevModeScript.boot_scene(args) != DevModeScript.PUBLIC_HOME:
			_fail(tree, "Release exposes development home")
			return
	for path in ["res://data/village/village_content.json", "res://data/beta/beta_content.json", "res://data/combat/weapon_profiles.json", TowerContentScript.PATH]:
		if not FileAccess.file_exists(path) or JSON.parse_string(FileAccess.get_file_as_string(path)) == null:
			_fail(tree, "Missing or invalid packaged content: " + path)
			return
	for folder in ["res://tests", "res://tools", "res://art", "res://docs", "res://node_modules"]:
		if DirAccess.dir_exists_absolute(folder):
			_fail(tree, "Development files included: " + folder)
			return
	if not WeaponCombat.validation_errors().is_empty():
		_fail(tree, "Invalid weapon profiles")
		return
	for key in ["characters/eloa", "buildings/torre", "tiles/grass"]:
		if load("res://assets/sprites/" + key + ".png") == null:
			_fail(tree, "Missing packaged sprite: " + key)
			return
	for character_id in ["eloa", "sena", "cira", "rui"]:
		var frame := preload("res://src/presentation/art/sprite_library.gd").character_frame(character_id, Vector2.DOWN, true, 0.0)
		if frame == null:
			_fail(tree, "Missing packaged animation: " + character_id)
			return
		var idle := preload("res://src/presentation/art/sprite_library.gd").character_frame(character_id, Vector2.DOWN, false, 0.0) as AtlasTexture
		if idle == null or idle.atlas.get_size() != Vector2(64, 256):
			_fail(tree, "Missing packaged idle animation: " + character_id)
			return
	var title := load(DevModeScript.PUBLIC_HOME) as PackedScene
	var village := JSON.parse_string(FileAccess.get_file_as_string("res://data/village/village_content.json")) as Dictionary
	for npc: Dictionary in village["npcs"]:
		if preload("res://src/presentation/art/sprite_library.gd").actor_frame(String(npc["sprite"]), Vector2.DOWN, true, 0.0) == null:
			_fail(tree, "Missing packaged NPC animation: " + String(npc["id"]))
			return
		var idle := preload("res://src/presentation/art/sprite_library.gd").actor_frame(String(npc["sprite"]), Vector2.DOWN, false, 0.0) as AtlasTexture
		if idle == null or idle.atlas.get_size() != Vector2(64, 256):
			_fail(tree, "Missing packaged NPC idle animation: " + String(npc["id"]))
			return
	for collection in ["enemies", "bosses"]:
		for enemy: Dictionary in TowerContentScript.collection(collection):
			if preload("res://src/presentation/art/sprite_library.gd").actor_frame("enemies/" + String(enemy["id"]), Vector2.DOWN, true, 0.0) == null:
				_fail(tree, "Missing packaged enemy animation: " + String(enemy["id"]))
				return
	if title == null:
		_fail(tree, "Missing public title scene")
		return
	var instance := title.instantiate()
	tree.root.add_child.call_deferred(instance)
	await tree.process_frame
	await tree.process_frame
	if instance.get_node_or_null("Menu/Play") == null or instance.get_node_or_null("Menu/Settings") == null or instance.get_node_or_null("SettingsDialog") == null:
		_fail(tree, "Public title did not initialize")
		return
	var version := preload("res://src/core/app/app_version.gd").current()
	if not str(instance.get("_game_version")).ends_with(version):
		_fail(tree, "Title version differs from packaged VERSION")
		return
	print("RELEASE_VERSION: " + version)
	print("RELEASE_PACK_OK: public boot, content, sprites and title")
	tree.quit(0)


static func _fail(tree: SceneTree, message: String) -> void:
	push_error(message)
	tree.quit(1)
