extends SceneTree

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for id in ["eloa", "sena", "cira", "rui"]:
		var sheet := Sprites.texture("characters/animations/" + id + "_walk")
		if sheet == null or sheet.get_size() != Vector2(256.0, 256.0):
			return _fail("Invalid atlas: " + id)
		var image := sheet.get_image()
		var directions := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]
		for row in range(4):
			var hashes := {}
			for column in range(4):
				var frame := Sprites.character_frame(id, directions[row], true, float(column) / 8.0) as AtlasTexture
				if frame == null or frame.region != Rect2(column * 64, row * 64, 64, 64):
					return _fail("Wrong animation region")
				var pixels := image.get_region(Rect2i(column * 64, row * 64, 64, 64))
				var used := pixels.get_used_rect()
				if used.size == Vector2i.ZERO or used.size.y > 48 or used.end.y != 61 or used.position.x < 1 or used.end.x >= 64:
					return _fail("Empty, clipped or unaligned frame: %s %d %d" % [id, row, column])
				hashes[pixels.get_data().hex_encode().sha256_text()] = true
				if frame != Sprites.character_frame(id, directions[row], true, float(column) / 8.0):
					return _fail("Animation frame not cached")
			if hashes.size() != 4:
				return _fail("Duplicate walk poses: " + id)
			var idle := Sprites.character_frame(id, directions[row], false, 5.0) as AtlasTexture
			if idle.region.position != Vector2(64.0, float(row) * 64.0):
				return _fail("Idle must retain direction and stop cycling")
	if Sprites.character_frame("missing", Vector2.DOWN, true, 0.0) != null:
		return _fail("Missing sheet must allow static fallback")
	if Sprites.direction_row(Vector2.ZERO) != 0 or Sprites.direction_row(Vector2(-1.0, -0.2)) != 1:
		return _fail("Invalid direction selection")
	var sim := Simulation.new()
	sim.setup(4242)
	sim.add_player(1)
	var state := sim.player(1)
	for direction in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		sim.set_move_target(1, (state["position"] as Vector2) + direction * 20.0)
		sim.step(0.1)
		if not bool(state["moving"]) or (state["facing_direction"] as Vector2).dot(direction) < 0.99:
			return _fail("Movement direction not recorded")
		var snapshot := sim.view_snapshot()
		if (snapshot["players"][1]["facing_direction"] as Vector2).dot(direction) < 0.99:
			return _fail("Co-op snapshot omits facing")
		sim.set_move_target(1, state["position"] as Vector2)
		sim.step(0.1)
		if bool(state["moving"]) or (state["facing_direction"] as Vector2).dot(direction) < 0.99:
			return _fail("Idle lost last direction")
	print("CHARACTER_ANIMATION_OK: 64 unique poses, anchors, cache, idle and co-op facing")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
