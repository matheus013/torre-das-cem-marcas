extends SceneTree

const VfxLayerScript := preload("res://src/presentation/vfx/vfx_layer.gd")


class FakeAudio:
	extends Node
	var cues: Array[String] = []

	func play(cue: String, _position: Variant = null) -> bool:
		cues.append(cue)
		return true


func _init() -> void:
	var layer: Node2D = VfxLayerScript.new()
	var audio := FakeAudio.new()
	layer.set("audio", audio)
	root.add_child(layer)
	layer.call("number", Vector2.ZERO, 18.2, false)
	layer.call("number", Vector2.ZERO, 41.7, true)
	layer.call("number", Vector2.ZERO, 9.0, false, "player")
	var numbers := _of_kind(layer, "number")
	if numbers.size() != 3:
		_fail("Damage numbers were not queued")
		return
	if String(numbers[0]["text"]) != "18" or bool(numbers[0]["critical"]):
		_fail("Normal enemy damage style is invalid")
		return
	if String(numbers[1]["text"]) != "42!" or not bool(numbers[1]["critical"]):
		_fail("Critical damage did not receive its distinct treatment")
		return
	if String(numbers[2]["text"]) != "-9" or String(numbers[2]["style"]) != "player":
		_fail("Player damage did not receive its distinct treatment")
		return
	if _sprites(layer) != ["vfx/anim/crit", "vfx/anim/blood"]:
		_fail("Critical and player damage must play their animations: %s" % [_sprites(layer)])
		return
	if audio.cues != ["hit", "crit", "hurt"]:
		_fail("Damage numbers must cue hit, crit and hurt sounds: %s" % [audio.cues])
		return

	for key: String in VfxLayerScript.ANIMS:
		var frames := int(VfxLayerScript.anim_frames(key))
		if frames < 2:
			_fail("Animation strip missing or not a horizontal strip: " + key)
			return

	layer.call("clear")
	audio.cues.clear()
	layer.call("label", Vector2.ZERO, "BLOQUEIO", Color.WHITE, "block")
	layer.call("play", "poof", Vector2(10.0, 10.0))
	layer.call("play", "efeito_inexistente", Vector2.ZERO)
	if _sprites(layer) != ["vfx/anim/block", "vfx/anim/poof"] or audio.cues.slice(0, 2) != ["block", "poof"]:
		_fail("Labels and named effects must play animation and sound")
		return
	var poof := _of_kind(layer, "anim")[1]
	if not is_equal_approx(float(poof["duration"]), float(poof["frames"]) / 30.0):
		_fail("Animation duration must follow frame count and fps")
		return

	layer.call("clear")
	layer.call("chain", [Vector2.ZERO, Vector2(80.0, 0.0), Vector2(160.0, 0.0)])
	if _sprites(layer) != ["vfx/anim/zap", "vfx/anim/zap"]:
		_fail("Each chain link must end in a zap")
		return
	layer.call("_process", 10.0)
	if int(layer.call("active_count")) != 0:
		_fail("Finished animations must be released")
		return
	print("VFX_LAYER_OK: damage feedback, animations, sounds and cleanup validated")
	quit(0)


func _of_kind(layer: Node2D, kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect: Dictionary in layer.get("_effects") as Array:
		if String(effect["kind"]) == kind:
			result.append(effect)
	return result


func _sprites(layer: Node2D) -> Array[String]:
	var result: Array[String] = []
	for effect in _of_kind(layer, "anim"):
		result.append(String(effect["sprite"]))
	return result


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
