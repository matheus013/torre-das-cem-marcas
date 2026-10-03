class_name SpriteLibrary
extends RefCounted

const ROOT := "res://assets/sprites/"

static var _cache := {}


static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key] as Texture2D
	var path := ROOT + key + ".png"
	var result: Texture2D = null
	if ResourceLoader.exists(path):
		result = load(path) as Texture2D
	_cache[key] = result
	return result
