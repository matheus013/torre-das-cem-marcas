extends SceneTree

const CombatAudioScript := preload("res://src/presentation/audio/combat_audio.gd")
const VfxLayerScript := preload("res://src/presentation/vfx/vfx_layer.gd")
const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")

## Sons que a VfxLayer dispara por conta própria.
const LAYER_CUES := ["shoot", "needle", "burst", "ring", "slash", "telegraph", "zap", "hit", "crit", "hurt", "dash"]
## Efeitos nomeados que a simulação emite via play() ou label(); cada um precisa de som e animação.
const SIM_EFFECTS := ["block", "shield", "downed", "heal", "coins", "poof", "explosion", "levelup", "stairs"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var audio: Node2D = CombatAudioScript.new()
	root.add_child(audio)
	for cue: String in CombatAudioScript.CUES:
		if not bool(audio.call("has_cue", cue)):
			return _fail("Sound has no audio files: " + cue)
	var expected: Array = LAYER_CUES.duplicate()
	expected.append_array(SIM_EFFECTS)
	for cue: String in expected:
		if not CombatAudioScript.CUES.has(cue):
			return _fail("Effect has no sound configured: " + cue)
	for effect: String in SIM_EFFECTS:
		if not VfxLayerScript.ANIMS.has(effect):
			return _fail("Simulation effect has no animation: " + effect)

	if not bool(audio.call("play", "hit", Vector2(5.0, 5.0))):
		return _fail("A configured sound must play")
	if bool(audio.call("play", "hit", Vector2(5.0, 5.0))):
		return _fail("The same sound must respect its minimum interval")
	if not bool(audio.call("play", "levelup")):
		return _fail("Global sounds must play without a position")
	if bool(audio.call("play", "som_inexistente", Vector2.ZERO)):
		return _fail("Unknown sounds must be ignored")
	for index in range(CombatAudioScript.VOICES + 8):
		audio.set("_last_played", {})
		audio.call("play", "shoot", Vector2(float(index), 0.0))
	if audio.get_child_count() != CombatAudioScript.VOICES + 4:
		return _fail("Voices must be pooled, not created per sound")

	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", 99)
	sim.call("add_player", 1)
	sim.call("enter_tower", 1)
	var enemies := sim.get("enemies") as Array
	if enemies.is_empty():
		return _fail("Tower floor has no enemies to defeat")
	var target := (enemies[0] as Dictionary)["position"] as Vector2
	sim.call("drain_events")
	sim.call("damage_enemy", 1, 0, 100000.0)
	var defeat_effect := false
	for event: Dictionary in sim.call("drain_events"):
		if String(event.get("call", "")) == "play" and (event["args"] as Array)[1] == target:
			defeat_effect = String((event["args"] as Array)[0]) in ["poof", "explosion"]
	if not defeat_effect:
		return _fail("Defeating an enemy must emit a defeat effect at its position")
	print("COMBAT_AUDIO_OK: %d sounds, pooled voices, throttling and defeat event" % CombatAudioScript.CUES.size())
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
