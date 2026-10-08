class_name VfxLayer
extends Node2D

## Efeitos visuais transitórios de combate. Não altera regras: só desenha o que já foi resolvido.

const SpriteLibraryScript := preload("res://src/presentation/art/sprite_library.gd")
const SkillThemesScript := preload("res://src/presentation/vfx/skill_themes.gd")
const MAX_EFFECTS := 160
const GLOW := Color("7fd6e0")
const CORE := Color("c8f2f0")
const ANIM_ROOT := "vfx/anim/"

## Tiras horizontais de quadros quadrados em assets/sprites/vfx/anim. Sem a arte,
## a animação simplesmente não aparece e os traços procedurais continuam valendo.
const ANIMS := {
	"sk_flame_field": {"fps": 8.0},
	"sk_acid_pool": {"fps": 6.0},
	"sk_gravity_field": {"fps": 8.0},
	"sk_root_field": {"fps": 5.0},
	"sk_holy_field": {"fps": 6.0},
	"sk_living_field": {"fps": 5.0},
	"sk_steel_blade": {"fps": 8.0},
	"sk_ice_crystal": {"fps": 8.0},
	"hit": {"fps": 24.0, "spin": true},
	"crit": {"fps": 20.0, "scale": 1.5},
	"burst": {"fps": 20.0},
	"block": {"fps": 15.0, "offset": Vector2(0.0, -16.0)},
	"zap": {"fps": 24.0},
	"blood": {"fps": 20.0, "offset": Vector2(0.0, -18.0)},
	"poof": {"fps": 30.0, "offset": Vector2(0.0, -12.0)},
	"explosion": {"fps": 15.0, "scale": 3.0, "offset": Vector2(0.0, -20.0)},
	"downed": {"fps": 15.0, "scale": 1.5, "offset": Vector2(0.0, -28.0)},
	"heal": {"fps": 24.0, "offset": Vector2(0.0, -24.0)},
	"shield": {"fps": 24.0, "offset": Vector2(0.0, -24.0)},
	"coins": {"fps": 30.0, "offset": Vector2(0.0, -20.0)},
	"levelup": {"fps": 20.0, "scale": 1.5, "offset": Vector2(0.0, -24.0)},
	"stairs": {"sprite": "levelup", "fps": 15.0, "scale": 2.0},
	# Elementos das gemas (SkillThemes). frame_width: quadros não quadrados; extent: diâmetro
	# visível em px, para ajustar a explosão ao raio; anchor bottom: sobe do chão a partir do alvo.
	"fire_bolt": {"sprite": "el_fire_bolt", "fps": 14.0},
	"fire_hit": {"sprite": "el_fire_hit", "fps": 18.0, "extent": 40.0},
	"fire_blast": {"sprite": "el_fire_blast", "fps": 20.0, "extent": 44.0},
	"ice_ball": {"sprite": "el_ice_ball", "fps": 10.0, "scale": 0.45},
	"ice_burst": {"sprite": "el_ice_burst", "fps": 16.0, "extent": 100.0},
	"energy_ball": {"sprite": "el_energy_ball", "fps": 16.0, "scale": 0.4},
	"energy_hit": {"sprite": "el_energy_hit", "fps": 18.0, "extent": 90.0},
	"acid_bolt": {"sprite": "el_acid_bolt", "fps": 14.0},
	"acid_hit": {"sprite": "el_acid_hit", "fps": 16.0, "extent": 30.0},
	"dark_bolt": {"sprite": "el_dark_bolt", "fps": 14.0, "frame_width": 40.0},
	"dark_hit": {"sprite": "el_dark_hit", "fps": 14.0, "frame_width": 40.0, "extent": 32.0},
	"dark_rise": {"sprite": "el_dark_rise", "fps": 16.0, "frame_width": 48.0, "extent": 44.0, "anchor": "bottom"},
	"holy_bolt": {"sprite": "el_holy_bolt", "fps": 14.0},
	"holy_hit": {"sprite": "el_holy_hit", "fps": 16.0, "extent": 30.0},
	"holy_pillar": {"sprite": "el_holy_pillar", "fps": 18.0, "extent": 40.0},
	"wood_bolt": {"sprite": "el_wood_bolt", "fps": 12.0},
	"wood_hit": {"sprite": "el_wood_hit", "fps": 16.0, "extent": 30.0},
	"wood_roots": {"sprite": "el_wood_roots", "fps": 16.0, "extent": 32.0},
	"earth_bump": {"sprite": "el_earth_bump", "fps": 18.0, "extent": 44.0},
	"thunder_strike": {"sprite": "el_thunder_strike", "fps": 14.0, "frame_width": 128.0, "extent": 110.0, "anchor": "bottom"},
	"lightning_link": {"sprite": "el_lightning_link", "fps": 16.0, "frame_width": 256.0},
	"light_beam": {"sprite": "el_light_beam", "fps": 16.0},
	"magic_circle": {"sprite": "el_magic_circle", "fps": 10.0, "extent": 64.0},
	# Folhas de 9 cores (sheet): quadros 64x64, a linha vem do elemento do tema (SkillThemes.row).
	"sh_arrow": {"sprite": "sh_arrow", "fps": 20.0, "sheet": true, "scale": 0.9},
	"sh_comet": {"sprite": "sh_comet", "fps": 14.0, "sheet": true, "scale": 1.4},
	"sh_cast": {"sprite": "sh_cast", "fps": 24.0, "sheet": true, "extent": 48.0, "scale": 0.9},
	"sh_nova": {"sprite": "sh_nova", "fps": 18.0, "sheet": true, "extent": 56.0},
	"sh_sparks": {"sprite": "sh_sparks", "fps": 20.0, "sheet": true, "extent": 52.0},
	"sh_slash": {"sprite": "sh_slash", "fps": 22.0, "sheet": true, "extent": 50.0},
	"sh_star": {"sprite": "sh_star", "fps": 20.0, "sheet": true},
	"sh_pulse": {"sprite": "sh_pulse", "fps": 16.0, "sheet": true},
	"sh_summon": {"sprite": "sh_summon", "fps": 16.0, "sheet": true, "extent": 52.0, "scale": 1.2},
	"sh_ripple": {"sprite": "sh_ripple", "fps": 18.0, "sheet": true, "extent": 60.0, "scale": 1.3},
	"sh_vortex": {"sprite": "sh_vortex", "fps": 18.0, "sheet": true, "extent": 52.0},
	"sh_fountain": {"sprite": "sh_fountain", "fps": 18.0, "sheet": true, "extent": 30.0, "anchor": "bottom"},
	"sh_rune": {"sprite": "sh_rune", "fps": 16.0, "sheet": true, "extent": 52.0},
}

## Nó com play(cue, position); opcional, para a camada funcionar sem áudio em testes.
var audio: Node = null
## Gema do evento em curso (vem da simulação); escolhe o tema visual por elemento.
var theme := ""
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
	var bolt := "sh_arrow" if sprite == "vfx/arrow" else String(_theme().get("projectile", ""))
	if anim_frames(bolt) > 0:
		var config := ANIMS[bolt] as Dictionary
		_add({"kind": "projectile", "sprite": ANIM_ROOT + String(config["sprite"]), "from": from, "to": to, "frames": anim_frames(bolt),
			"frame_width": _frame_width(bolt), "frame_height": _frame_height(bolt), "row": _row(bolt), "tint": _sheet_tint(bolt),
			"fps": float(config["fps"]), "scale": float(config.get("scale", 1.0)), "duration": duration})
		if not _theme_anim("impact", to, maxf(impact_radius, 16.0), duration):
			_impact(to, impact_radius, duration)
	else:
		_add({"kind": "travel", "sprite": sprite, "from": from, "to": to, "duration": duration})
		_impact(to, impact_radius, duration)
	_cue("needle" if sprite == "vfx/needle" else "shoot", from)


func burst(position: Vector2, radius: float, delay: float = 0.0) -> void:
	if not _theme_anim("burst", position, radius, delay):
		_impact(position, radius, delay)
		_anim("burst", position, delay, clampf(roundf(radius * 2.0 / 48.0), 1.0, 3.0))
	_cue("burst", position)


## Impacto de meteoro: o ataque do céu do elemento, ou a explosão comum, com faíscas por cima.
func strike(position: Vector2, radius: float) -> void:
	_anim("sh_sparks", position, 0.0, _fit("sh_sparks", radius))
	if _theme_anim("strike", position, radius):
		_cue("burst", position)
	else:
		burst(position, radius)


## Círculo de conjuração aos pés de quem lança qualquer gema, na cor do elemento.
func cast(position: Vector2) -> void:
	_anim("sh_cast", position + Vector2(0.0, 8.0))


## Invocação: redemoinho no ponto onde a criatura surge.
func summon(position: Vector2) -> void:
	_anim("sh_summon", position)
	_cue("burst", position)


func ring(position: Vector2, radius: float) -> void:
	_add({"kind": "ring", "sprite": "vfx/shockwave", "position": position, "radius": radius, "duration": 0.35, "tint": _tint()})
	_anim("sh_nova", position, 0.0, _fit("sh_nova", radius))
	_theme_anim("burst", position, radius)
	_cue("ring", position)


func cone(position: Vector2, direction: Vector2, radius: float, angle: float) -> void:
	_add({"kind": "cone", "position": position, "direction": direction, "radius": radius, "angle": angle, "duration": 0.3, "tint": _tint()})
	# Meia-lua apontada para a frente do corte.
	_anim("sh_slash", position + direction * radius * 0.45, 0.0, _fit("sh_slash", radius * 0.6), direction.angle())
	if not _theme().is_empty():
		for step in [-0.35, 0.0, 0.35]:
			var spot := position + direction.rotated(angle * float(step)) * radius * 0.65
			_theme_anim("impact", spot, radius * 0.25)
	_cue("slash", position)


## Feixe reto da origem até o fim, esticando a tira do elemento.
func beam(from: Vector2, to: Vector2, width: float) -> void:
	var key := String(_theme().get("beam", "light_beam"))
	if anim_frames(key) > 0:
		_add_stretch(key, from, to, maxf(0.5, width / 32.0), _tint())
	else:
		chain([from, to])
		return
	_theme_anim("impact", to, 20.0)
	_cue("zap", from)


func target_ring(position: Vector2, radius: float, duration: float) -> void:
	_add({"kind": "target_ring", "position": position, "radius": radius, "duration": duration, "tint": _tint()})
	# Cometa caindo durante o aviso: a folha já vem inclinada, cabeça embaixo à esquerda.
	if String(_theme().get("telegraph", "")) == "sh_comet" and anim_frames("sh_comet") > 0:
		var config := ANIMS["sh_comet"] as Dictionary
		_add({"kind": "projectile", "sprite": ANIM_ROOT + String(config["sprite"]), "from": position + Vector2(130.0, -240.0), "to": position,
			"frames": anim_frames("sh_comet"), "frame_width": 64.0, "frame_height": 64.0, "row": _row("sh_comet"), "tint": _sheet_tint("sh_comet"),
			"fps": float(config["fps"]), "scale": float(config["scale"]), "duration": duration, "fixed": true})
	_cue("telegraph", position)


func spark(position: Vector2) -> void:
	var spot := position + Vector2(randf_range(-6.0, 6.0), randf_range(-14.0, -4.0))
	if not _anim("hit", spot):
		_add({"kind": "burst", "sprite": "vfx/spark", "position": spot, "radius": 10.0, "duration": 0.16})


## Efeito nomeado sem geometria própria (abate, nível, escada): animação e som.
func play(key: String, position: Vector2) -> void:
	_anim(key, position)
	_cue(key, position)


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
	var link := String(_theme().get("link", ""))
	if anim_frames(link) > 0:
		for index in range(points.size() - 1):
			_add_stretch(link, points[index], points[index + 1], 0.35, Color.WHITE)
	else:
		_add({"kind": "chain", "points": jagged, "duration": 0.3, "tint": _tint()})
	for point in points.slice(1):
		if not _theme_anim("impact", point, 18.0) and not _anim("zap", point):
			spark(point)
	_cue("zap", points[-1])


## Número de dano flutuante. Críticos são maiores e vermelhos; dano sofrido usa laranja.
func number(position: Vector2, amount: float, critical: bool, kind: String = "enemy") -> void:
	var text := "%d" % maxi(1, int(round(amount)))
	if critical:
		text += "!"
	elif kind == "player":
		text = "-" + text
	_add({"kind": "number", "text": text, "position": position + Vector2(randf_range(-16.0, 16.0), randf_range(-38.0, -26.0)), "critical": critical, "style": kind, "duration": 0.95 if critical else 0.7})
	if kind == "player":
		_anim("blood", position)
		_cue("hurt", position)
	elif critical:
		_anim("crit", position + Vector2(0.0, -16.0))
		_cue("crit", position)
	else:
		_cue("hit", position)


## Texto curto sobre o alvo; anim nomeia um efeito de ANIMS que reforça o significado.
func label(position: Vector2, text: String, color: Color, anim: String = "") -> void:
	_add({"kind": "number", "text": text, "position": position + Vector2(0.0, -30.0), "critical": false, "style": "label", "color": color, "duration": 0.6})
	if not anim.is_empty():
		play(anim, position)


func ghosts(texture_key: String, from: Vector2, to: Vector2, flip: bool) -> void:
	for index in range(4):
		var ratio := float(index) / 4.0
		_add({"kind": "ghost", "sprite": texture_key, "position": from.lerp(to, ratio), "flip": flip, "duration": 0.18 + ratio * 0.12})
	_anim("sh_ripple", to + Vector2(0.0, 10.0))
	_cue("dash", from)


## Quantos quadros a tira de um efeito tem; 0 quando a arte não existe.
static func anim_frames(key: String) -> int:
	if not ANIMS.has(key):
		return 0
	var texture := SpriteLibraryScript.texture(ANIM_ROOT + String((ANIMS[key] as Dictionary).get("sprite", key)))
	if texture == null or texture.get_height() <= 0:
		return 0
	return int(texture.get_width() / _frame_width(key))


static func _frame_height(key: String) -> float:
	var config := ANIMS.get(key, {}) as Dictionary
	if bool(config.get("sheet", false)):
		return 64.0
	var texture := SpriteLibraryScript.texture(ANIM_ROOT + String(config.get("sprite", key)))
	return float(texture.get_height()) if texture != null else 1.0


static func _frame_width(key: String) -> float:
	var config := ANIMS.get(key, {}) as Dictionary
	var texture := SpriteLibraryScript.texture(ANIM_ROOT + String(config.get("sprite", key)))
	if bool(config.get("sheet", false)):
		return 64.0
	return float(config.get("frame_width", texture.get_height() if texture != null else 1.0))


func _impact(position: Vector2, radius: float, delay: float) -> void:
	_add({"kind": "burst", "sprite": "vfx/impact", "position": position, "radius": radius, "duration": 0.28, "delay": delay})


func _anim(key: String, position: Vector2, delay: float = 0.0, size: float = 0.0, angle: float = INF) -> bool:
	var config := ANIMS.get(key, {}) as Dictionary
	var frames := anim_frames(key)
	if config.is_empty() or frames <= 0:
		return false
	var scale_value := size if size > 0.0 else float(config.get("scale", 1.0))
	var frame_height := _frame_height(key)
	var anchor := Vector2(0.0, -frame_height * scale_value * 0.5) if String(config.get("anchor", "")) == "bottom" else Vector2.ZERO
	_add({
		"kind": "anim",
		"sprite": ANIM_ROOT + String(config.get("sprite", key)),
		"position": position + (config.get("offset", Vector2.ZERO) as Vector2) + anchor,
		"frames": frames,
		"frame_width": _frame_width(key),
		"frame_height": frame_height,
		"row": _row(key),
		"tint": _sheet_tint(key),
		"rotation": angle if angle != INF else (randf() * TAU if bool(config.get("spin", false)) else 0.0),
		"scale": scale_value,
		"duration": float(frames) / float(config["fps"]),
		"delay": delay,
	})
	return true


## Linha da folha de 9 cores para o tema atual; 0 para tiras de uma linha.
func _row(key: String) -> int:
	return SkillThemesScript.row(theme) if bool((ANIMS.get(key, {}) as Dictionary).get("sheet", false)) else 0


func _sheet_tint(key: String) -> Color:
	return SkillThemesScript.sheet_tint(theme) if bool((ANIMS.get(key, {}) as Dictionary).get("sheet", false)) else Color.WHITE


func _fit(key: String, radius: float) -> float:
	return clampf(snappedf(radius * 1.8 / float((ANIMS[key] as Dictionary).get("extent", 48.0)), 0.25), 0.5, 2.5)


## Quadros de folhas elementais ou tiras individuais para efeitos persistentes.
static func sheet_frame(key: String, theme_id: String, time: float) -> Dictionary:
	var config := ANIMS.get(key, {}) as Dictionary
	var texture := SpriteLibraryScript.texture(ANIM_ROOT + String(config.get("sprite", key)))
	if texture == null:
		return {}
	var width := _frame_width(key)
	var height := _frame_height(key)
	var frames := maxi(1, int(texture.get_width() / width))
	var frame := int(time * float(config.get("fps", 12.0))) % frames
	var row := SkillThemesScript.row(theme_id) if bool(config.get("sheet", false)) else 0
	var tint := SkillThemesScript.sheet_tint(theme_id) if bool(config.get("sheet", false)) else Color.WHITE
	return {"texture": texture, "region": Rect2(frame * width, row * height, width, height), "tint": tint}


func _theme() -> Dictionary:
	return SkillThemesScript.for_gem(theme)


func _tint() -> Color:
	return SkillThemesScript.tint(theme, GLOW)


## Toca o papel do tema (impact, burst, strike) ajustado ao raio. Falso sem tema ou arte.
func _theme_anim(role: String, position: Vector2, radius: float, delay: float = 0.0) -> bool:
	var key := String(_theme().get(role, ""))
	if anim_frames(key) <= 0:
		return false
	var extent := float((ANIMS[key] as Dictionary).get("extent", 32.0))
	# Acima de 2,5x a pixel art vira blocos; o anel procedural continua marcando o raio real.
	return _anim(key, position, delay, clampf(snappedf(radius * 1.8 / extent, 0.25), 0.5, 2.5))


func _add_stretch(key: String, from: Vector2, to: Vector2, thickness: float, tint: Color) -> void:
	var config := ANIMS[key] as Dictionary
	_add({"kind": "stretch", "sprite": ANIM_ROOT + String(config["sprite"]), "from": from, "to": to, "frames": anim_frames(key),
		"frame_width": _frame_width(key), "thickness": thickness, "tint": tint, "duration": float(anim_frames(key)) / float(config["fps"])})


func _cue(key: String, position: Vector2) -> void:
	if audio != null:
		audio.call("play", key, position)


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
		var glow := effect.get("tint", GLOW) as Color
		var core := glow.lerp(Color.WHITE, 0.55)
		match String(effect["kind"]):
			"travel":
				_draw_travel(effect, progress)
			"burst":
				_draw_burst(effect, progress)
			"ring":
				_draw_ring(effect, progress)
			"cone":
				var center: Vector2 = effect["position"]
				var heading := (effect["direction"] as Vector2).angle()
				var half := float(effect["angle"]) * 0.5
				var radius := float(effect["radius"])
				draw_arc(center, radius, heading - half, heading + half, 24, Color(glow, 1.0 - progress), 3.0)
				for edge in [-half, half]:
					draw_line(center, center + Vector2.RIGHT.rotated(heading + edge) * radius, Color(core, 1.0 - progress), 2.0)
			"target_ring":
				var center: Vector2 = effect["position"]
				var radius := float(effect["radius"])
				draw_arc(center, radius, 0, TAU, 32, Color(glow, 0.45), 2.0)
				draw_arc(center, radius * (1.0 - progress), 0, TAU, 32, core, 2.0)
			"chain":
				_draw_chain(effect, progress)
			"ghost":
				_draw_ghost(effect, progress)
			"number":
				_draw_number(effect, progress)
			"anim":
				_draw_anim(effect, local_time)
			"projectile":
				_draw_projectile(effect, local_time, progress)
			"stretch":
				_draw_stretch(effect, local_time)


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
	var glow := effect.get("tint", GLOW) as Color
	var core := glow.lerp(Color.WHITE, 0.55)
	var texture := SpriteLibraryScript.texture(String(effect["sprite"]))
	if texture != null:
		_draw_centered(String(effect["sprite"]), position, 0.0, radius * 2.0 / texture.get_size().x, Color(1.0, 1.0, 1.0, alpha))
	draw_arc(position, radius, 0.0, TAU, 48, Color(glow, alpha), 3.0)
	draw_arc(position, radius * 0.85, 0.0, TAU, 48, Color(core, alpha * 0.4), 2.0)


func _draw_chain(effect: Dictionary, progress: float) -> void:
	var points := effect["points"] as PackedVector2Array
	var alpha := 1.0 - progress
	var glow := effect.get("tint", GLOW) as Color
	var core := glow.lerp(Color.WHITE, 0.55)
	draw_polyline(points, Color(glow, alpha * 0.4), 7.0)
	draw_polyline(points, Color(glow, alpha), 3.0)
	draw_polyline(points, Color(core, alpha), 1.0)


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
	elif style == "poison":
		font_size = 15
		color = Color("8fe05a")
	elif style == "burn":
		font_size = 15
		color = Color("ff9a3c")
	var font := ThemeDB.fallback_font
	var text := String(effect["text"])
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := position - Vector2(width * 0.5, 0.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4 if critical else 3, Color(0.11, 0.1, 0.12, alpha))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, alpha))


func _draw_anim(effect: Dictionary, local_time: float) -> void:
	var texture := SpriteLibraryScript.texture(String(effect["sprite"]))
	if texture == null:
		return
	var frames := int(effect["frames"])
	var frame := mini(int(local_time / float(effect["duration"]) * frames), frames - 1)
	var size := Vector2(float(effect.get("frame_width", texture.get_height())), float(effect.get("frame_height", texture.get_height())))
	draw_set_transform((effect["position"] as Vector2).round(), float(effect["rotation"]), Vector2.ONE * float(effect["scale"]))
	draw_texture_rect_region(texture, Rect2(-size * 0.5, size), Rect2(frame * size.x, int(effect.get("row", 0)) * size.y, size.x, size.y), effect.get("tint", Color.WHITE) as Color)
	draw_set_transform(Vector2.ZERO)


## Projétil animado em loop, voando e apontando na direção do alvo.
func _draw_projectile(effect: Dictionary, local_time: float, progress: float) -> void:
	var texture := SpriteLibraryScript.texture(String(effect["sprite"]))
	if texture == null:
		return
	var from := effect["from"] as Vector2
	var to := effect["to"] as Vector2
	var frames := int(effect["frames"])
	# Cometas tocam a animação uma vez ao longo da queda; projéteis repetem em loop.
	var frame := mini(int(progress * frames), frames - 1) if bool(effect.get("fixed", false)) else int(local_time * float(effect["fps"])) % frames
	var size := Vector2(float(effect["frame_width"]), float(effect.get("frame_height", texture.get_height())))
	var angle := 0.0 if bool(effect.get("fixed", false)) else (to - from).angle()
	draw_set_transform(from.lerp(to, progress).round(), angle, Vector2.ONE * float(effect["scale"]))
	draw_texture_rect_region(texture, Rect2(-size * 0.5, size), Rect2(frame * size.x, int(effect.get("row", 0)) * size.y, size.x, size.y), effect.get("tint", Color.WHITE) as Color)
	draw_set_transform(Vector2.ZERO)


## Tira esticada de um ponto a outro: raio entre alvos ou feixe.
func _draw_stretch(effect: Dictionary, local_time: float) -> void:
	var texture := SpriteLibraryScript.texture(String(effect["sprite"]))
	if texture == null:
		return
	var from := effect["from"] as Vector2
	var to := effect["to"] as Vector2
	var frames := int(effect["frames"])
	var frame := mini(int(local_time / float(effect["duration"]) * frames), frames - 1)
	var size := Vector2(float(effect["frame_width"]), float(texture.get_height()))
	draw_set_transform(from.round(), (to - from).angle(), Vector2(from.distance_to(to) / size.x, float(effect["thickness"])))
	draw_texture_rect_region(texture, Rect2(Vector2(0.0, -size.y * 0.5), size), Rect2(frame * size.x, 0.0, size.x, size.y), effect["tint"] as Color)
	draw_set_transform(Vector2.ZERO)


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
