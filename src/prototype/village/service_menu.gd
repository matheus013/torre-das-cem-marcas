extends Control
const UiSkin := preload("res://src/presentation/ui/game_ui_skin.gd")

signal purchase_requested(npc_id: String, offer_id: String)
signal talk_requested(npc_id: String)
signal shop_requested
## Moradores com loja de equipamentos (decisão 594).
const SHOP_NPCS := ["dalia_ferral"]
const Services := preload("res://src/gameplay/world/village_services.gd")
var npc_id := ""
var _title: Label
var _balance: Label
var _stock: Label
var _context: Label
var _feedback: Label
var _rows: VBoxContainer
var _buttons: Dictionary = {}
var _close: Button
var _panel: PanelContainer

func _ready() -> void:
	UiSkin.apply(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	_panel = panel
	panel.add_theme_stylebox_override("panel", UiSkin.frame(true, 22))
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)
	_title = _label(column, 19)
	_context = _label(column, 13)
	_balance = _label(column, 14)
	_stock = _label(column, 13)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	column.add_child(_rows)
	_feedback = _label(column, 13)
	var talk := Button.new()
	talk.text = "Conversar"
	talk.custom_minimum_size.y = 44
	talk.pressed.connect(func() -> void:
		var selected := npc_id
		close()
		talk_requested.emit(selected))
	column.add_child(talk)
	_close = Button.new()
	_close.text = "Fechar"
	_close.custom_minimum_size.y = 44
	_close.pressed.connect(close)
	column.add_child(_close)
	resized.connect(_layout)
	_layout()
	visible = false

func _layout() -> void:
	if _panel == null:
		return
	_panel.size = Vector2(minf(520, size.x - 32), minf(620, size.y - 32))
	_panel.position = (size - _panel.size) * 0.5

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func open(npc: Dictionary, state: Dictionary, warehouse: Dictionary, narrative_context: Dictionary = {}) -> void:
	npc_id = String(npc["id"])
	_title.text = String(npc["name"]) + " · " + String(npc["title"])
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for offer: Dictionary in Services.offers(npc_id):
		var button := Button.new()
		button.custom_minimum_size.y = 48
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = String(offer["name"])
		button.tooltip_text = String(offer["description"])
		var costs: Array[String] = []
		if int(offer["price"]) > 0:
			costs.append("%d prata" % int(offer["price"]))
		for resource: String in offer["materials"]:
			costs.append("%d %s" % [int(offer["materials"][resource]), resource])
		var cost := _label(_rows, 12)
		cost.text = " + ".join(costs) if not costs.is_empty() else "Gratuito"
		_rows.add_child(button)
		_buttons[offer["id"]] = button
		button.pressed.connect(func() -> void: purchase_requested.emit(npc_id, String(offer["id"])))
	if npc_id in SHOP_NPCS:
		var shop := Button.new()
		shop.name = "OpenShop"
		shop.custom_minimum_size.y = 48
		shop.text = "Ver equipamentos a venda"
		shop.tooltip_text = "Pecas da forja com afixos ja sorteados, pagas em prata."
		shop.pressed.connect(func() -> void: shop_requested.emit())
		_rows.add_child(shop)
	visible = true
	refresh(state, warehouse, "", narrative_context)
	_close.grab_focus.call_deferred()
	for button: Button in _buttons.values():
		if not button.disabled:
			button.grab_focus.call_deferred()
			break

func refresh(state: Dictionary, warehouse: Dictionary, status: String, narrative_context: Dictionary = {}) -> void:
	if not visible:
		return
	_context.text = String(narrative_context.get("dialogue", ""))
	_context.visible = not _context.text.is_empty()
	var silver := int(state.get("silver", 0))
	_balance.text = "Prata: %d    Suprimentos: %d / 9" % [silver, int(state.get("quick_items", 0))]
	var stock := warehouse.get("stock", {}) as Dictionary
	_stock.text = "Armazem: %d madeira · %d minerio · %d alimentos" % [int(stock.get("madeira", 0)), int(stock.get("minerio", 0)), int(stock.get("alimentos", 0))]
	_feedback.text = status
	for offer: Dictionary in Services.offers(npc_id):
		var available := silver >= int(offer["price"])
		for resource: String in offer["materials"]:
			available = available and int(stock.get(resource, 0)) >= int(offer["materials"][resource])
		if String(offer["effect"]) == "supply":
			available = available and int(state.get("quick_items", 0)) + int(offer["quantity"]) <= 9
		(_buttons[offer["id"]] as Button).disabled = not available

func close() -> void:
	visible = false
	npc_id = ""
