class_name PrototypeCombatHud
extends Control

const BindingsScript := preload("res://src/core/app/input_bindings.gd")
const Sprites := preload("res://src/presentation/art/sprite_library.gd")

var health := 100.0
var max_health := 100.0
var breath := 100.0
var max_breath := 100.0
var cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var maximum_cooldowns: Array[float] = [1.5, 3.0, 5.0, 8.0]
var carried_stone := 0
var hostile_count := 0
var quick_item_count := 0
var player_position := Vector2.ZERO
var enemy_positions: Array[Vector2] = []
var map_size := Vector2(1280.0, 720.0)
var exit_position := Vector2(64.0, 360.0)
var skill_icons: Array[Texture2D] = []
## Encaixes sem gema (a personagem começa só com uma; as outras vêm dos chefes).
var empty_slots: Array[bool] = []
var minimap_title := "TORRE"
var minimap_hint := "COLETAR E RETORNAR"
var skill_charges: Array[int] = [1, 1, 1, 1]
var skill_charge_caps: Array[int] = [1, 1, 1, 1]
var passive_display := {}
var character_level := 1
var experience := 0
var experience_required := 100
var milestone_pending := false
var _skill_hover: Array[DescriptionHover] = []
var _item_hover: DescriptionHover
var skill_costs: Array = [0.0, 0.0, 0.0, 0.0]
var barrier := 0.0
var barrier_seconds := 0.0
var downed := false
var downed_seconds := 0.0
var rescue_progress := 0.0
var auto_aim := false
var selected_target: Dictionary = {}
var effects: Array = []
var party: Array[Dictionary] = []
var _effect_hover: Array[DescriptionHover] = []
var _notice := ""
var _notice_seconds := 0.0
var _notice_key := ""
var _floor_number := -1
var _stairs_open := false


## A cena define `size` em coordenadas de projeto (1280×720 escalado pela tela); a HUD
## desenha tudo nesse espaço e fica proporcional em qualquer janela.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot in range(4):
		var region := DescriptionHover.new()
		region.mouse_filter = Control.MOUSE_FILTER_STOP
		region.size = Vector2(52.0, 52.0)
		add_child(region)
		_skill_hover.append(region)
	_item_hover = DescriptionHover.new()
	_item_hover.mouse_filter = Control.MOUSE_FILTER_STOP
	_item_hover.size = Vector2(44.0, 44.0)
	add_child(_item_hover)
	for index in range(6):
		var region := DescriptionHover.new()
		region.mouse_filter = Control.MOUSE_FILTER_STOP
		region.hide()
		add_child(region)
		_effect_hover.append(region)
	resized.connect(_layout_skill_hover)
	_layout_skill_hover()
	queue_redraw()


func _layout_skill_hover() -> void:
	for slot in range(_skill_hover.size()):
		_skill_hover[slot].position = Vector2(size.x * 0.5 - 160.0 + slot * 60.0, size.y - 65.0)
	if _item_hover != null:
		_item_hover.position = Vector2(size.x * 0.5 + 92.0, size.y - 61.0)
	for index in range(_effect_hover.size()):
		var rect := effect_rect(index)
		_effect_hover[index].position = rect.position
		_effect_hover[index].size = rect.size


func effect_rect(index: int) -> Rect2:
	return Rect2(Vector2(size.x * 0.5 - mini(6, effects.size()) * 20.0 + index * 40.0, size.y - 156.0), Vector2(32, 44))


func set_context(local: Dictionary, players: Dictionary, local_peer: int, aim_enabled: bool, target: Dictionary, floor_state: Dictionary) -> void:
	skill_costs = local.get("skill_costs", [0.0, 0.0, 0.0, 0.0]) as Array
	barrier = float(local.get("barrier", 0.0))
	barrier_seconds = float(local.get("barrier_timer", 0.0))
	downed = bool(local.get("downed", false))
	downed_seconds = float(local.get("downed_timer", 0.0))
	rescue_progress = clampf(float(local.get("stabilize_progress", 0.0)), 0.0, 1.0)
	auto_aim = aim_enabled
	selected_target = target if aim_enabled else {}
	effects = local.get("status_effects", []) as Array
	party.clear()
	var peers := players.keys()
	peers.sort()
	for peer: Variant in peers:
		if int(peer) != local_peer and party.size() < 3:
			party.append(players[peer] as Dictionary)
	for index in range(_effect_hover.size()):
		_effect_hover[index].visible = index < effects.size()
		if index < effects.size():
			var effect := effects[index] as Dictionary
			_effect_hover[index].tooltip_text = "%s\n%s\n%s" % [effect.get("name", ""), effect.get("description", ""), "Ate retornar a vila" if float(effect.get("remaining", 0.0)) < 0.0 else "Zona expira em %.1fs" % float(effect.get("remaining", 0.0)) if effect.get("id") in ["healing", "stability", "slow"] else "Restam %.1fs" % float(effect.get("remaining", 0.0))]
	_layout_skill_hover()
	var number := int(floor_state.get("number", -1))
	if number != _floor_number:
		_floor_number = number
		_stairs_open = false
		_notice_seconds = 0.0
	var open := bool(floor_state.get("stairs_open", false))
	if open and not _stairs_open:
		announce("ESCADA LIBERADA", "stairs", 4.0)
	_stairs_open = open
	queue_redraw()


func announce(message: String, key: String, seconds := 2.5) -> void:
	if key == _notice_key and _notice_seconds > 0.0:
		return
	_notice = message
	_notice_key = key
	_notice_seconds = seconds
	queue_redraw()


func clear_context() -> void:
	_notice_seconds = 0.0
	_notice_key = ""
	_floor_number = -1
	_stairs_open = false


func _process(delta: float) -> void:
	if visible and _notice_seconds > 0.0:
		_notice_seconds = maxf(0.0, _notice_seconds - delta)
		queue_redraw()


func skill_state(slot: int) -> String:
	if slot < empty_slots.size() and empty_slots[slot]:
		return "empty"
	if downed:
		return "blocked"
	var available := int(skill_charges[slot]) if slot < skill_charges.size() else 0
	if available <= 0:
		return "cooldown"
	if breath < (float(skill_costs[slot]) if slot < skill_costs.size() else 0.0):
		return "breath"
	return "ready"


func warning_text() -> String:
	if downed:
		return "CAIDO %.1fs | RESGATE %.0f%%" % [downed_seconds, rescue_progress * 100.0]
	var critical := max_health > 0.0 and health / max_health <= 0.25
	if _notice_seconds > 0.0:
		return _notice + (" | VIDA CRITICA" if critical else "")
	return "VIDA CRITICA" if critical else ""


func set_skill_tooltips(texts: Array) -> void:
	for slot in range(_skill_hover.size()):
		_skill_hover[slot].tooltip_text = String(texts[slot]) if slot < texts.size() else ""


func set_passive(display: Dictionary) -> void:
	passive_display = display


func set_skill_icons(icons: Array[Texture2D], empty: Array[bool] = []) -> void:
	skill_icons = icons.duplicate()
	empty_slots = empty.duplicate()
	queue_redraw()


## Slots com mais de uma carga (`extra_charge`) mostram as cargas disponíveis no canto.
func set_skill_charges(charges: Array[int], caps: Array[int]) -> void:
	skill_charges = charges.duplicate()
	skill_charge_caps = caps.duplicate()


func configure(
	new_health: float,
	new_max_health: float,
	new_breath: float,
	new_max_breath: float,
	new_cooldowns: Array[float],
	new_maximum_cooldowns: Array[float],
	new_carried_stone: int,
	new_hostile_count: int,
	new_quick_item_count: int,
	new_player_position: Vector2,
	new_enemy_positions: Array[Vector2],
	new_map_size: Vector2,
	new_exit_position: Vector2,
	new_character_level: int,
	new_experience: int,
	new_experience_required: int,
	new_milestone_pending: bool
) -> void:
	health = new_health
	max_health = new_max_health
	breath = new_breath
	max_breath = new_max_breath
	cooldowns = new_cooldowns.duplicate()
	maximum_cooldowns = new_maximum_cooldowns.duplicate()
	carried_stone = new_carried_stone
	hostile_count = new_hostile_count
	quick_item_count = new_quick_item_count
	if _item_hover != null:
		_item_hover.tooltip_text = "Consumivel rapido\nRecupera 35 Vida, sem ultrapassar a Vida maxima.\nRestantes: %d" % quick_item_count
	player_position = new_player_position
	enemy_positions = new_enemy_positions.duplicate()
	map_size = new_map_size
	exit_position = new_exit_position
	character_level = new_character_level
	experience = new_experience
	experience_required = maxi(1, new_experience_required)
	milestone_pending = new_milestone_pending
	queue_redraw()


const FRAME := Color("1d1b26e8")
const FRAME_DARK := Color("12111aee")
const BORDER := Color("8f7a6a")
const HAIRLINE := Color(0.79, 0.66, 0.42, 0.55)
const GOLD := Color("e8c27a")
const TEXT := Color("f2e6c9")
const HEALTH := Color("c0392b")
const BREATH := Color("5ec8d8")

var _boxes := {}


## Painel arredondado com sombra e fio dourado; caixas ficam em cache por aparência.
func _panel(rect: Rect2, fill: Color, border: Color = HAIRLINE, radius := 8, border_width := 1, shadow := 8) -> void:
	var key := "%s|%s|%d|%d|%d" % [fill.to_html(), border.to_html(), radius, border_width, shadow]
	if not _boxes.has(key):
		var box := StyleBoxFlat.new()
		box.bg_color = fill
		box.border_color = border
		box.set_border_width_all(border_width)
		box.set_corner_radius_all(radius)
		box.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
		box.shadow_size = shadow
		box.anti_aliasing = true
		_boxes[key] = box
	draw_style_box(_boxes[key] as StyleBoxFlat, rect)


func _draw() -> void:
	var width := size.x
	var height := size.y
	var center_x := width * 0.5
	var now := Time.get_ticks_msec() / 1000.0
	_draw_minimap(Rect2(width - 196.0, 40.0, 180.0, 120.0))
	_draw_context()
	# Doca inferior: painel escuro arredondado, orbes nas pontas, gemas e item rápido no centro.
	var panel := Rect2(center_x - 236.0, height - 74.0, 472.0, 66.0)
	_panel(panel, FRAME_DARK, HAIRLINE, 14, 1, 12)
	_panel(Rect2(panel.position + Vector2(10.0, 4.0), Vector2(panel.size.x - 20.0, 2.0)), Color(1.0, 1.0, 1.0, 0.05), Color(0, 0, 0, 0), 1, 0, 0)
	_draw_orb(Vector2(panel.position.x - 4.0, height - 46.0), 40.0, health, max_health, HEALTH, "VIDA", now)
	_draw_orb(Vector2(panel.end.x + 4.0, height - 46.0), 40.0, breath, max_breath, BREATH, "FOLEGO", now + 1.3)
	var keys: Array[String] = []
	for slot in range(4):
		keys.append(BindingsScript.label("skill_%d" % (slot + 1)))
	for index in range(4):
		_draw_skill_slot(index, Rect2(center_x - 160.0 + index * 60.0, height - 65.0, 52.0, 52.0), keys[index])
	var item_rect := Rect2(center_x + 92.0, height - 61.0, 44.0, 44.0)
	_panel(item_rect, FRAME, HAIRLINE, 8, 1, 0)
	draw_circle(item_rect.get_center() + Vector2(0.0, 3.0), 9.0, HEALTH)
	draw_circle(item_rect.get_center() + Vector2(-3.0, 0.0), 3.0, Color(1.0, 1.0, 1.0, 0.35))
	draw_rect(Rect2(item_rect.get_center() + Vector2(-4.0, -11.0), Vector2(8.0, 6.0)), Color("d9c2a0"))
	_draw_key_chip(item_rect.position + Vector2(3.0, 3.0), BindingsScript.label("quick_item"), true)
	draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(20.0, 41.0), "x%d" % quick_item_count, HORIZONTAL_ALIGNMENT_RIGHT, 22.0, 11, TEXT if quick_item_count > 0 else MUTED_COLOR)
	_draw_experience(Rect2(panel.position.x + 24.0, panel.position.y - 9.0, panel.size.x - 48.0, 5.0))
	_draw_passive(Rect2(center_x - 170.0, panel.position.y - 50.0, 340.0, 24.0))
	if not downed and max_health > 0.0 and health / max_health <= 0.25:
		var pulse := 0.55 + 0.45 * sin(now * 6.0)
		draw_arc(Vector2(panel.position.x - 4.0, height - 46.0), 48.0, 0, TAU, 64, Color(0.95, 0.53, 0.45, pulse), 2.5, true)


## Gema: ícone em moldura arredondada, recarga em varredura radial, tecla e cargas discretas.
func _draw_skill_slot(index: int, rect: Rect2, key: String) -> void:
	var state := skill_state(index)
	var ready := state == "ready"
	if state == "empty":
		_panel(rect, Color(FRAME_DARK, 0.55), Color(HAIRLINE, 0.5), 8, 1, 0)
		_draw_key_chip(rect.position + Vector2(-4.0, rect.size.y - 12.0), key, false)
		return
	_panel(rect, FRAME, GOLD if ready else HAIRLINE, 8, 1, 0)
	var icon: Texture2D = skill_icons[index] if index < skill_icons.size() else null
	if icon != null:
		draw_texture_rect(icon, rect.grow(-4.0), false, Color.WHITE if ready else Color(0.62, 0.6, 0.66))
	var remaining: float = cooldowns[index] if index < cooldowns.size() else 0.0
	if state == "cooldown":
		var maximum := maximum_cooldowns[index] if index < maximum_cooldowns.size() else 1.0
		_draw_sweep(rect.grow(-4.0), clampf(remaining / maximum, 0.0, 1.0))
		_outlined_text(rect.position + Vector2(0.0, 33.0), "%.1f" % remaining, rect.size.x, 14, TEXT)
	elif not ready:
		draw_rect(rect.grow(-4.0), Color(0.07, 0.07, 0.1, 0.6))
		_outlined_text(rect.position + Vector2(0.0, 31.0), "FOLEGO" if state == "breath" else "CAIDO", rect.size.x, 9, BREATH if state == "breath" else TEXT)
	_draw_key_chip(rect.position + Vector2(-4.0, rect.size.y - 12.0), key, ready)
	var cap: int = skill_charge_caps[index] if index < skill_charge_caps.size() else 1
	if cap > 1:
		var available: int = skill_charges[index] if index < skill_charges.size() else 0
		for pip in range(cap):
			var spot := rect.position + Vector2(rect.size.x - 7.0 - pip * 7.0, 7.0)
			draw_circle(spot, 2.6, BREATH if pip < available else Color(0.3, 0.3, 0.36))


## Fatia escura que encolhe no sentido horário conforme a recarga termina.
func _draw_sweep(rect: Rect2, ratio: float) -> void:
	if ratio <= 0.0:
		return
	var center := rect.get_center()
	var radius := rect.size.length() * 0.5
	var points := PackedVector2Array([center])
	var steps := maxi(2, int(ceil(32.0 * ratio)))
	for step in range(steps + 1):
		var angle := -PI * 0.5 + TAU * (1.0 - ratio) + TAU * ratio * float(step) / float(steps)
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point.clamp(rect.position, rect.end))
	draw_colored_polygon(points, Color(0.05, 0.05, 0.08, 0.72))


func _draw_key_chip(origin: Vector2, key: String, active: bool) -> void:
	var font_size := 10
	while font_size > 6 and ThemeDB.fallback_font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 40.0:
		font_size -= 1
	var width := maxf(16.0, ThemeDB.fallback_font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 8.0)
	_panel(Rect2(origin, Vector2(width, 15.0)), FRAME_DARK, GOLD if active else HAIRLINE, 4, 1, 0)
	draw_string(ThemeDB.fallback_font, origin + Vector2(0.0, 11.5), key, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, GOLD if active else MUTED_COLOR)


func _outlined_text(origin: Vector2, text: String, width: float, font_size: int, color: Color) -> void:
	draw_string_outline(ThemeDB.fallback_font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 4, Color(0.05, 0.05, 0.08, 0.9))
	draw_string(ThemeDB.fallback_font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


const MUTED_COLOR := Color("aaa59a")


func _fit_text(text: String, width: float, font_size := 12) -> String:
	var value := text
	while value.length() > 1 and ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		value = value.left(value.length() - 1)
	return value if value == text else value.left(maxi(0, value.length() - 3)) + "..."


func _draw_context() -> void:
	var font := ThemeDB.fallback_font
	var center := size.x * 0.5
	if barrier > 0.0:
		var rect := Rect2(center - 140, size.y - 183, 280, 20)
		_panel(rect, FRAME_DARK, Color(BREATH, 0.6), 10, 1, 4)
		draw_string(font, rect.position + Vector2(0, 14.5), "BARREIRA %.0f   |   %.1fs" % [barrier, barrier_seconds], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, BREATH)
	for index in range(mini(6, effects.size())):
		var effect := effects[index] as Dictionary
		var rect := effect_rect(index)
		_panel(rect, FRAME_DARK, HAIRLINE, 6, 1, 4)
		var texture := Sprites.texture("icons/" + String(effect.get("icon", "")))
		if texture != null:
			draw_texture_rect(texture, Rect2(rect.position + Vector2(2, 2), Vector2(28, 28)), false)
		var seconds := float(effect.get("remaining", 0.0))
		draw_string(font, rect.position + Vector2(0, 41), "VILA" if seconds < 0.0 else "%.1f" % seconds, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 10, TEXT)
	var aim_x := size.x - 196.0
	draw_string(font, Vector2(aim_x, 220), "MIRA AUTO: " + ("LIGADA" if auto_aim else "DESLIGADA"), HORIZONTAL_ALIGNMENT_CENTER, 180, 12, GOLD if auto_aim else MUTED_COLOR)
	if auto_aim and not selected_target.is_empty():
		draw_string(font, Vector2(aim_x, 238), _fit_text(String(selected_target.get("name", "ALVO")), 180), HORIZONTAL_ALIGNMENT_CENTER, 180, 12, TEXT)
		var rect := Rect2(aim_x, 245, 180, 5)
		_panel(rect, FRAME_DARK, Color(0, 0, 0, 0), 3, 0, 0)
		var target_ratio := clampf(float(selected_target.get("health", 0)) / maxf(1.0, float(selected_target.get("max_health", 1))), 0, 1)
		if target_ratio > 0.0:
			_panel(Rect2(rect.position, Vector2(rect.size.x * target_ratio, 5)), HEALTH, Color(0, 0, 0, 0), 3, 0, 0)
		var conditions := PackedStringArray()
		if float(selected_target.get("slow_timer", 0.0)) > 0.0:
			conditions.append("LENTO %.1fs" % float(selected_target["slow_timer"]))
		if float(selected_target.get("vulnerable_timer", 0.0)) > 0.0:
			conditions.append("VULN %.1fs" % float(selected_target["vulnerable_timer"]))
		draw_string(font, Vector2(aim_x, 266), " | ".join(conditions), HORIZONTAL_ALIGNMENT_CENTER, 180, 10, BREATH)
	elif auto_aim:
		draw_string(font, Vector2(aim_x, 238), "SEM ALVO", HORIZONTAL_ALIGNMENT_CENTER, 180, 11, MUTED_COLOR)
	for index in range(party.size()):
		var member := party[index]
		var origin := Vector2(20, 166 + index * 68)
		_panel(Rect2(origin + Vector2(-10, -16), Vector2(244, 58)), Color(FRAME_DARK, 0.8), HAIRLINE, 8, 1, 4)
		draw_string(font, origin, _fit_text(String(member.get("character_name", "")), 215), HORIZONTAL_ALIGNMENT_LEFT, 220, 12, TEXT)
		for spec in [["health", "max_health", HEALTH], ["breath", "max_breath", BREATH]]:
			var y := 8 if spec[0] == "health" else 16
			var rect := Rect2(origin + Vector2(0, y), Vector2(150, 4))
			var value := float(member.get(spec[0], 0.0))
			var maximum := maxf(1.0, float(member.get(spec[1], 1.0)))
			_panel(rect, Color(0.06, 0.06, 0.09), Color(0, 0, 0, 0), 2, 0, 0)
			if value > 0.0:
				_panel(Rect2(rect.position, Vector2(150 * clampf(value / maximum, 0, 1), 4)), spec[2], Color(0, 0, 0, 0), 2, 0, 0)
			draw_string(font, origin + Vector2(156, y + 5), "%.0f/%.0f" % [value, maximum], HORIZONTAL_ALIGNMENT_LEFT, 68, 9, spec[2])
		var state := "NA TORRE" if String(member.get("zone", "")) in ["tower", "boss_room"] else "NA VILA"
		var color := MUTED_COLOR
		if not bool(member.get("connected", true)):
			state = "RECONECTANDO %.0fs" % ceilf(float(member.get("reconnect_timer", 0.0)))
		elif bool(member.get("downed", false)):
			state = "CAIDO %.1fs | RESGATE %.0f%%" % [float(member.get("downed_timer", 0.0)), float(member.get("stabilize_progress", 0.0)) * 100.0]
			color = Color("f38674")
			var rect := Rect2(origin + Vector2(0, 43), Vector2(220, 3))
			_panel(rect, Color(0.06, 0.06, 0.09), Color(0, 0, 0, 0), 2, 0, 0)
			if float(member.get("stabilize_progress", 0.0)) > 0.0:
				_panel(Rect2(rect.position, Vector2(220 * clampf(float(member.get("stabilize_progress", 0.0)), 0, 1), 3)), BREATH, Color(0, 0, 0, 0), 2, 0, 0)
		else:
			state += " | BARREIRA %.0f" % float(member.get("barrier", 0.0)) if float(member.get("barrier", 0.0)) > 0.0 else ""
		draw_string(font, origin + Vector2(0, 36), state, HORIZONTAL_ALIGNMENT_LEFT, 224, 10, color)
	var warning := warning_text()
	if not warning.is_empty():
		var width := minf(420.0, size.x - 40.0)
		var y := 384.0 if size.x < 960.0 and not party.is_empty() else 166.0
		var rect := Rect2(center - width * 0.5, y, width, 30)
		var alarm := warning.contains("CRITICA") or warning.contains("FOLEGO") or warning.contains("CAIDO")
		_panel(rect, FRAME_DARK, Color("f38674") if alarm else GOLD, 15, 1, 10)
		draw_string(font, rect.position + Vector2(0, 20), warning, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, TEXT)


## Fio fino de experiência no topo da doca, com o nível em destaque à esquerda.
func _draw_experience(rect: Rect2) -> void:
	_panel(rect, Color(0.08, 0.08, 0.11, 0.9), Color(0, 0, 0, 0), 3, 0, 0)
	var ratio := clampf(float(experience) / float(experience_required), 0.0, 1.0)
	if ratio > 0.0:
		_panel(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), GOLD, Color(0, 0, 0, 0), 3, 0, 0)
	var label := "NIVEL %d   ·   EVOLUCAO PENDENTE" % character_level if milestone_pending else "NIVEL %d   ·   %d / %d" % [character_level, experience, experience_required]
	_outlined_text(rect.position + Vector2(0.0, -4.0), label, rect.size.x, 10, GOLD if milestone_pending else TEXT)


## Passiva da personagem numa pílula: nome à esquerda, medidor ou contas à direita.
func _draw_passive(rect: Rect2) -> void:
	if passive_display.is_empty():
		return
	var color := passive_display.get("color", GOLD) as Color
	_panel(rect, FRAME_DARK, Color(color, 0.6), 12, 1, 6)
	draw_circle(rect.position + Vector2(14.0, rect.size.y * 0.5), 4.0, color)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(24.0, 16.5), String(passive_display.get("name", "")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 160.0, 11, color)
	var maximum := maxf(1.0, float(passive_display.get("maximum", 1.0)))
	var value := float(passive_display.get("value", 0.0))
	var meter := Rect2(rect.position + Vector2(186.0, 7.0), Vector2(140.0, 10.0))
	if maximum <= 3.0:
		for index in range(int(maximum)):
			draw_circle(meter.position + Vector2(8.0 + index * 20.0, 5.0), 5.0, color if index < int(value) else Color(0.22, 0.21, 0.27))
		if passive_display.has("secondary"):
			for index in range(int(maximum)):
				draw_circle(meter.position + Vector2(84.0 + index * 20.0, 5.0), 5.0, BREATH if index < int(passive_display["secondary"]) else Color(0.22, 0.21, 0.27))
	else:
		_panel(meter, Color(0.08, 0.08, 0.11, 0.95), Color(0, 0, 0, 0), 5, 0, 0)
		var ratio := clampf(value / maximum, 0.0, 1.0)
		if ratio > 0.0:
			_panel(Rect2(meter.position, Vector2(meter.size.x * ratio, meter.size.y)), color, Color(0, 0, 0, 0), 5, 0, 0)
		if bool(passive_display.get("flag", false)):
			draw_circle(meter.end + Vector2(8.0, -5.0), 4.0, GOLD)


## Orbe de vidro escuro com líquido ondulando, menisco claro e reflexo.
func _draw_orb(center: Vector2, radius: float, value: float, maximum: float, color: Color, label_text: String, time: float) -> void:
	var ratio := clampf(value / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	draw_circle(center + Vector2(0.0, 3.0), radius + 8.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(center, radius + 6.0, FRAME_DARK)
	draw_circle(center, radius, Color(0.06, 0.06, 0.09))
	var circle := PackedVector2Array()
	for index in range(48):
		var angle := TAU * float(index) / 48.0
		circle.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var level := center.y + radius - radius * 2.0 * ratio
	var surface := PackedVector2Array()
	for step in range(17):
		var x := center.x - radius - 1.0 + (radius * 2.0 + 2.0) * float(step) / 16.0
		surface.append(Vector2(x, level + sin(time * 2.4 + float(step) * 0.7) * (2.0 if 0.02 < ratio and ratio < 0.98 else 0.0)))
	var liquid := surface.duplicate()
	liquid.append(Vector2(center.x + radius + 1.0, center.y + radius + 1.0))
	liquid.append(Vector2(center.x - radius - 1.0, center.y + radius + 1.0))
	for fill in Geometry2D.intersect_polygons(circle, liquid):
		draw_colored_polygon(fill, color.darkened(0.25))
	var core := liquid.duplicate()
	for index in range(core.size()):
		core[index] = core[index] + Vector2(0.0, 5.0) if index < surface.size() else core[index]
	for fill in Geometry2D.intersect_polygons(circle, core):
		draw_colored_polygon(fill, color)
	if 0.02 < ratio and ratio < 0.98:
		var meniscus := PackedVector2Array()
		for point in surface:
			if center.distance_to(point) < radius - 1.0:
				meniscus.append(point)
		if meniscus.size() > 1:
			draw_polyline(meniscus, color.lightened(0.45), 1.5, true)
	draw_circle(center + Vector2(-radius * 0.38, -radius * 0.42), radius * 0.2, Color(1.0, 1.0, 1.0, 0.16))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.0, 0.0, 0.0, 0.6), 3.0, true)
	draw_arc(center, radius + 3.5, 0.0, TAU, 64, HAIRLINE, 1.5, true)
	_outlined_text(center + Vector2(-radius, 8.0), "%d" % int(value), radius * 2.0, 18, TEXT)
	_outlined_text(center + Vector2(-radius, -12.0), label_text, radius * 2.0, 9, Color(TEXT, 0.8))


## Minimapa em painel arredondado: inimigos em vermelho, saída em losango, posição com halo.
func _draw_minimap(rect: Rect2) -> void:
	_panel(rect, FRAME_DARK, HAIRLINE, 10, 1, 8)
	var inner := rect.grow(-7.0)
	_panel(inner, Color(0.11, 0.1, 0.14, 0.95), Color(0, 0, 0, 0), 6, 0, 0)
	var player_marker := _map_to_minimap(player_position, inner)
	for enemy_position in enemy_positions:
		draw_circle(_map_to_minimap(enemy_position, inner), 2.4, HEALTH.lightened(0.15))
	var exit_marker := _map_to_minimap(exit_position, inner)
	draw_colored_polygon(PackedVector2Array([
		exit_marker + Vector2(0.0, -6.0), exit_marker + Vector2(6.0, 0.0),
		exit_marker + Vector2(0.0, 6.0), exit_marker + Vector2(-6.0, 0.0),
	]), BREATH)
	draw_circle(player_marker, 3.5, GOLD)
	draw_arc(player_marker, 7.0, 0.0, TAU, 24, Color(GOLD, 0.6), 1.5, true)
	_outlined_text(rect.position + Vector2(0.0, -8.0), minimap_title, rect.size.x, 13, GOLD)
	_outlined_text(rect.position + Vector2(0.0, rect.size.y + 16.0), minimap_hint, rect.size.x, 11, TEXT)
	_outlined_text(rect.position + Vector2(0.0, rect.size.y + 31.0), "PEDRA %d   ·   HOSTIS %d" % [carried_stone, hostile_count], rect.size.x, 11, MUTED_COLOR)


func _map_to_minimap(world_position: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		remap(clampf(world_position.x, 0.0, map_size.x), 0.0, map_size.x, rect.position.x, rect.end.x),
		remap(clampf(world_position.y, 0.0, map_size.y), 0.0, map_size.y, rect.position.y, rect.end.y)
	)
