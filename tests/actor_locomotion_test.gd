extends SceneTree

const Locomotion := preload("res://src/presentation/art/actor_locomotion.gd")


func _init() -> void:
	var clock := Locomotion.new()
	clock.update("a", Vector2(1000, 500), true, 10)
	assert(clock.elapsed("a") == 0.0)
	clock.update("a", Vector2(1010, 500), true, 10)
	assert(is_equal_approx(clock.elapsed("a"), 0.125))
	clock.update("b", Vector2(5000, 0), true, 10)
	assert(clock.elapsed("b") == 0.0)
	clock.update("a", Vector2(1010, 500), false, 10)
	assert(clock.elapsed("a") == 0.0)
	clock.update("a", Vector2(1020, 500), true, 10)
	clock.update("a", Vector2(3000, 500), true, 10)
	assert(clock.elapsed("a") == 0.0)
	clock.update("a", Vector2(3010, 500), true, 10, "new_actor")
	assert(clock.elapsed("a") == 0.0)
	clock.retain([])
	assert(clock._actors.is_empty())
	print("ACTOR_LOCOMOTION_OK: independent distance, stop, teleport, identity and cleanup")
	quit(0)
