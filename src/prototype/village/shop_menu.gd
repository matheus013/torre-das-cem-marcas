extends Control
const UiSkin := preload("res://src/presentation/ui/game_ui_skin.gd")

## Loja de equipamentos da Forja (decisão 594): vitrine com ícone na cor da raridade, preço e
## botão de compra; a dica mostra a peça completa (atributos, afixos, passiva).

signal buy_requested(index: int)
signal reroll_requested
signal forge_requested(recipe_id: String, slot: String)
signal ascend_requested(gem_id: String)

const PlayerMenuScript := preload("res://src/prototype/village/player_menu.gd")
const GOLD := Color("e8b84a")
const TEXT := Color("f2e6c9")
const MUTED := Color("aaa59a")
const TIER_COLORS := {"common": Color("d8cdb4"), "uncommon": Color("7fc66a"), "rare": Color("5aa2e8"), "epic": Color("b276e8"), "legendary": Color("f08a3a"), "divine": Color("f6e7a8")}

var _model: Dictionary = {}
var _silver: Label
var _grid: GridContainer
var _reroll: Button
var _recipes: VBoxContainer
var _sharing: Label
var _ascension: VBoxContainer
var _panel: PanelContainer


func _ready() -> void:
	UiSkin.apply(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	_panel = panel
	panel.add_theme_stylebox_override("panel", UiSkin.frame(true, 22))
	add_child(panel)
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
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Textos com quebra precisam de largura mínima: com 1 px na primeira montagem medem milhares de
	# pixels de altura e o painel cresce além da tela (regressão de 2026-10-11).
	title.custom_minimum_size.x = 180.0
	header.add_child(title)
	_silver = Label.new()
	_silver.name = "ShopSilver"
	_silver.add_theme_color_override("font_color", TEXT)
	header.add_child(_silver)
	var hint := Label.new()
	hint.text = "Estoque novo a cada volta da Torre; melhora quanto mais fundo o grupo ja chegou."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 200.0
	hint.add_theme_color_override("font_color", MUTED)
	hint.add_theme_font_size_override("font_size", 12)
	column.add_child(hint)
	_grid = GridContainer.new()
	_grid.name = "ShopGrid"
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	column.add_child(scroll)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Vitrine e receitas da Forja (E1 fase 2b) rolam juntas, sempre na vertical.
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	body.add_child(_grid)
	var recipes_title := Label.new()
	recipes_title.text = "RECEITAS DA FORJA  ·  peca garantida no encaixe escolhido"
	recipes_title.add_theme_color_override("font_color", GOLD)
	body.add_child(recipes_title)
	_recipes = VBoxContainer.new()
	_recipes.name = "ForgeRecipes"
	_recipes.add_theme_constant_override("separation", 6)
	body.add_child(_recipes)
	# Ascensão (decisão 608): 3 armas únicas da mesma gema e Pólen Lunar viram um divino.
	_ascension = VBoxContainer.new()
	_ascension.name = "Ascension"
	_ascension.add_theme_constant_override("separation", 6)
	body.add_child(_ascension)
	_sharing = Label.new()
	_sharing.name = "SharingRule"
	_sharing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sharing.custom_minimum_size.x = 200.0
	_sharing.add_theme_font_size_override("font_size", 11)
	_sharing.add_theme_color_override("font_color", MUTED)
	body.add_child(_sharing)
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
	resized.connect(_layout)
	_layout()
	visible = false


func _layout() -> void:
	if _panel == null:
		return
	_grid.columns = clampi(int((minf(760, size.x - 32) - 60) / 170), 1, 4)
	_fit_panel()
	_fit_panel.call_deferred()


## Um Control nunca encolhe sozinho: reaplica o tamanho depois que os mínimos se recalculam.
func _fit_panel() -> void:
	_panel.size = Vector2(minf(760, size.x - 32), minf(540, size.y - 32))
	_panel.position = (size - _panel.size) * 0.5


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
	for child in _recipes.get_children():
		_recipes.remove_child(child)
		child.queue_free()
	for recipe: Dictionary in _model.get("recipes", []) as Array:
		_recipes.add_child(_recipe_row(recipe, _model.get("slots", {}) as Dictionary))
	_sharing.text = String(_model.get("sharing_rule", ""))
	for child in _ascension.get_children():
		_ascension.remove_child(child)
		child.queue_free()
	var title := Label.new()
	title.text = "ASCENSAO  ·  3 armas unicas da mesma gema + 5 Polen Lunar = 1 item divino" + ("" if bool(_model.get("ascension_open", false)) else "  (abre com a dificuldade 4)")
	title.add_theme_color_override("font_color", ItemTier.color("divine"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 200.0
	_ascension.add_child(title)
	for option: Dictionary in _model.get("ascension", []) as Array:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s  %d/%d  ·  %s %d/%d" % [String(option["name"]), int(option["have"]), int(option["need"]), String(option["material"]), int(option["material_have"]), int(option["material_need"])]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 120.0
		label.add_theme_color_override("font_color", TEXT if bool(option["ready"]) else MUTED)
		row.add_child(label)
		var button := Button.new()
		button.name = "Ascend"
		button.text = "ASCENDER"
		button.disabled = not bool(option["ready"])
		var gem_id := String(option["gem_id"])
		button.pressed.connect(func() -> void: ascend_requested.emit(gem_id))
		row.add_child(button)
		_ascension.add_child(row)


## Receita: nome e custo, encaixe a escolher e botão; bloqueada até vencer o guardião.
func _recipe_row(recipe: Dictionary, slots: Dictionary) -> Control:
	var row := HFlowContainer.new()
	row.name = "Recipe_%s" % String(recipe["id"])
	row.add_theme_constant_override("h_separation", 8)
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = 260.0
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("font_size", 12)
	var unlocked := bool(recipe.get("unlocked", false))
	info.text = "%s (andar %d) -> %s\n%s" % [String(recipe["name"]), int(recipe["floor"]), String(recipe.get("tier_label", "")), String(recipe.get("cost_text", "")) if unlocked else "Venca %s para liberar." % String(recipe.get("boss", ""))]
	info.add_theme_color_override("font_color", TEXT if unlocked else MUTED)
	row.add_child(info)
	var slot := OptionButton.new()
	slot.name = "Slot"
	for key: String in slots:
		slot.add_item(String(slots[key]))
		slot.set_item_metadata(slot.item_count - 1, key)
	slot.disabled = not unlocked
	row.add_child(slot)
	var forge := Button.new()
	forge.name = "Forge"
	forge.text = "FORJAR"
	forge.disabled = not unlocked or not bool(recipe.get("materials_ready", false)) or int(_model.get("silver", 0)) < int(recipe.get("silver", 0))
	var recipe_id := String(recipe["id"])
	forge.pressed.connect(func() -> void: forge_requested.emit(recipe_id, String(slot.get_item_metadata(slot.selected))))
	row.add_child(forge)
	return row


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
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
