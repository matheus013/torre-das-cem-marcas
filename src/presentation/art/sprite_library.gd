class_name SpriteLibrary
extends RefCounted

const ROOT := "res://assets/sprites/"
const CHARACTER_FRAME_SIZE := 64
const CHARACTER_FOOT_ANCHOR := Vector2(32.0, 61.0)
const WALK_FPS := 8.0

static var _cache := {}
static var _frame_cache := {}


static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key] as Texture2D
	var path := ROOT + key + ".png"
	var result: Texture2D = null
	if ResourceLoader.exists(path):
		result = load(path) as Texture2D
	_cache[key] = result
	return result


static func character_frame(character_id: String, direction: Vector2, moving: bool, elapsed: float) -> Texture2D:
	return actor_frame("characters/" + character_id, direction, moving, elapsed)


static func actor_frame(actor_key: String, direction: Vector2, moving: bool, elapsed: float) -> Texture2D:
	var parts := actor_key.split("/")
	if parts.size() != 2 or parts[0] not in ["characters", "npcs", "enemies"]:
		return null
	var atlas := texture(parts[0] + "/animations/" + parts[1] + "_walk")
	if atlas == null or atlas.get_size() != Vector2(256.0, 256.0):
		return null
	var row := direction_row(direction)
	var column := posmod(int(floor(elapsed * WALK_FPS)), 4) if moving else 1
	var key := "%s:%d:%d" % [actor_key, row, column]
	if not _frame_cache.has(key):
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(column * CHARACTER_FRAME_SIZE, row * CHARACTER_FRAME_SIZE, CHARACTER_FRAME_SIZE, CHARACTER_FRAME_SIZE)
		_frame_cache[key] = frame
	return _frame_cache[key] as Texture2D


static func direction_row(direction: Vector2) -> int:
	if direction.is_zero_approx():
		return 0
	if absf(direction.x) > absf(direction.y):
		return 1 if direction.x < 0.0 else 2
	return 3 if direction.y < 0.0 else 0
