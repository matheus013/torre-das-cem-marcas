extends SceneTree

const DirectorScript := preload("res://src/gameplay/encounters/enemy_respawn_director.gd")


func _init() -> void:
	var director: RefCounted = DirectorScript.new()
	director.call("configure", {
		"interval": 10.0, "variance": 0.0, "maximum_alive": 3, "batch_size": 1,
		"minimum_player_distance": 100.0, "minimum_enemy_distance": 20.0,
		"eligible_classes": ["common", "elite"], "seed": 42,
	})
	if not bool(director.call("register_defeat", &"raspador", &"common", Vector2(200, 0))):
		_fail("Common enemy was not scheduled for respawn")
		return
	if bool(director.call("register_defeat", &"guardiao", &"boss", Vector2(300, 0))):
		_fail("Boss entered the periodic respawn queue")
		return
	var distant_players: Array[Vector2] = [Vector2.ZERO]
	var nearby_players: Array[Vector2] = [Vector2(200, 0)]
	var spawn_points: Array[Vector2] = [Vector2(200, 0)]
	var occupied: Array[Vector2] = []
	var early: Array = director.call("tick", 9.0, 2, distant_players, spawn_points, occupied)
	if not early.is_empty():
		_fail("Enemy respawned before its interval")
		return
	var blocked: Array = director.call("tick", 1.0, 2, nearby_players, spawn_points, occupied)
	if not blocked.is_empty():
		_fail("Enemy respawned too close to a player")
		return
	var requests: Array = director.call("tick", 1.0, 2, distant_players, spawn_points, occupied)
	if requests.size() != 1 or requests[0].get("definition_id", "") != &"raspador":
		_fail("Ready enemy did not produce a deterministic spawn request")
		return
	director.call("register_defeat", &"vigia", &"elite", Vector2(300, 0))
	var snapshot: Dictionary = director.call("snapshot")
	var restored: RefCounted = DirectorScript.new()
	restored.call("configure", {
		"interval": 10.0, "variance": 0.0, "maximum_alive": 3, "batch_size": 1,
		"minimum_player_distance": 100.0, "minimum_enemy_distance": 20.0,
		"eligible_classes": ["common", "elite"], "seed": 42,
	})
	if not bool(restored.call("restore", snapshot)) or int(restored.call("pending_count")) != 1:
		_fail("Respawn queue snapshot could not be restored")
		return
	print("ENEMY_RESPAWN_OK: interval, safety distance, class exclusion, capacity and snapshot validated")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
