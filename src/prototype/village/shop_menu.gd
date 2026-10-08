extends Control

## Loja de equipamentos da Forja (decisão 594): vitrine com ícone na cor da raridade, preço e
## botão de compra; a dica mostra a peça completa (atributos, afixos, passiva).

signal buy_requested(index: int)
signal reroll_requested

const PlayerMenuScript := preload("res://src/prototype/village/player_menu.gd")
const GOLD := Color("e8b84a")
const TEXT := Color("f2e6c9")
const MUTED := Color("aaa59a")
const TIER_COLORS := {"common": Color("d8cdb4"), "uncommon": Color("7fc66a"), "rare": Color("5aa2e8"), "epic": Color("b276e8"), "legendary": Color("f08a3a")}

var _model: Dictionary = {}
var _silver: Label
var _grid: GridContainer
var _reroll: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 470)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b1a1f")
	style.border_color = Color("8f7a6a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "FORJA DE DALIA  ·  EQUIPAMENTOS"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_silver = Label.new()
	_silver.name = "ShopSilver"
	_silver.add_theme_color_override("font_color", TEXT)
	header.add_child(_silver)
	var hint := Label.new()
	hint.text = "Estoque novo a cada volta da Torre; melhora quanto mais fundo o grupo ja chegou."
	hint.add_theme_color_override("font_color", MUTED)
	hint.add_theme_font_size_override("font_size", 12)
	column.add_child(hint)
	_grid = GridContainer.new()
	_grid.name = "ShopGrid"
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(_grid)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	column.add_child(footer)
	_reroll = Button.new()
	_reroll.name = "ShopReroll"
	_reroll.custom_minimum_size = Vector2(220, 40)
	_reroll.pressed.connect(func() -> void: reroll_requested.emit())
	footer.add_child(_reroll)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(120, 40)
	close_button.pressed.connect(close)
	footer.add_child(close_button)
	visible = false


func open(model: Dictionary) -> void:
	visible = true
	refresh(model)


func close() -> void:
	visible = false


func refresh(model: Dictionary) -> void:
	_model = model.duplicate(true)
	if not visible or _grid == null:
		return
	_silver.text = "Prata: %d P" % int(_model.get("silver", 0))
	_reroll.text = "Renovar estoque (%d P)" % int(_model.get("reroll_price", 25))
	_reroll.disabled = int(_model.get("silver", 0)) < int(_model.get("reroll_price", 25))
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for entry: Dictionary in _model.get("items", []) as Array:
		_grid.add_child(_card(entry))


func _card(entry: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.name = "Offer_%d" % int(entry["index"])
	card.custom_minimum_size = Vector2(160, 0)
	card.add_theme_constant_override("separation", 4)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	card.add_child(top)
	var cell := ItemCell.new().setup(PlayerMenuScript.item_icon(String(entry["item_id"])), String(entry["tier_id"]), 0, "", int(entry.get("affix_count", 0)))
	DescriptionHover.attach(cell, String(entry.get("rich_tooltip", "")))
	top.add_child(cell)
	var name_label := Label.new()
	name_label.text = String(entry["name"])
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(100, 0)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", TIER_COLORS.get(String(entry["tier_id"]), TEXT) as Color)
	top.add_child(name_label)
	var buy := Button.new()
	buy.name = "Buy"
	var sold := bool(entry.get("sold", false))
	buy.text = "VENDIDO" if sold else "%d P" % int(entry["price"])
	buy.disabled = sold or not bool(entry.get("affordable", false))
	buy.tooltip_text = "%s (%s)" % [String(entry["name"]), String(entry["tier"])]
	var index := int(entry["index"])
	buy.pressed.connect(func() -> void: buy_requested.emit(index))
	card.add_child(buy)
	if sold:
		cell.modulate = Color(1, 1, 1, 0.35)
	return card
