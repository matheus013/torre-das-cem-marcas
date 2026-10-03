class_name VfxLayer
extends Node2D

## Efeitos visuais transitórios de combate. Não altera regras: só desenha o que já foi resolvido.

const SpriteLibraryScript := preload("res://src/presentation/art/sprite_library.gd")
const MAX_EFFECTS := 96
const GLOW := Color("7fd6e0")
const CORE := Color("c8f2f0")

var _effects: Array[Dictionary] = []


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	for index in range(_effects.size() - 1, -1, -1):
		var effect := _effects[index]
		effect["time"] = float(effect["time"]) + delta
		if float(effect["time"]) >= float(effect["delay"]) + float(effect["duration"]):
			_effects.remove_at(index)
	queue_redraw()


func clear() -> void:
	_effects.clear()


func active_count() -> int:
	return _effects.size()


## Projétil que voa da origem ao alvo e termina num impacto.
func travel(sprite: String, from: Vector2, to: Vector2, duration: float, impact_radius: float) -> void:
	_add({"kind": "travel", "sprite": sprite, "from": from, "to": to, "duration": duration})
	burst(to, impact_radius, duration)


func burst(position: Vector2, radius: float, delay: float = 0.0) -> void:
	_add({"kind": "burst", "sprite": "vfx/impact", "position": position, "radius": radius, "duration": 0.28, "delay": delay})


func ring(position: Vector2, radius: float) -> void:
	_add({"kind": "ring", "sprite": "vfx/shockwave", "position": position, "radius": radius, "duration": 0.35})


func spark(position: Vector2) -> void:
	_add({"kind": "burst", "sprite": "vfx/spark", "position": position + Vector2(randf_range(-6.0, 6.0), randf_range(-14.0, -4.0)), "radius": 10.0, "duration": 0.16})


func chain(raw_points: Array) -> void:
	var points: Array[Vector2] = []
	for point: Variant in raw_points:
		points.append(point as Vector2)
	if points.size() < 2:
		return
	var jagged := PackedVector2Array()
	for index in range(points.size() - 1):
		var from := points[index]
		var to := points[index + 1]
		var normal := (to - from).orthogonal().normalized()
		for step in range(6):
			var ratio := float(step) / 6.0
			jagged.append(from.lerp(to, ratio) + normal * (randf_range(-9.0, 9.0) if step > 0 else 0.0))
	jagged.append(points[-1])
	_add({"kind": "chain", "points": jagged, "duration": 0.3})
	for point in points.slice(1):
		spark(point)


## Número de dano flutuante. Críticos são maiores e vermelhos; dano sofrido usa laranja.
func number(position: Vector2, amount: float, critical: bool, kind: String = "enemy") -> void:
	var text := "%d" % maxi(1, int(round(amount)))
	if critical:
		text += "!"
	elif kind == "player":
		text = "-" + text
	_add({"kind": "number", "text": text, "position": position + Vector2(randf_range(-16.0, 16.0), randf_range(-38.0, -26.0)), "critical": critical, "style": kind, "duration": 0.95 if critical else 0.7})


func label(position: Vector2, text: String, color: Color) -> void:
	_add({"kind": "number", "text": text, "position": position + Vector2(0.0, -30.0), "critical": false, "style": "label", "color": color, "duration": 0.6})


func ghosts(texture_key: String, from: Vector2, to: Vector2, flip: bool) -> void:
	for index in range(4):
		var ratio := float(index) / 4.0
		_add({"kind": "ghost", "sprite": texture_key, "position": from.lerp(to, ratio), "flip": flip, "duration": 0.18 + ratio * 0.12})


func _add(effect: Dictionary) -> void:
	if _effects.size() >= MAX_EFFECTS:
		_effects.pop_front()
	effect["time"] = 0.0
	if not effect.has("delay"):
		effect["delay"] = 0.0
	_effects.append(effect)


func _draw() -> void:
	for effect in _effects:
		var local_time := float(effect["time"]) - float(effect["delay"])
		if local_time < 0.0:
			continue
		var progress := clampf(local_time / float(effect["duration"]), 0.0, 1.0)
		match String(effect["kind"]):
			"travel":
				_draw_travel(effect, progress)
			"burst":
				_draw_burst(effect, progress)
			"ring":
				_draw_ring(effect, progress)
			"chain":
				_draw_chain(effect, progress)
			"ghost":
				_draw_ghost(effect, progress)
			"number":
				_draw_number(effect, progress)


func _draw_travel(effect: Dictionary, progress: float) -> void:
	var from := effect["from"] as Vector2
	var to := effect["to"] as Vector2
	var position := from.lerp(to, progress)
	var direction := (to - from).normalized()
	draw_line(position - direction * 26.0, position, Color(GLOW, 0.45), 3.0)
	if not _draw_centered(String(effect["sprite"]), position, direction.angle(), 1.0, Color.WHITE):
		draw_line(position - direction * 10.0, position + direction * 6.0, CORE, 3.0)


func _draw_burst(effect: Dictionary, progress: float) -> void:
	var position := effect["position"] as Vector2
	var radius := float(effect["radius"])
	var alpha := 1.0 - progress
	var texture := SpriteLibraryScript.texture(String(effect["sprite"]))
	if texture != null:
		var scale := (radius * 2.0 / texture.get_size().x) * (0.6 + 0.5 * progress)
		_draw_centered(String(effect["sprite"]), position, 0.0, scale, Color(1.0, 1.0, 1.0, alpha))
	else:
		draw_circle(position, radius * (0.4 + 0.6 * progress), Color(CORE, alpha * 0.5))
		draw_arc(position, radius * (0.5 + 0.5 * progress), 0.0, TAU, 32, Color(GLOW, alpha), 2.0)


func _draw_ring(effect: Dictionary, progress: float) -> void:
	var position := effect["position"] as Vector2
	var radius := float(effect["radius"]) * (0.25 + 0.75 * progress)
	var alpha := 1.0 - progress * progress
	var texture := SpriteLibraryScript.texture(String(effect["sprite"]))
	if texture != null:
		_draw_centered(String(effect["sprite"]), position, 0.0, radius * 2.0 / texture.get_size().x, Color(1.0, 1.0, 1.0, alpha))
	draw_arc(position, radius, 0.0, TAU, 48, Color(GLOW, alpha), 3.0)
	draw_arc(position, radius * 0.85, 0.0, TAU, 48, Color(CORE, alpha * 0.4), 2.0)


func _draw_chain(effect: Dictionary, progress: float) -> void:
	var points := effect["points"] as PackedVector2Array
	var alpha := 1.0 - progress
	draw_polyline(points, Color(GLOW, alpha * 0.4), 7.0)
	draw_polyline(points, Color(GLOW, alpha), 3.0)
	draw_polyline(points, Color(CORE, alpha), 1.0)


func _draw_number(effect: Dictionary, progress: float) -> void:
	var critical := bool(effect["critical"])
	var style := String(effect["style"])
	var rise := (34.0 if critical else 26.0) * (1.0 - pow(1.0 - progress, 2.0))
	var position := ((effect["position"] as Vector2) - Vector2(0.0, rise)).round()
	var alpha := 1.0 if progress < 0.6 else 1.0 - (progress - 0.6) / 0.4
	var font_size := 18
	var color := Color("f2e6c9")
	if critical:
		font_size = 30 + int(round(12.0 * maxf(0.0, 1.0 - progress * 5.0)))
		color = Color("ff3b30")
	elif style == "player":
		font_size = 19
		color = Color("d9824a")
	elif style == "label":
		font_size = 14
		color = effect.get("color", Color("c9d4d6")) as Color
	var font := ThemeDB.fallback_font
	var text := String(effect["text"])
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := position - Vector2(width * 0.5, 0.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4 if critical else 3, Color(0.11, 0.1, 0.12, alpha))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, alpha))


func _draw_ghost(effect: Dictionary, progress: float) -> void:
	var texture := SpriteLibraryScript.texture(String(effect["sprite"]))
	if texture == null:
		return
	var base := (effect["position"] as Vector2).round()
	var size := texture.get_size()
	draw_set_transform(base, 0.0, Vector2(-1.0 if bool(effect["flip"]) else 1.0, 1.0))
	draw_texture(texture, Vector2(-floorf(size.x * 0.5), -size.y), Color(0.5, 0.9, 1.0, 0.55 * (1.0 - progress)))
	draw_set_transform(Vector2.ZERO)


func _draw_centered(key: String, position: Vector2, rotation: float, scale: float, tint: Color) -> bool:
	var texture := SpriteLibraryScript.texture(key)
	if texture == null:
		return false
	draw_set_transform(position.round(), rotation, Vector2.ONE * scale)
	draw_texture(texture, -texture.get_size() * 0.5, tint)
	draw_set_transform(Vector2.ZERO)
	return true
