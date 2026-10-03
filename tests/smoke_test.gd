extends SceneTree


func _init() -> void:
	var scene := load("res://src/prototype/network/network_prototype.tscn") as PackedScene
	if scene == null:
		push_error("Prototype scene could not be loaded")
		quit(1)
		return

	var instance := scene.instantiate()
	if instance == null:
		push_error("Prototype scene could not be instantiated")
		quit(1)
		return

	root.add_child(instance)
	await process_frame

	var menu := instance.get_node_or_null("Interface/SessionMenu")
	if menu == null:
		push_error("Network session menu did not initialize correctly")
		quit(1)
		return

	print("SMOKE_OK: network scene and host-client session menu initialized")
	quit(0)
