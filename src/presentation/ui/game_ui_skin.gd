extends RefCounted

const ROOT := "res://assets/ui/"
const TEXT := Color("eef1e9")
const MUTED := Color("a8b7b1")
const GOLD := Color("dcc47c")
const CYAN := Color("72cfd2")
const ICON_CELLS := {
	"play": Vector2i(0, 0), "close": Vector2i(1, 0), "settings": Vector2i(2, 0),
	"character": Vector2i(3, 0), "back": Vector2i(5, 0), "confirm": Vector2i(7, 0),
	"potion": Vector2i(0, 1), "inventory": Vector2i(6, 1), "skills": Vector2i(6, 3),
	"journal": Vector2i(7, 3), "tower": Vector2i(7, 4), "bestiary": Vector2i(2, 6),
}
static var _textures: Dictionary = {}
static var _theme: Theme

static func region(file_name: String, rect: Rect2) -> Texture2D:
	var key := file_name + str(rect)
	if not _textures.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(ROOT + file_name) as Texture2D
		atlas.region = rect
		_textures[key] = atlas
	return _textures[key] as Texture2D

static func icon(id: String) -> Texture2D:
	var cell: Vector2i = ICON_CELLS.get(id, Vector2i(4, 0))
	return region("medieval_icons.png", Rect2(Vector2(cell) * 32, Vector2(32, 32)))

static func frame(ornate := false, margin := 16.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = region("dark_ages.png", Rect2(0, 0, 96, 96) if ornate else Rect2(208, 16, 64, 64))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 16.0 if ornate else 10.0)
		style.set_content_margin(side, margin)
	return style

static func slot(active := false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = region("dark_ages.png", Rect2(256, 96, 32, 32) if active else Rect2(192, 96, 32, 32))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 8)
		style.set_content_margin(side, 6)
	return style

static func button_style(active := false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = region("dark_ages.png", Rect2(128, 104, 64, 18) if active else Rect2(0, 104, 64, 18))
	style.texture_margin_left = 8
	style.texture_margin_right = 8
	style.texture_margin_top = 5
	style.texture_margin_bottom = 5
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

static func focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = CYAN
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_expand_margin_all(2)
	return style

static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font_size = 15
	_theme.set_stylebox("panel", "PanelContainer", frame())
	_theme.set_stylebox("panel", "Panel", frame())
	_theme.set_stylebox("panel", "PopupPanel", frame(false, 12))
	_theme.set_stylebox("panel", "TooltipPanel", frame(false, 12))
	_theme.set_color("font_color", "Label", TEXT)
	_theme.set_color("font_color", "TooltipLabel", TEXT)
	_theme.set_color("default_color", "RichTextLabel", TEXT)
	for type in ["Button", "OptionButton"]:
		_theme.set_stylebox("normal", type, button_style())
		_theme.set_stylebox("hover", type, button_style(true))
		_theme.set_stylebox("pressed", type, button_style(true))
		var disabled := button_style()
		disabled.modulate_color = Color(0.55, 0.6, 0.58)
		_theme.set_stylebox("disabled", type, disabled)
		_theme.set_stylebox("focus", type, focus_style())
		_theme.set_color("font_color", type, TEXT)
		_theme.set_color("font_hover_color", type, Color.WHITE)
		_theme.set_color("font_pressed_color", type, GOLD)
		_theme.set_color("font_disabled_color", type, MUTED)
		_theme.set_constant("h_separation", type, 8)
		_theme.set_constant("icon_max_width", type, 24)
	_theme.set_stylebox("normal", "LineEdit", frame(false, 10))
	_theme.set_stylebox("focus", "LineEdit", focus_style())
	_theme.set_color("font_color", "LineEdit", TEXT)
	_theme.set_stylebox("panel", "TabContainer", frame(false, 16))
	for type in ["TabContainer", "TabBar"]:
		_theme.set_stylebox("tab_unselected", type, button_style())
		_theme.set_stylebox("tab_selected", type, button_style(true))
		_theme.set_stylebox("tab_hovered", type, button_style(true))
		_theme.set_color("font_selected_color", type, GOLD)
		_theme.set_color("font_unselected_color", type, TEXT)
	return _theme

static func apply(control: Control) -> void:
	control.theme = theme()
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func icon_button(button: Button, id: String, description: String) -> void:
	button.icon = icon(id)
	button.expand_icon = true
	button.text = ""
	button.tooltip_text = description
	button.add_theme_constant_override("icon_max_width", 24)
