extends SceneTree

const VfxLayerScript := preload("res://src/presentation/vfx/vfx_layer.gd")


func _init() -> void:
	var layer: Node2D = VfxLayerScript.new()
	root.add_child(layer)
	layer.call("number", Vector2.ZERO, 18.2, false)
	layer.call("number", Vector2.ZERO, 41.7, true)
	layer.call("number", Vector2.ZERO, 9.0, false, "player")
	var effects := layer.get("_effects") as Array
	if effects.size() != 3:
		_fail("Damage numbers were not queued")
		return
	if String(effects[0]["text"]) != "18" or bool(effects[0]["critical"]):
		_fail("Normal enemy damage style is invalid")
		return
	if String(effects[1]["text"]) != "42!" or not bool(effects[1]["critical"]):
		_fail("Critical damage did not receive its distinct treatment")
		return
	if String(effects[2]["text"]) != "-9" or String(effects[2]["style"]) != "player":
		_fail("Player damage did not receive its distinct treatment")
		return
	print("VFX_LAYER_OK: normal, critical and player damage feedback validated")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
