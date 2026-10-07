extends RefCounted

var _actors := {}


func update(key: String, position: Vector2, moving: bool, pixels_per_frame: float, identity: String = "") -> void:
	var previous: Dictionary = _actors.get(key, {"position": position, "distance": 0.0, "identity": identity})
	var distance := position.distance_to(previous["position"] as Vector2)
	if not moving or distance > 160.0 or String(previous["identity"]) != identity:
		previous["distance"] = 0.0
	else:
		previous["distance"] = fmod(float(previous["distance"]) + distance / maxf(1.0, pixels_per_frame), 4.0)
	previous["position"] = position
	previous["identity"] = identity
	_actors[key] = previous


func elapsed(key: String) -> float:
	return float((_actors.get(key, {}) as Dictionary).get("distance", 0.0)) / 8.0


func retain(keys: Array[String]) -> void:
	for key: String in _actors.keys():
		if key not in keys:
			_actors.erase(key)
