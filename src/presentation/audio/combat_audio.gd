class_name CombatAudio
extends Node2D

## Sons transitórios de combate e interface. Como a VfxLayer, só reage ao que já foi resolvido.

const ROOT := "res://assets/audio/sfx/"
const BUS := &"Effects"
const VOICES := 24
const MAX_VARIANTS := 6
const MAX_DISTANCE := 1100.0

## volume em dB; interval: segundos mínimos entre dois disparos do mesmo som;
## limit: vozes simultâneas; pitch: variação aleatória; global: ignora posição.
## O ataque automático dispara várias vezes por segundo, então sem interval/limit
## os sons frequentes viram ruído contínuo.
const CUES := {
	"shoot": {"volume": -20.0, "interval": 0.12, "limit": 2, "pitch": 0.1},
	"needle": {"volume": -14.0, "interval": 0.08, "limit": 2, "pitch": 0.08},
	"hit": {"volume": -13.0, "interval": 0.06, "limit": 3, "pitch": 0.12},
	"crit": {"volume": -8.0, "interval": 0.12, "limit": 2, "pitch": 0.06},
	"hurt": {"volume": -9.0, "interval": 0.18, "limit": 1, "pitch": 0.1},
	"block": {"volume": -10.0, "interval": 0.1, "limit": 2, "pitch": 0.08},
	"shield": {"volume": -11.0, "interval": 0.15, "limit": 1, "pitch": 0.06},
	"burst": {"volume": -11.0, "interval": 0.08, "limit": 3, "pitch": 0.1},
	"ring": {"volume": -12.0, "interval": 0.12, "limit": 2, "pitch": 0.08},
	"slash": {"volume": -12.0, "interval": 0.08, "limit": 2, "pitch": 0.1},
	"zap": {"volume": -13.0, "interval": 0.1, "limit": 2, "pitch": 0.1},
	"dash": {"volume": -12.0, "interval": 0.15, "limit": 1, "pitch": 0.08},
	"telegraph": {"volume": -16.0, "interval": 0.25, "limit": 2, "pitch": 0.05},
	"poof": {"volume": -12.0, "interval": 0.07, "limit": 3, "pitch": 0.12},
	"explosion": {"volume": -6.0, "interval": 0.5, "limit": 1, "pitch": 0.0},
	"downed": {"volume": -6.0, "interval": 0.5, "limit": 1, "pitch": 0.0},
	"heal": {"volume": -9.0, "interval": 0.3, "limit": 1, "pitch": 0.0},
	"coins": {"volume": -13.0, "interval": 0.1, "limit": 2, "pitch": 0.08},
	"levelup": {"volume": -7.0, "interval": 0.5, "limit": 1, "pitch": 0.0, "global": true},
	"stairs": {"volume": -8.0, "interval": 1.0, "limit": 1, "pitch": 0.0, "global": true},
	"denied": {"volume": -12.0, "interval": 0.35, "limit": 1, "pitch": 0.0, "global": true},
	"click": {"volume": -14.0, "interval": 0.04, "limit": 2, "pitch": 0.04, "global": true},
}

var _positional: Array[AudioStreamPlayer2D] = []
var _flat: Array[AudioStreamPlayer] = []
var _next_positional := 0
var _next_flat := 0
var _streams := {}
var _last_variant := {}
var _last_played := {}


func _ready() -> void:
	for index in range(VOICES):
		var voice := AudioStreamPlayer2D.new()
		voice.bus = BUS
		voice.max_distance = MAX_DISTANCE
		add_child(voice)
		_positional.append(voice)
	for index in range(4):
		var voice := AudioStreamPlayer.new()
		voice.bus = BUS
		add_child(voice)
		_flat.append(voice)


## Toca um som pelo nome. Retorna false quando o som não existe ou foi limitado.
func play(cue: String, position: Variant = null) -> bool:
	var config := CUES.get(cue, {}) as Dictionary
	var variants := _variants(cue)
	if config.is_empty() or variants.is_empty():
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(cue, -INF)) < float(config["interval"]):
		return false
	if _active_count(cue) >= int(config["limit"]):
		return false
	_last_played[cue] = now
	var stream := variants[_pick_variant(cue, variants.size())]
	var pitch := 1.0 + randf_range(-1.0, 1.0) * float(config["pitch"])
	if bool(config.get("global", false)) or not position is Vector2:
		var flat := _flat[_next_flat]
		_next_flat = (_next_flat + 1) % _flat.size()
		_start(flat, cue, stream, float(config["volume"]), pitch)
	else:
		var voice := _free_positional()
		voice.position = position as Vector2
		_start(voice, cue, stream, float(config["volume"]), pitch)
	return true


func has_cue(cue: String) -> bool:
	return not _variants(cue).is_empty()


func _start(voice: Node, cue: String, stream: AudioStream, volume: float, pitch: float) -> void:
	voice.set_meta("cue", cue)
	voice.set("stream", stream)
	voice.set("volume_db", volume)
	voice.set("pitch_scale", pitch)
	# O driver Dummy (headless) nunca encerra a reprodução e prende o stream até a saída.
	if AudioServer.get_driver_name() != "Dummy":
		voice.call("play")


func _free_positional() -> AudioStreamPlayer2D:
	for offset in range(_positional.size()):
		var voice := _positional[(_next_positional + offset) % _positional.size()]
		if not voice.playing:
			_next_positional = (_next_positional + offset + 1) % _positional.size()
			return voice
	# Todas ocupadas: rouba a mais antiga em rodízio.
	var stolen := _positional[_next_positional]
	_next_positional = (_next_positional + 1) % _positional.size()
	return stolen


func _active_count(cue: String) -> int:
	var count := 0
	for voice: Node in get_children():
		if bool(voice.get("playing")) and String(voice.get_meta("cue", "")) == cue:
			count += 1
	return count


func _pick_variant(cue: String, count: int) -> int:
	var choice := randi() % count
	if count > 1 and choice == int(_last_variant.get(cue, -1)):
		choice = (choice + 1) % count
	_last_variant[cue] = choice
	return choice


func _variants(cue: String) -> Array[AudioStream]:
	if _streams.has(cue):
		return _streams[cue]
	var result: Array[AudioStream] = []
	for index in range(1, MAX_VARIANTS + 1):
		var path := "%s%s_%d.wav" % [ROOT, cue, index]
		if ResourceLoader.exists(path):
			result.append(load(path) as AudioStream)
	_streams[cue] = result
	return result
