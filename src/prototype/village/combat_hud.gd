class_name PrototypeCombatHud
extends Control

const BindingsScript := preload("res://src/core/app/input_bindings.gd")

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
var minimap_title := "TORRE"
var minimap_hint := "COLETAR E RETORNAR"
var skill_charges: Array[int] = [1, 1, 1, 1]
var skill_charge_caps: Array[int] = [1, 1, 1, 1]
var passive_display := {}
var character_level := 1
var experience := 0
var experience_required := 100
var milestone_pending := false


## A cena define `size` em coordenadas de projeto (1280×720 escalado pela tela); a HUD
## desenha tudo nesse espaço e fica proporcional em qualquer janela.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_passive(display: Dictionary) -> void:
	passive_display = display


func set_skill_icons(icons: Array[Texture2D]) -> void:
	skill_icons = icons.duplicate()
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
	player_position = new_player_position
	enemy_positions = new_enemy_positions.duplicate()
	map_size = new_map_size
	exit_position = new_exit_position
	character_level = new_character_level
	experience = new_experience
	experience_required = maxi(1, new_experience_required)
	milestone_pending = new_milestone_pending
	queue_redraw()


const FRAME := Color("2f2a35e6")
const FRAME_DARK := Color("1b1a1ff0")
const BORDER := Color("8f7a6a")
const GOLD := Color("e8b84a")
const TEXT := Color("f2e6c9")
const HEALTH := Color("b04a3a")
const BREATH := Color("7fd6e0")


func _draw() -> void:
	var width := size.x
	var height := size.y
	var center_x := width * 0.5
	_draw_minimap(Rect2(width - 196.0, 40.0, 180.0, 120.0))
	# Barra inferior compacta: orbes nas pontas, gemas e item rápido no centro.
	var panel := Rect2(center_x - 250.0, height - 70.0, 500.0, 62.0)
	draw_rect(panel, FRAME_DARK)
	draw_rect(panel, BORDER, false, 2.0)
	draw_rect(panel.grow(-4.0), Color(0.56, 0.48, 0.42, 0.35), false, 1.0)
	_draw_orb(Vector2(panel.position.x - 6.0, height - 48.0), 40.0, health, max_health, HEALTH, "VIDA")
	_draw_orb(Vector2(panel.end.x + 6.0, height - 48.0), 40.0, breath, max_breath, BREATH, "FOLEGO")
	var keys: Array[String] = []
	for slot in range(4):
		keys.append(BindingsScript.label("skill_%d" % (slot + 1)))
	for index in range(4):
		var rect := Rect2(center_x - 160.0 + index * 60.0, height - 65.0, 52.0, 52.0)
		draw_rect(rect, FRAME)
		var icon: Texture2D = skill_icons[index] if index < skill_icons.size() else null
		if icon != null:
			draw_texture_rect(icon, rect.grow(-2.0), false)
		draw_rect(rect, BORDER, false, 2.0)
		var remaining: float = cooldowns[index] if index < cooldowns.size() else 0.0
		var ready := remaining <= 0.0
		if not ready:
			var maximum := maximum_cooldowns[index] if index < maximum_cooldowns.size() else 1.0
			var ratio := clampf(remaining / maximum, 0.0, 1.0)
			draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y * (1.0 - ratio)), Vector2(rect.size.x, rect.size.y * ratio)), Color("1b1a1fcc"))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(0.0, 47.0), "%.1f" % remaining, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, TEXT)
		else:
			draw_rect(rect.grow(-3.0), Color(0.91, 0.72, 0.29, 0.35), false, 1.0)
		var key_width := minf(48.0, maxf(16.0, ThemeDB.fallback_font.get_string_size(keys[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 4.0))
		draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), Vector2(key_width, 16.0)), FRAME_DARK)
		var key_font := 11
		while key_font > 6 and ThemeDB.fallback_font.get_string_size(keys[index], HORIZONTAL_ALIGNMENT_LEFT, -1, key_font).x > key_width:
			key_font -= 1
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(2.0, 15.0), keys[index], HORIZONTAL_ALIGNMENT_CENTER, key_width, key_font, GOLD if ready else Color("8f7a6a"))
		var cap: int = skill_charge_caps[index] if index < skill_charge_caps.size() else 1
		if cap > 1:
			var available: int = skill_charges[index] if index < skill_charges.size() else 0
			var badge := Rect2(rect.end - Vector2(18.0, 18.0), Vector2(16.0, 16.0))
			draw_rect(badge, FRAME_DARK)
			draw_string(ThemeDB.fallback_font, badge.position + Vector2(0.0, 13.0), str(available), HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 12, BREATH if available > 0 else Color("8f7a6a"))
	var item_rect := Rect2(center_x + 92.0, height - 61.0, 44.0, 44.0)
	draw_rect(item_rect, FRAME)
	draw_rect(item_rect, BORDER, false, 2.0)
	draw_circle(item_rect.get_center() + Vector2(0.0, 3.0), 9.0, HEALTH)
	draw_rect(Rect2(item_rect.get_center() + Vector2(-4.0, -11.0), Vector2(8.0, 6.0)), Color("d9c2a0"))
	var item_key := BindingsScript.label("quick_item")
	var item_font := 9
	while item_font > 5 and ThemeDB.fallback_font.get_string_size(item_key, HORIZONTAL_ALIGNMENT_LEFT, -1, item_font).x > 38.0:
		item_font -= 1
	draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(3.0, 13.0), item_key, HORIZONTAL_ALIGNMENT_LEFT, 38.0, item_font, GOLD)
	draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(22.0, 41.0), "x%d" % quick_item_count, HORIZONTAL_ALIGNMENT_LEFT, 24.0, 11, TEXT)
	_draw_experience(Rect2(panel.position.x + 40.0, panel.position.y - 12.0, panel.size.x - 80.0, 10.0))
	_draw_passive(Rect2(center_x - 180.0, panel.position.y - 40.0, 360.0, 24.0))


func _draw_experience(rect: Rect2) -> void:
	draw_rect(rect, FRAME_DARK)
	var ratio := clampf(float(experience) / float(experience_required), 0.0, 1.0)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), GOLD)
	draw_rect(rect, BORDER, false, 1.0)
	var label := "NIVEL %d   EVOLUCAO PENDENTE" % character_level if milestone_pending else "NIVEL %d   %d / %d EXP" % [character_level, experience, experience_required]
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0.0, 9.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 9, TEXT)


func _draw_passive(rect: Rect2) -> void:
	if passive_display.is_empty():
		return
	var color := passive_display.get("color", GOLD) as Color
	draw_rect(rect, FRAME_DARK)
	draw_rect(rect, color, false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 17.0), String(passive_display.get("name", "")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 190.0, 11, color)
	var maximum := maxf(1.0, float(passive_display.get("maximum", 1.0)))
	var value := float(passive_display.get("value", 0.0))
	var meter := Rect2(rect.position + Vector2(196.0, 5.0), Vector2(156.0, 14.0))
	if maximum <= 3.0:
		for index in range(int(maximum)):
			var pip := Rect2(meter.position + Vector2(index * 22.0, 0.0), Vector2(16.0, 14.0))
			draw_rect(pip, color if index < int(value) else Color("2f2a35"))
			draw_rect(pip, BORDER, false, 1.0)
		if passive_display.has("secondary"):
			for index in range(int(maximum)):
				var pip := Rect2(meter.position + Vector2(76.0 + index * 22.0, 0.0), Vector2(16.0, 14.0))
				draw_rect(pip, BREATH if index < int(passive_display["secondary"]) else Color("2f2a35"))
				draw_rect(pip, BORDER, false, 1.0)
	else:
		draw_rect(meter, Color("2f2a35"))
		draw_rect(Rect2(meter.position, Vector2(meter.size.x * clampf(value / maximum, 0.0, 1.0), meter.size.y)), color)
		draw_rect(meter, BORDER, false, 1.0)
		if bool(passive_display.get("flag", false)):
			draw_circle(meter.end + Vector2(-6.0, -7.0), 4.0, GOLD)


func _draw_orb(center: Vector2, radius: float, value: float, maximum: float, color: Color, label_text: String) -> void:
	var ratio := clampf(value / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	draw_circle(center, radius + 6.0, FRAME_DARK)
	draw_circle(center, radius, Color("1b1a1f"))
	var circle := PackedVector2Array()
	for index in range(40):
		var angle := TAU * float(index) / 40.0
		circle.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var level := center.y + radius - radius * 2.0 * ratio
	var below := PackedVector2Array([
		Vector2(center.x - radius - 1.0, level), Vector2(center.x + radius + 1.0, level),
		Vector2(center.x + radius + 1.0, center.y + radius + 1.0), Vector2(center.x - radius - 1.0, center.y + radius + 1.0),
	])
	for fill in Geometry2D.intersect_polygons(circle, below):
		draw_colored_polygon(fill, color)
	draw_circle(center + Vector2(-radius * 0.35, -radius * 0.4), radius * 0.22, Color(1.0, 1.0, 1.0, 0.12))
	draw_arc(center, radius, 0.0, TAU, 48, BORDER, 3.0)
	draw_arc(center, radius + 5.0, 0.0, TAU, 48, Color("4a3f4f"), 2.0)
	for shadow in [Vector2(1.0, 1.0), Vector2(-1.0, 1.0), Vector2(1.0, -1.0), Vector2(-1.0, -1.0)]:
		draw_string(ThemeDB.fallback_font, center + Vector2(-radius, 10.0) + shadow, "%d" % int(value), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 17, FRAME_DARK)
		draw_string(ThemeDB.fallback_font, center + Vector2(-radius, -12.0) + shadow, label_text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 9, FRAME_DARK)
	draw_string(ThemeDB.fallback_font, center + Vector2(-radius, 10.0), "%d" % int(value), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 17, TEXT)
	draw_string(ThemeDB.fallback_font, center + Vector2(-radius, -12.0), label_text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 9, TEXT)


func _draw_minimap(rect: Rect2) -> void:
	draw_rect(rect, FRAME_DARK)
	draw_rect(rect, BORDER, false, 2.0)
	var inner := rect.grow(-8.0)
	draw_rect(inner, Color("2f2a35"))
	var player_marker := _map_to_minimap(player_position, inner)
	for enemy_position in enemy_positions:
		var marker := _map_to_minimap(enemy_position, inner)
		draw_rect(Rect2(marker - Vector2(2.5, 2.5), Vector2(5.0, 5.0)), HEALTH)
	var exit_marker := _map_to_minimap(exit_position, inner)
	draw_colored_polygon(PackedVector2Array([
		exit_marker + Vector2(0.0, -6.0), exit_marker + Vector2(6.0, 0.0),
		exit_marker + Vector2(0.0, 6.0), exit_marker + Vector2(-6.0, 0.0),
	]), BREATH)
	draw_circle(player_marker, 4.0, GOLD)
	draw_arc(player_marker, 7.0, 0.0, TAU, 20, GOLD, 1.5)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0.0, -8.0), minimap_title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, GOLD)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0.0, rect.size.y + 16.0), minimap_hint, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, TEXT)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0.0, rect.size.y + 31.0), "PEDRA %d   ·   HOSTIS %d" % [carried_stone, hostile_count], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, TEXT)


func _map_to_minimap(world_position: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		remap(clampf(world_position.x, 0.0, map_size.x), 0.0, map_size.x, rect.position.x, rect.end.x),
		remap(clampf(world_position.y, 0.0, map_size.y), 0.0, map_size.y, rect.position.y, rect.end.y)
	)
