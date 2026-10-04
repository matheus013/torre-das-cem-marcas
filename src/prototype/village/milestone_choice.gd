extends Control

signal choice_requested(choice_id: StringName)

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
var _key := ""
var _panel: PanelContainer
var _content: VBoxContainer
var _choices_grid: GridContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("101217dc")
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20242a")
	style.border_color = Color("dbbd68")
	style.set_border_width_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	scroll.add_child(_content)
	get_viewport().size_changed.connect(_resize)
	_resize()
	hide()


func _resize() -> void:
	var viewport := get_viewport_rect().size
	_panel.custom_minimum_size = Vector2(minf(820, viewport.x - 32), minf(620, viewport.y - 32))
	if is_instance_valid(_choices_grid):
		_choices_grid.columns = 1 if viewport.x < 700 else 2


func refresh(local: Dictionary, pending: Array) -> void:
	if pending.is_empty():
		_key = ""
		hide()
		return
	var choices := local.get("milestone_choices", []) as Array
	var key := JSON.stringify([local.get("character_id", ""), local.get("level", 1), choices, pending if choices.is_empty() else []])
	if key == _key:
		return
	_key = key
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	show()
	if choices.is_empty():
		_label("COMBATE PAUSADO", 24, Color("dbbd68"))
		_label("Aguardando escolhas de evolucao: %d" % pending.size(), 18)
		return
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	_content.add_child(header)
	var portrait := TextureRect.new()
	portrait.texture = Sprites.texture("characters/" + String(local.get("character_id", "")))
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(64, 64)
	header.add_child(portrait)
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_label("EVOLUCAO - NIVEL %d" % int(local.get("level", 1)), 24, Color("dbbd68"), title)
	_label(String(local.get("character_name", "")), 18, Color("e8ebed"), title)
	_choices_grid = GridContainer.new()
	_choices_grid.add_theme_constant_override("h_separation", 24)
	_choices_grid.add_theme_constant_override("v_separation", 18)
	_content.add_child(_choices_grid)
	_resize()
	var first: Button
	for entry: Dictionary in choices:
		var option := VBoxContainer.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_theme_constant_override("separation", 8)
		_choices_grid.add_child(option)
		_label(String(entry.get("name", "")), 20, Color("dbbd68"), option)
		_label(String(entry.get("description", "")), 16, Color("e8ebed"), option)
		var button := Button.new()
		button.text = "Escolher"
		button.custom_minimum_size.y = 44
		button.tooltip_text = String(entry.get("name", "")) + "\n" + String(entry.get("description", ""))
		button.pressed.connect(func() -> void: choice_requested.emit(StringName(String(entry["id"]))))
		option.add_child(button)
		if first == null:
			first = button
	if first != null:
		first.grab_focus()


func _label(value: String, font_size: int, color := Color("e8ebed"), parent: Container = null) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	(parent if parent != null else _content).add_child(label)
