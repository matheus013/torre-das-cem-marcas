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
	var atlas := texture("characters/animations/" + character_id + "_walk")
	if atlas == null or atlas.get_size() != Vector2(256.0, 256.0):
		return null
	var row := direction_row(direction)
	var column := posmod(int(floor(elapsed * WALK_FPS)), 4) if moving else 1
	var key := "%s:%d:%d" % [character_id, row, column]
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
