extends SceneTree

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Slicer := preload("res://tools/art/animation_sheet_slicer.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://art/actor-animations.json")) as Dictionary
	var counts := {"npcs": 0, "enemies": 0}
	var keys := {}
	var directions := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]
	for actor: Dictionary in catalog["actors"]:
		var key := String(actor["group"]) + "/" + String(actor["id"])
		if keys.has(key) or not FileAccess.file_exists("res://art/" + String(actor["source"])):
			return _fail("Duplicate or missing source: " + key)
		keys[key] = true
		counts[actor["group"]] += 1
		var atlas := Sprites.texture(String(actor["group"]) + "/animations/" + String(actor["id"]) + "_walk")
		if atlas == null or atlas.get_size() != Vector2(256, 256):
			return _fail("Missing atlas: " + key)
		var image := atlas.get_image()
		for row in range(4):
			var hashes := {}
			for column in range(4):
				var frame := Sprites.actor_frame(key, directions[row], true, float(column) / 8.0) as AtlasTexture
				if frame == null or frame.region != Rect2(column * 64, row * 64, 64, 64):
					return _fail("Wrong frame: " + key)
				if frame != Sprites.actor_frame(key, directions[row], true, float(column) / 8.0):
					return _fail("Uncached frame: " + key)
				var pixels := image.get_region(Rect2i(column * 64, row * 64, 64, 64))
				var bounds := pixels.get_used_rect()
				if bounds.size == Vector2i.ZERO or bounds.size.y > 48 or bounds.end.y != 61 or bounds.position.x < 1 or bounds.end.x >= 64:
					return _fail("Empty, clipped or unaligned frame: " + key)
				hashes[pixels.get_data().hex_encode().sha256_text()] = true
			if hashes.size() != 4:
				return _fail("Duplicate locomotion phases: " + key)
			var idle := Sprites.actor_frame(key, directions[row], false, 50.0) as AtlasTexture
			if idle.region.position != Vector2(64, row * 64):
				return _fail("Idle cycles or loses direction: " + key)
	if counts != {"npcs": 17, "enemies": 55}:
		return _fail("Incomplete actor catalog")
	for group in counts:
		for file in DirAccess.get_files_at("res://assets/sprites/" + String(group)):
			if file.ends_with(".png") and not keys.has(String(group) + "/" + file.trim_suffix(".png")):
				return _fail("Static actor not animated: " + file)
	for key in ["invalid", "icons/rui", "enemies/missing", "../rui"]:
		if Sprites.actor_frame(key, Vector2.DOWN, true, 0.0) != null:
			return _fail("Invalid actor key accepted")
	var sim := Simulation.new()
	sim.setup(4242)
	var enemy := {"position": Vector2.ZERO}
	if not sim._move_enemy(enemy, Vector2.LEFT * 10.0) or enemy.get("facing_direction") != Vector2.LEFT or not bool(enemy.get("moving", false)):
		return _fail("Enemy motion omits facing")
	# Unequal generated gutters must preserve complete silhouettes and row order.
	var source := Image.create_empty(400, 400, false, Image.FORMAT_RGBA8)
	for row in range(4):
		for column in range(4):
			var top := [10, 100, 190, 290][row] as int
			source.fill_rect(Rect2i(column * 100 + 20, top, 40, 80), Color.WHITE)
	var frames := Slicer.frames(source)
	if frames.size() != 16:
		return _fail("Slicer lost frames")
	for frame in frames:
		if frame.get_used_rect().size != Vector2i(40, 80):
			return _fail("Unequal gutter sliced a silhouette")
	print("ACTOR_ANIMATION_OK: 17 NPCs, 55 enemies, 1152 unique poses, anchors, cache, idle, facing and gutters")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
