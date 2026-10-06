class_name ItemCell
extends Control

## Célula de item no estilo de Hero Siege (decisão 584): fundo escuro com brilho e borda na cor da
## raridade, ícone ampliado sem suavizar, quantidade no canto e, vazia, o nome do encaixe apagado.
## Clique esquerdo emite `pressed`; direito, `secondary_pressed`.

signal pressed
signal secondary_pressed

const SIZE := Vector2(52.0, 52.0)
const BACK := Color("15141b")
const EDGE := Color("3a3542")
const CAPTION := Color("6b5a5e")

var texture: Texture2D
var tier_id := ""
var count := 0
var caption := ""
var affix_count := 0
var _hover := false


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw())


func setup(item_texture: Texture2D, item_tier: String, item_count: int = 0, slot_caption: String = "", affixes: int = 0) -> ItemCell:
	texture = item_texture
	tier_id = item_tier
	count = item_count
	caption = slot_caption
	affix_count = affixes
	queue_redraw()
	return self


func is_empty() -> bool:
	return tier_id.is_empty() and texture == null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			secondary_pressed.emit()
			accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACK)
	if is_empty():
		draw_rect(rect.grow(-1.0), EDGE, false, 1.0)
		if not caption.is_empty():
			var font := ThemeDB.fallback_font
			draw_string(font, Vector2(0.0, size.y * 0.5 + 4.0), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, CAPTION)
		if _hover:
			draw_rect(rect.grow(-1.0), Color(1, 1, 1, 0.15), false, 1.0)
		return
	var color := ItemTier.color(tier_id) if not tier_id.is_empty() else EDGE
	# Brilho da raridade de baixo para cima, como os fundos de item de Hero Siege.
	for step in range(6):
		var height := size.y * (0.18 + step * 0.13)
		draw_rect(Rect2(Vector2(2.0, size.y - 2.0 - height), Vector2(size.x - 4.0, height)), Color(color, 0.05))
	if texture != null:
		var side := minf(size.x, size.y) - 10.0
		var scale := floorf(side / maxf(texture.get_width(), texture.get_height()))
		var drawn := Vector2(texture.get_width(), texture.get_height()) * (scale if scale >= 1.0 else side / maxf(texture.get_width(), texture.get_height()))
		draw_texture_rect(texture, Rect2((size - drawn) * 0.5, drawn), false)
	draw_rect(rect.grow(-1.0), Color(color, 1.0 if _hover else 0.85), false, 2.0)
	if tier_id == "legendary":
		draw_rect(rect.grow(-4.0), Color(color, 0.35), false, 1.0)
	if affix_count > 0:
		for pip in range(affix_count):
			draw_rect(Rect2(Vector2(5.0 + pip * 5.0, 5.0), Vector2(3.0, 3.0)), Color("7fb0ff"))
	if count > 1:
		var font := ThemeDB.fallback_font
		var text := str(count) if count < 1000 else "%dk" % (count / 1000)
		draw_string_outline(font, Vector2(0.0, size.y - 5.0), text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 5.0, 12, 3, Color("12111a"))
		draw_string(font, Vector2(0.0, size.y - 5.0), text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 5.0, 12, Color("f2e6c9"))
