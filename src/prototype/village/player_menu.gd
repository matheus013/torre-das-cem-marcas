class_name PrototypePlayerMenu
extends Control

const BindingsScript := preload("res://src/core/app/input_bindings.gd")
const UiSkin := preload("res://src/presentation/ui/game_ui_skin.gd")

signal stat_requested(stat: StringName)
signal stats_reset_requested
signal milestone_requested(choice_id: StringName)
signal equip_requested(instance_id: StringName)
signal unequip_requested(slot: int, index: int)
signal sell_requested(instance_id: StringName)
signal sell_all_requested
signal loot_filter_requested(tier: String)
signal auto_sell_requested(tier: String)
signal gem_slot_requested(slot: int, gem_id: String)
signal support_attach_requested(slot: int, support_id: String)
signal support_detach_requested(slot: int, support_id: String)
signal start_floor_requested(floor_number: int)
signal difficulty_requested(level: int)
signal journal_requested
signal gem_evolution_requested(gem_id: String, choice_id: String)

const SpriteLibraryScript := preload("res://src/presentation/art/sprite_library.gd")

const BG := Color("111014f5")
const PANEL := Color("1b1a1ff5")
const BORDER := Color("8f7a6a")
const GOLD := Color("e8b84a")
const TEXT := Color("f2e6c9")
const MUTED := Color("aaa59a")

var _model: Dictionary = {}
var _active_tab := "inventory"
var _content: VBoxContainer
var _title: Label
var _tab_buttons: Dictionary = {}
var _scroll: ScrollContainer
var _sell_dialog: ConfirmationDialog
var _pending_sell: StringName = &""
var _sell_all_dialog: ConfirmationDialog
var _reset_dialog: ConfirmationDialog
var _bestiary_selected := ""
var _show_details := false
var _frame: PanelContainer
var _tabs: GridContainer
var _compact := false
var _comparison: RichTextLabel
var _comparison_id := ""


func _ready() -> void:
	UiSkin.apply(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_shell()
	resized.connect(_layout_shell)
	_layout_shell()
	hide()


func open(tab: String) -> void:
	_active_tab = tab
	show()
	_rebuild()
	_scroll.scroll_vertical = 0
	(_tab_buttons[_active_tab] as Button).grab_focus()


func close() -> void:
	hide()


func refresh(model: Dictionary) -> void:
	_model = model.duplicate(true)
	if visible:
		_rebuild()


func _build_shell() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = BG
	add_child(shade)
	var frame := PanelContainer.new()
	_frame = frame
	frame.name = "MenuFrame"
	frame.add_theme_stylebox_override("panel", UiSkin.frame(true, 22))
	add_child(frame)
	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 12)
	frame.add_child(root_column)
	var header := HBoxContainer.new()
	root_column.add_child(header)
	_title = Label.new()
	_title.text = "REGISTRO DA EXPEDICAO"
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Sem largura mínima, na primeira montagem o título recebe 1 px, quebra letra por letra, mede
	# ~680 px de altura e o quadro do menu cresce além da tela (regressão de 2026-10-11).
	_title.custom_minimum_size.x = 180.0
	header.add_child(_title)
	var journal_button := Button.new()
	journal_button.name = "Journal"
	journal_button.text = "Diario"
	journal_button.custom_minimum_size = Vector2(80, 34)
	UiSkin.icon_button(journal_button, "journal", "Diario de expedicao")
	journal_button.custom_minimum_size = Vector2(40, 38)
	journal_button.pressed.connect(func() -> void: journal_requested.emit())
	header.add_child(journal_button)
	var close_button := Button.new()
	close_button.text = "X"
	close_button.tooltip_text = "Fechar"
	close_button.custom_minimum_size = Vector2(38.0, 34.0)
	UiSkin.icon_button(close_button, "close", "Fechar")
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var tabs := GridContainer.new()
	_tabs = tabs
	tabs.columns = 5
	tabs.add_theme_constant_override("separation", 6)
	root_column.add_child(tabs)
	for spec in [["inventory", "INVENTARIO"], ["character", "PERSONAGEM"], ["skills", "SKILLS"], ["tower", "TORRE"], ["bestiary", "BESTIARIO"]]:
		var button := Button.new()
		button.text = spec[1]
		button.icon = UiSkin.icon(spec[0])
		button.expand_icon = true
		button.add_theme_font_size_override("font_size", 13)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(140.0, 40.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.name = "Tab_%s" % spec[0]
		button.pressed.connect(_select_tab.bind(spec[0]))
		tabs.add_child(button)
		_tab_buttons[spec[0]] = button
	var separator := HSeparator.new()
	root_column.add_child(separator)
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	root_column.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)
	_comparison = RichTextLabel.new()
	_comparison.name = "EquipmentComparison"
	_comparison.bbcode_enabled = true
	_comparison.custom_minimum_size.y = 140
	_comparison.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comparison.add_theme_font_size_override("normal_font_size", 13)
	_comparison.hide()
	root_column.add_child(_comparison)


func _layout_shell() -> void:
	if _frame == null:
		return
	_tabs.columns = 3 if size.x < 800.0 else 5
	_fit_frame()
	# Ao encolher, o título com quebra de linha mede uma altura enorme por um instante e o quadro
	# cresce junto; um Control nunca encolhe sozinho. Reaplica o tamanho depois que os mínimos se
	# recalculam (painel de inventário passava da tela em 480x600).
	_fit_frame.call_deferred()
	var compact := _frame.size.x < 920.0
	if compact != _compact:
		_compact = compact
		if visible and not _model.is_empty():
			_rebuild()


func _fit_frame() -> void:
	_frame.size = Vector2(minf(960.0, maxf(300.0, size.x - 32.0)), minf(640.0, maxf(300.0, size.y - 32.0)))
	_frame.position = (size - _frame.size) * 0.5


func _select_tab(tab: String) -> void:
	_active_tab = tab
	_rebuild()
	_scroll.scroll_vertical = 0


func _rebuild() -> void:
	if _content == null:
		return
	_comparison.hide()
	_comparison.text = ""
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	for tab: String in _tab_buttons:
		(_tab_buttons[tab] as Button).button_pressed = tab == _active_tab
	match _active_tab:
		"character": _build_character()
		"skills": _build_skills()
		"tower": _build_tower()
		"bestiary": _build_bestiary()
		_: _build_inventory()
	_wrap_content(_content)


func _wrap_content(node: Node) -> void:
	if node is Label:
		if node.custom_minimum_size.x == 0:
			node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elif node is OptionButton:
		node.fit_to_longest_item = false
		node.clip_text = true
	elif node is Button:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for child in node.get_children():
		_wrap_content(child)


func _fit_item_grid(grid: GridContainer, maximum: int) -> void:
	grid.resized.connect(func() -> void:
		grid.columns = clampi(int((grid.size.x + 4.0) / 56.0), 1, maximum))
	grid.columns = 1


const LOOT_FILTER_OPTIONS := [["common", "Recolher tudo"], ["uncommon", "Incomum ou melhor"], ["rare", "Raro ou melhor"], ["epic", "Epico ou melhor"]]
const AUTO_SELL_OPTIONS := [["", "Desligada"], ["uncommon", "Vender comuns"], ["rare", "Abaixo de raro"], ["epic", "Abaixo de epico"]]


## Inventário no estilo de Hero Siege (decisão 584): boneco da personagem com os encaixes em volta,
## mochila em grade de ícones com a cor da raridade e saque como ícones com quantidade.
## Clique na mochila equipa; botão direito vende (com confirmação); clique no boneco desequipa.
const DOLL_SIZE := Vector2(380.0, 376.0)
const DOLL_SLOTS := {
	"AMULETO": Vector2(164, 0), "ARMA": Vector2(20, 64), "OFFHAND": Vector2(308, 64),
	"ARMADURA": Vector2(20, 126), "CALCA": Vector2(308, 126), "LUVAS": Vector2(20, 188), "BOTAS": Vector2(308, 188),
}
const BACKPACK_COLUMNS := 7
const BACKPACK_MIN_CELLS := 42


func _build_inventory() -> void:
	var top: BoxContainer = VBoxContainer.new() if _compact else HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	_content.add_child(top)
	var left := VBoxContainer.new()
	top.add_child(left)
	left.add_child(_header_label("EQUIPAMENTO", "%d / %d" % [int(_model.get("equipped_count", 0)), (_model.get("equipment_slots", []) as Array).size()]))
	left.add_child(_build_doll())
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(right)
	var available: Array = _model.get("inventory_equipment", []) as Array
	var backpack_header := _header_label("MOCHILA", "%d pecas  |  %d P" % [available.size(), int(_model.get("silver", 0))])
	var sell_all := Button.new()
	sell_all.name = "SellAll"
	var preview := _model.get("sell_all", {}) as Dictionary
	sell_all.text = "VENDER TUDO"
	sell_all.disabled = int(preview.get("count", 0)) == 0
	sell_all.tooltip_text = "Vende %d pecas da mochila por %d P. Pecas equipadas, lendarias e armas unicas ficam." % [int(preview.get("count", 0)), int(preview.get("price", 0))]
	sell_all.pressed.connect(_confirm_sell_all)
	backpack_header.add_child(sell_all)
	right.add_child(backpack_header)
	var grid := GridContainer.new()
	grid.name = "Backpack"
	_fit_item_grid(grid, BACKPACK_COLUMNS)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	right.add_child(grid)
	var cells := maxi(BACKPACK_MIN_CELLS, int(ceil(available.size() / float(BACKPACK_COLUMNS))) * BACKPACK_COLUMNS)
	for index in range(cells):
		var cell := ItemCell.new()
		grid.add_child(cell)
		if index >= available.size():
			continue
		var entry := available[index] as Dictionary
		cell.setup(item_icon(String(entry.get("item_id", ""))), String(entry.get("tier_id", "common")), 0, "", int(entry.get("affix_count", 0)))
		cell.name = "Item_%s" % String(entry.get("instance_id", ""))
		DescriptionHover.attach(cell, String(entry.get("rich_tooltip", entry.get("tooltip", ""))))
		var instance_id := StringName(String(entry.get("instance_id", "")))
		cell.pressed.connect(func() -> void: equip_requested.emit(instance_id))
		cell.secondary_pressed.connect(_confirm_sell.bind(entry))
		cell.mouse_entered.connect(_show_equipment_comparison.bind(entry))
		cell.focus_entered.connect(_show_equipment_comparison.bind(entry))
	if not available.is_empty():
		var selected: Dictionary = available[0]
		for entry: Dictionary in available:
			if String(entry["instance_id"]) == _comparison_id:
				selected = entry
		_show_equipment_comparison(selected)
	var filters := VBoxContainer.new()
	filters.add_theme_constant_override("separation", 12)
	right.add_child(filters)
	_add_choice(filters, "Filtro de saque", LOOT_FILTER_OPTIONS, String(_model.get("loot_filter", "common")), func(tier: String) -> void: loot_filter_requested.emit(tier),
		"Equipamentos abaixo desta raridade ficam no chao, apagados. Materiais sempre sao recolhidos.")
	_add_choice(filters, "Autovenda", AUTO_SELL_OPTIONS, String(_model.get("auto_sell", "")), func(tier: String) -> void: auto_sell_requested.emit(tier),
		"Ao voltar a vila, vende as pecas do inventario abaixo desta raridade. Pecas equipadas e armas unicas nunca sao vendidas.")
	_content.add_child(_header_label("CARGA DA EXPEDICAO", "%d tipos" % (_model.get("carried_loot", {}) as Dictionary).size()))
	_loot_rows(_model.get("carried_loot", {}) as Dictionary, "Nenhum saque carregado")
	_content.add_child(_header_label("ARMAZEM DA VILA", "%d tipos" % (_model.get("banked_loot", {}) as Dictionary).size()))
	_loot_rows(_model.get("banked_loot", {}) as Dictionary, "Armazem vazio")


func _show_equipment_comparison(entry: Dictionary) -> void:
	if not is_instance_valid(_comparison):
		return
	_comparison_id = String(entry.get("instance_id", ""))
	var data := entry.get("comparison", {}) as Dictionary
	var lines := PackedStringArray(["[b]%s[/b]" % String(entry.get("name", ""))])
	if data.is_empty():
		_comparison.text = ""
		return
	lines.append("Substitui: %s" % String(data.get("replaces_name", "Encaixe vazio")))
	if not data.get("can_equip", false):
		lines.append("[color=#e5a2a0]%s[/color]" % String(data.get("reason", "Encaixe incompativel.")))
	else:
		for row: Dictionary in data.get("rows", []):
			var delta := float(row["delta"])
			var unit := String(row["unit"])
			var better := delta < 0 if row.get("lower_is_better", false) else delta > 0
			lines.append("%s: %.2f%s > %.2f%s [color=#%s](%+.2f%s)[/color]" % [row["label"], row["before"], unit, row["after"], unit, "8fcab2" if better else "e5a2a0", delta, " p.p." if unit == "%" else unit])
		if (data.get("rows", []) as Array).is_empty():
			lines.append("Sem alteracao nos atributos derivados comparados.")
		for passive: String in data.get("gained_passives", []):
			lines.append("+ Passiva: " + passive)
		for passive: String in data.get("lost_passives", []):
			lines.append("- Passiva: " + passive)
		for support: String in data.get("inactive_supports", []):
			lines.append("! Suporte ficara inativo: " + support)
	_comparison.text = "\n".join(lines)
	_comparison.show()
	_comparison.scroll_to_line(0)


## Boneco: retrato ampliado no centro, sete encaixes em volta e anéis e relíquias embaixo.
func _build_doll() -> Control:
	var doll := Control.new()
	doll.name = "Doll"
	doll.custom_minimum_size = DOLL_SIZE
	var backdrop := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("16221f")
	style.border_color = Color("4d6055")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	backdrop.add_theme_stylebox_override("panel", style)
	backdrop.position = Vector2(84, 56)
	backdrop.size = Vector2(212, 186)
	doll.add_child(backdrop)
	var portrait := TextureRect.new()
	portrait.texture = SpriteLibraryScript.texture("characters/" + String(_model.get("character_id", "")))
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(110, 64)
	portrait.size = Vector2(160, 170)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	doll.add_child(portrait)
	var rings := 0
	var relics := 0
	for slot: Dictionary in _model.get("equipment_slots", []) as Array:
		var label := String(slot.get("slot", ""))
		var position := Vector2.ZERO
		var caption := label
		if DOLL_SLOTS.has(label):
			position = DOLL_SLOTS[label] as Vector2
		elif label.begins_with("ANEL"):
			position = Vector2(134 + rings * 56, 260)
			caption = "ANEL"
			rings += 1
		else:
			position = Vector2(78 + relics * 56, 320)
			caption = "RELIQ."
			relics += 1
		var cell := ItemCell.new()
		cell.name = "Slot_%s" % label.replace(" ", "_")
		cell.position = position
		doll.add_child(cell)
		if not bool(slot.get("occupied", false)):
			cell.setup(null, "", 0, caption)
			continue
		cell.setup(item_icon(String(slot.get("item_id", ""))), String(slot.get("tier_id", "common")))
		DescriptionHover.attach(cell, String(slot.get("rich_tooltip", slot.get("tooltip", ""))))
		var slot_id := int(slot.get("slot_id", -1))
		var slot_index := int(slot.get("index", 0))
		cell.pressed.connect(func() -> void: unequip_requested.emit(slot_id, slot_index))
	return doll


## Status detalhados no estilo de Dofus (decisão 589), abertos por um botão: atributos separados em
## base, equipamento, total e efetivo; números de combate; bônus de dano por tipo e elemento.
func _build_detailed_stats() -> void:
	var details := _model.get("detailed_stats", {}) as Dictionary
	if details.is_empty():
		return
	var toggle := Button.new()
	toggle.name = "DetailedStatsToggle"
	toggle.text = ("v  STATUS DETALHADOS" if _show_details else ">  STATUS DETALHADOS")
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.add_theme_color_override("font_color", GOLD)
	toggle.pressed.connect(func() -> void:
		_show_details = not _show_details
		var scroll := _scroll.scroll_vertical
		_rebuild()
		_scroll.set_deferred("scroll_vertical", scroll))
	_content.add_child(toggle)
	if not _show_details:
		return
	var table := GridContainer.new()
	table.name = "DetailedAttributes"
	table.columns = 5
	table.add_theme_constant_override("h_separation", 8 if _compact else 26)
	_content.add_child(table)
	for header in ["ATRIBUTO", "BASE", "EQUIPAMENTO", "TOTAL", "EFETIVO"]:
		table.add_child(_detail_cell(header, GOLD))
	for row: Dictionary in details.get("attributes", []) as Array:
		table.add_child(_detail_cell(_stat_label(String(row["stat"])), TEXT))
		table.add_child(_detail_cell("%d" % roundi(float(row["base"])), TEXT))
		var bonus := roundi(float(row["equipment"]))
		table.add_child(_detail_cell(("+%d" % bonus) if bonus > 0 else str(bonus), Color("7fb0ff") if bonus != 0 else MUTED))
		table.add_child(_detail_cell("%d" % roundi(float(row["total"])), TEXT))
		var effective := float(row["effective"])
		table.add_child(_detail_cell("%.0f" % effective, Color("e8b84a") if effective < float(row["total"]) - 0.5 else TEXT))
	_add_text("Efetivo: valor usado pelas formulas, com redutores acima de 100 pontos.", MUTED)
	for group: Array in [["COMBATE", details.get("combat", [])], ["BONUS DE DANO", details.get("damage", [])]]:
		var title := _detail_cell(String(group[0]), GOLD)
		_content.add_child(title)
		var grid := GridContainer.new()
		grid.columns = 2 if _compact else 4
		grid.add_theme_constant_override("h_separation", 26)
		_content.add_child(grid)
		for entry: Array in group[1] as Array:
			grid.add_child(_detail_cell(String(entry[0]), MUTED))
			var value := String(entry[1])
			grid.add_child(_detail_cell(value, TEXT if not (value.begins_with("+0") or value == "0%") else MUTED))


func _detail_cell(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", color)
	return label


func _header_label(title: String, detail: String) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_font_size_override("font_size", 15)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = detail
	info.add_theme_color_override("font_color", MUTED)
	row.add_child(info)
	return row


## Botão direito na mochila: vender pede confirmação, para um clique errado não custar uma peça boa.
func _confirm_sell(entry: Dictionary) -> void:
	if _sell_dialog == null:
		_sell_dialog = ConfirmationDialog.new()
		_sell_dialog.name = "SellDialog"
		_sell_dialog.title = "Vender"
		_sell_dialog.ok_button_text = "Vender"
		_sell_dialog.cancel_button_text = "Manter"
		_sell_dialog.confirmed.connect(func() -> void: sell_requested.emit(_pending_sell))
		add_child(_sell_dialog)
	_pending_sell = StringName(String(entry.get("instance_id", "")))
	_sell_dialog.dialog_text = "Vender %s (%s) por %d P?" % [String(entry.get("name", "")), String(entry.get("tier", "")), int(entry.get("sell_price", 0))]
	_sell_dialog.popup_centered()


func _confirm_reset_stats() -> void:
	if _reset_dialog == null:
		_reset_dialog = ConfirmationDialog.new()
		_reset_dialog.name = "ResetStatsDialog"
		_reset_dialog.title = "Resetar atributos"
		_reset_dialog.ok_button_text = "Resetar"
		_reset_dialog.cancel_button_text = "Manter"
		_reset_dialog.dialog_text = "Devolver todos os pontos distribuidos para redistribuir?\nGemas podem agir num nivel menor ate os requisitos voltarem a ser cumpridos."
		_reset_dialog.confirmed.connect(func() -> void: stats_reset_requested.emit())
		add_child(_reset_dialog)
	_reset_dialog.popup_centered()


## Vender tudo pede confirmação com quantidade e valor; lendários e armas únicas nunca entram.
func _confirm_sell_all() -> void:
	if _sell_all_dialog == null:
		_sell_all_dialog = ConfirmationDialog.new()
		_sell_all_dialog.name = "SellAllDialog"
		_sell_all_dialog.title = "Vender tudo"
		_sell_all_dialog.ok_button_text = "Vender tudo"
		_sell_all_dialog.cancel_button_text = "Manter"
		_sell_all_dialog.confirmed.connect(func() -> void: sell_all_requested.emit())
		add_child(_sell_all_dialog)
	var preview := _model.get("sell_all", {}) as Dictionary
	_sell_all_dialog.dialog_text = "Vender %d pecas da mochila por %d P?\nPecas equipadas, lendarias e armas unicas ficam." % [int(preview.get("count", 0)), int(preview.get("price", 0))]
	_sell_all_dialog.popup_centered()


## Bestiário (decisão 593): lista por bioma à esquerda e ficha do monstro à direita. Cada nível de
## conhecimento, conquistado por abates, revela uma seção da ficha.
func _build_bestiary() -> void:
	var book := _model.get("bestiary", {}) as Dictionary
	var entries := book.get("entries", []) as Array
	_content.add_child(_header_label("BESTIARIO", "%d de %d descobertos" % [int(book.get("discovered", 0)), int(book.get("total", 0))]))
	if entries.is_empty():
		_add_text("Nenhum monstro catalogado.", MUTED)
		return
	var selected := {}
	for entry: Dictionary in entries:
		if String(entry["id"]) == _bestiary_selected:
			selected = entry
	if selected.is_empty():
		for entry: Dictionary in entries:
			if int(entry["level"]) > 0:
				selected = entry
				break
	if selected.is_empty():
		selected = entries[0] as Dictionary
	_bestiary_selected = String(selected["id"])
	var columns: BoxContainer = VBoxContainer.new() if _compact else HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	_content.add_child(columns)
	var list := VBoxContainer.new()
	list.name = "BestiaryList"
	list.custom_minimum_size = Vector2(290.0, 0.0)
	list.add_theme_constant_override("separation", 3)
	columns.add_child(list)
	var biome := ""
	for entry: Dictionary in entries:
		if String(entry["biome"]) != biome:
			biome = String(entry["biome"])
			var title := Label.new()
			title.text = biome.to_upper()
			title.add_theme_color_override("font_color", BORDER)
			title.add_theme_font_size_override("font_size", 12)
			list.add_child(title)
		var button := Button.new()
		button.name = "Beast_%s" % String(entry["id"])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = entry == selected
		button.text = "%s  %s%s" % [_stars(int(entry["level"])), String(entry["name"]), "  [%s]" % String(entry["class_name"]) if String(entry["class"]) != "common" else ""]
		button.tooltip_text = "%s: %d abates" % [String(entry["level_name"]), int(entry["kills"])]
		var enemy_id := String(entry["id"])
		button.pressed.connect(func() -> void:
			_bestiary_selected = enemy_id
			_rebuild())
		list.add_child(button)
	var detail := VBoxContainer.new()
	detail.name = "BestiaryDetail"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 6)
	columns.add_child(detail)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	detail.add_child(head)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(72.0, 72.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not String(selected["portrait"]).is_empty():
		var key := "enemies/" + String(selected["portrait"])
		portrait.texture = SpriteLibraryScript.actor_frame(key, Vector2.DOWN, false, 0.0)
		if portrait.texture == null:
			portrait.texture = SpriteLibraryScript.texture(key)
	else:
		portrait.modulate = Color(0.0, 0.0, 0.0, 0.6)
	head.add_child(portrait)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	var name_label := Label.new()
	name_label.name = "BeastName"
	name_label.text = String(selected["name"])
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", GOLD)
	names.add_child(name_label)
	var knowledge := Label.new()
	knowledge.name = "BeastKnowledge"
	knowledge.text = "%s  %s  |  %d abates" % [_stars(int(selected["level"])), String(selected["level_name"]), int(selected["kills"])]
	knowledge.add_theme_color_override("font_color", TEXT)
	names.add_child(knowledge)
	var progress := Label.new()
	progress.name = "BeastNext"
	progress.add_theme_color_override("font_color", MUTED)
	if int(selected["next"]) > 0:
		progress.text = "Abata mais %d para revelar: %s" % [int(selected["next"]) - int(selected["kills"]), String(selected["next_section"])]
	else:
		progress.text = "Conhecimento completo."
	names.add_child(progress)
	for section: Dictionary in selected.get("sections", []) as Array:
		var title := Label.new()
		title.text = String(section["title"]).to_upper()
		title.add_theme_color_override("font_color", GOLD)
		title.add_theme_font_size_override("font_size", 14)
		detail.add_child(title)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 3)
		detail.add_child(grid)
		for row: Array in section["rows"] as Array:
			var key_label := Label.new()
			key_label.text = String(row[0])
			key_label.add_theme_color_override("font_color", MUTED)
			key_label.custom_minimum_size = Vector2(100.0, 0.0)
			key_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			grid.add_child(key_label)
			var value_label := Label.new()
			value_label.text = String(row[1])
			value_label.add_theme_color_override("font_color", TEXT)
			value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			value_label.custom_minimum_size = Vector2(100.0, 0.0)
			grid.add_child(value_label)


static func _stars(level: int) -> String:
	return "★".repeat(level) + "☆".repeat(5 - level)


func _loot_rows(loot: Dictionary, empty_text: String) -> void:
	if loot.is_empty():
		_add_text(empty_text, MUTED)
		return
	var grid := GridContainer.new()
	_fit_item_grid(grid, 15)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_content.add_child(grid)
	var ids := loot.keys()
	ids.sort()
	for item_id: Variant in ids:
		var tier := String((_model.get("item_tiers", {}) as Dictionary).get(String(item_id), "common"))
		var cell := ItemCell.new().setup(item_icon(String(item_id)), tier, int(loot[item_id]))
		grid.add_child(cell)
		DescriptionHover.attach(cell, "%s  x%d\n%s" % [_friendly(String(item_id)), int(loot[item_id]), String((_model.get("item_tooltips", {}) as Dictionary).get(String(item_id), "Item de expedicao."))])


func _build_character() -> void:
	var level := int(_model.get("level", 1))
	var xp := int(_model.get("experience", 0))
	var required := maxi(1, int(_model.get("experience_required", 1)))
	_section(String(_model.get("character_name", "PERSONAGEM")).to_upper(), "NIVEL %d / %d" % [level, int(_model.get("max_level", 100))])
	_add_text("EXPERIENCIA   %d / %d" % [xp, required], GOLD)
	var bar := ProgressBar.new()
	bar.max_value = required
	bar.value = xp
	bar.show_percentage = false
	bar.custom_minimum_size.y = 14.0
	_content.add_child(bar)
	_section("ATRIBUTOS", "%d pontos livres" % int(_model.get("unspent_stat_points", 0)))
	var stats := _model.get("stats", {}) as Dictionary
	for stat_id in ["vitality", "strength", "intelligence", "agility", "fortune", "wisdom"]:
		var row := HBoxContainer.new()
		var label := Label.new()
		var bonus := int((_model.get("stat_bonus", {}) as Dictionary).get(stat_id, 0))
		label.text = "%s   %d%s" % [_stat_label(stat_id), int(stats.get(stat_id, 0)), "  (%s%d)" % ["+" if bonus > 0 else "", bonus] if bonus != 0 else ""]
		if bonus != 0:
			label.tooltip_text = "%d dos pontos e marcos %s %d do equipamento = %d" % [int(stats.get(stat_id, 0)), "+" if bonus > 0 else "-", absi(bonus), int(stats.get(stat_id, 0)) + bonus]
			label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", TEXT)
		row.add_child(label)
		var add_button := Button.new()
		add_button.text = "+"
		add_button.tooltip_text = "Adicionar ponto"
		add_button.custom_minimum_size = Vector2(36.0, 30.0)
		add_button.disabled = int(_model.get("unspent_stat_points", 0)) <= 0
		add_button.pressed.connect(func() -> void: stat_requested.emit(StringName(stat_id)))
		row.add_child(add_button)
		_content.add_child(row)
	var reset := Button.new()
	reset.name = "ResetStats"
	reset.text = "RESETAR ATRIBUTOS"
	reset.tooltip_text = "Devolve todos os pontos distribuidos para redistribuir. Bonus das evolucoes e do equipamento ficam."
	reset.custom_minimum_size = Vector2(200.0, 32.0)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(_confirm_reset_stats)
	_content.add_child(reset)
	_build_detailed_stats()
	var derived := _model.get("derived_stats", {}) as Dictionary
	_section("VALORES DE COMBATE", "atributos e equipamento")
	_add_text("VIDA %.0f   MOVIMENTO %.0f%%   CRITICO %.1f%%   RECARGA -%.0f%%   AREA +%.0f%%   DEFESA -%.0f%%" % [
		float(derived.get("max_health", 100.0)),
		float(derived.get("movement_speed_multiplier", 1.0)) * 100.0,
		float(derived.get("critical_chance", 0.12)) * 100.0,
		float(derived.get("cooldown_reduction", 0.0)) * 100.0,
		(float(derived.get("area_multiplier", 1.0)) - 1.0) * 100.0,
		float(derived.get("damage_reduction", 0.0)) * 100.0,
	], TEXT)
	var chosen: Array = _model.get("chosen_milestones", []) as Array
	var weapon := _model.get("weapon_attack", {}) as Dictionary
	if not weapon.is_empty():
		_section(String(weapon.get("item_name", weapon.get("name", ""))), "Afinidade %.0f%%" % float(weapon.get("affinity", 100.0)))
		_add_text("DANO %.1f   ALCANCE %.0f   INTERVALO %.2fs   CRITICO %.1f%%   GUARDA -%.0f%%" % [float(weapon["damage"]), float(weapon["range"]), float(weapon["interval"]), float(weapon["critical_chance"]) * 100.0, float(weapon.get("guard", 0.0)) * 100.0], TEXT)
		var damage_label := "ARCANO" if String(weapon["damage_type"]) == "arcane" else "FISICO"
		var pattern_label := String({"single":"ALVO UNICO", "line":"LINHA", "cone":"CONE"}.get(String(weapon["pattern"]), ""))
		_add_text("%s   |   %s   |   %s" % [String(weapon["name"]).to_upper(), damage_label, pattern_label], MUTED)
		for stat: String in weapon.get("scaling", {}) as Dictionary:
			_add_text("%s: +%.1f%% por ponto" % [_stat_label(stat), float(weapon["scaling"][stat]) * 100.0], MUTED)
		for type_id: String in weapon.get("affinities", {}) as Dictionary:
			_add_text("%s: %.0f%%" % [String((WeaponCombat.data()["types"][type_id] as Dictionary)["name"]), float(weapon["affinities"][type_id])], MUTED)
	if not chosen.is_empty():
		_section("EVOLUCOES ESCOLHIDAS", "%d de 10" % chosen.size())
		for entry: Dictionary in chosen:
			_add_text("NIVEL %d  ·  %s  ·  %s" % [int(entry.get("level", 0)), _branch_label(String(entry.get("branch", ""))), String(entry.get("name", ""))], GOLD)
			_add_text(String(entry.get("description", "")), MUTED)
	var choices: Array = _model.get("milestone_choices", []) as Array
	if not choices.is_empty():
		_section("EVOLUCAO DO NIVEL %d" % level, "Escolha uma direcao")
		for choice: Dictionary in choices:
			var button := Button.new()
			button.text = "%s  |  %s\n%s" % [_branch_label(String(choice.get("branch", ""))), String(choice.get("name", "")), String(choice.get("description", ""))]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size.y = 58.0
			button.pressed.connect(func() -> void: milestone_requested.emit(StringName(String(choice.get("id", "")))))
			_content.add_child(button)


## Mapa da Torre e recordes: andares alcançados, melhor tempo por modo e escolha do andar de partida.
## Dificuldade do mundo (E1 fase 2): o host escolhe entre as liberadas, fora da Torre; cada botão
## explica o que muda. Concluir o andar 100 libera a seguinte.
func _build_difficulty_picker(safe: bool) -> void:
	var model := _model.get("difficulty", {}) as Dictionary
	if model.is_empty():
		return
	var current := int(model.get("current", 1))
	_section("DIFICULDADE DO MUNDO", "%d de 5 liberadas  ·  conclua o andar 100 para liberar a proxima" % int(model.get("unlocked", 1)))
	var grid := GridContainer.new()
	grid.name = "DifficultyPicker"
	grid.columns = 1 if _compact else 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_content.add_child(grid)
	for entry: Dictionary in model.get("levels", []) as Array:
		var level := int(entry["level"])
		var button := Button.new()
		button.name = "Difficulty_%d" % level
		button.toggle_mode = true
		button.button_pressed = level == current
		button.text = "%d  %s" % [level, String(entry["name"]).to_upper()] if bool(entry["unlocked"]) else "%d  BLOQUEADA" % level
		button.disabled = not bool(entry["unlocked"]) or not safe
		button.tooltip_text = String(entry["summary"])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: difficulty_requested.emit(level))
		grid.add_child(button)


func _build_tower() -> void:
	var deepest := int(_model.get("deepest_floor", 1))
	var start := int(_model.get("tower_start_floor", 1))
	var safe := bool(_model.get("in_safe_area", true))
	_build_difficulty_picker(safe)
	_section("MAPA DA TORRE", "andar mais fundo: %d   ·   proxima entrada: andar %d" % [deepest, start])
	_add_text("Recordes de tempo por andar em SOLO, DUO, TRIO e SQUAD. Andares comuns contam ate a descida; andares de chefe, ate a queda do chefe.", MUTED)
	_add_text("Partilha do saque: cada peca vai para quem a recolhe; armas unicas e divinos sao sorteados para cada jogador; os materiais da carga vao para o armazem comum da vila ao voltar.", MUTED)
	var records := _model.get("records", {}) as Dictionary
	var previous_biome := ""
	for entry: Dictionary in _model.get("floors", []) as Array:
		var number := int(entry.get("number", 1))
		if String(entry.get("biome", "")) != previous_biome:
			previous_biome = String(entry.get("biome", ""))
			_section(previous_biome.to_upper(), "")
		var row: BoxContainer = VBoxContainer.new() if _compact else HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var label := Label.new()
		var kind := "CHEFE" if String(entry.get("kind", "")) == "boss" else "      "
		label.text = "%3d  %s  %s" % [number, kind, String(entry.get("name", ""))]
		label.custom_minimum_size.x = 0.0 if _compact else 330.0
		label.add_theme_color_override("font_color", GOLD if kind == "CHEFE" else TEXT)
		row.add_child(label)
		var by_floor := records.get(str(number), {}) as Dictionary
		var times := GridContainer.new()
		times.columns = 2 if _compact else 4
		times.add_theme_constant_override("h_separation", 10)
		row.add_child(times)
		for mode in ["solo", "duo", "trio", "squad"]:
			var list := by_floor.get(mode, []) as Array
			var time_label := Label.new()
			time_label.custom_minimum_size.x = 92.0
			time_label.text = "%s %s" % [mode.to_upper(), _format_time(float((list[0] as Dictionary)["time"])) if not list.is_empty() else "--"]
			time_label.add_theme_color_override("font_color", TEXT if not list.is_empty() else MUTED)
			times.add_child(time_label)
		var go := Button.new()
		go.text = "PARTIDA" if number == start else "partir daqui"
		go.disabled = not safe or number == start
		go.custom_minimum_size = Vector2(110.0, 28.0)
		go.pressed.connect(func() -> void: start_floor_requested.emit(number))
		row.add_child(go)
		_content.add_child(row)


func _format_time(seconds: float) -> String:
	return "%d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]


func _branch_label(branch: String) -> String:
	return {"essence": "ESSENCIA", "adaptation": "ADAPTACAO", "convergence": "CONVERGENCIA"}.get(branch, branch.to_upper()) as String


func _build_skills() -> void:
	var safe := bool(_model.get("in_safe_area", true))
	var keys: Array[String] = []
	for slot in range(4):
		keys.append(BindingsScript.label("skill_%d" % (slot + 1)))
	_section("GEMAS ATIVAS", " / ".join(keys) if safe else "trocas e evolucoes so em Aresta")
	var gem_options: Array = _model.get("gem_options", []) as Array
	for skill: Dictionary in _model.get("skills", []) as Array:
		_build_skill_card(skill, gem_options, safe)
	var locked := _model.get("locked_gem_sets", []) as Array
	if not locked.is_empty():
		_section("GEMAS A CONQUISTAR", "cada chefe entrega um conjunto a quem estiver na arena")
		for entry: Dictionary in locked:
			_add_text("Andar %d  %s:  %s" % [int(entry.get("floor", 0)), String(entry.get("boss", "")), ", ".join(PackedStringArray(entry.get("gems", []) as Array))], MUTED)
	var auto := _model.get("auto_attack_supports", {}) as Dictionary
	if not auto.is_empty():
		_section("AUTOATAQUE", String(auto.get("weapon_name", "")))
		_add_text("Dano %.1f   |   Intervalo %.2f s   |   Folego %.0f   |   Capacidade %d / %d" % [float(auto["damage"]), float(auto["interval"]), float(auto["breath_cost"]), int(auto["capacity_used"]), int(auto["capacity"])], TEXT)
		var controls := VBoxContainer.new()
		_content.add_child(controls)
		_build_skill_controls(controls, auto, safe)
	_section("PASSIVA AUTORAL", String(_model.get("passive_name", "")))
	_add_text(String(_model.get("passive_description", "")), TEXT)


func _build_skill_card(skill: Dictionary, gem_options: Array, safe: bool) -> void:
	var slot := int(skill.get("slot", 0))
	var gem_id := String(skill.get("id", ""))
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("1c2725")
	box.border_color = Color("4d6055")
	box.set_border_width_all(1)
	box.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", box)
	_content.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	var icon := TextureRect.new()
	icon.texture = null if gem_id.is_empty() else SpriteLibraryScript.texture("icons/" + gem_id)
	icon.custom_minimum_size = Vector2(44.0, 44.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(icon)
	if not gem_id.is_empty():
		DescriptionHover.attach(icon, ContentDescriptions.skill(skill))
	var key_label := Label.new()
	key_label.custom_minimum_size.x = 36
	key_label.text = BindingsScript.label("skill_%d" % (slot + 1))
	key_label.add_theme_font_size_override("font_size", 22)
	key_label.add_theme_color_override("font_color", GOLD)
	header.add_child(key_label)
	var empty := bool(skill.get("empty", false))
	var title := Label.new()
	var level := int(skill.get("level", 1))
	var maximum := int(skill.get("max_level", 4))
	var effective := int(skill.get("effective_level", level))
	title.text = "Encaixe vazio\nEscolha uma das suas gemas" if empty else "%s\nNivel %d / %d%s   %s   Capacidade %d / %d" % [
		String(skill.get("name", "")), level, maximum, "  (age no %d)" % effective if effective < level else "",
		"NIVEL MAXIMO" if level >= maximum else "EXP de uso %d / %d" % [int(skill.get("experience", 0)), int(skill.get("experience_required", 1))],
		int(skill.get("capacity_used", 0)), int(skill.get("capacity", 3)),
	]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", TEXT)
	header.add_child(title)
	if not empty:
		DescriptionHover.attach(title, ContentDescriptions.skill(skill))
	var swap := OptionButton.new()
	swap.custom_minimum_size = Vector2(200.0, 32.0)
	swap.tooltip_text = "Trocar a gema deste encaixe"
	swap.disabled = not safe
	swap.add_item("(vazio)")
	swap.set_item_metadata(0, "")
	var selected := 0
	for index in range(gem_options.size()):
		var option := gem_options[index] as Dictionary
		swap.add_item("%s  Nv %d" % [String(option.get("name", "")), int(option.get("level", 1))])
		swap.set_item_metadata(index + 1, String(option.get("id", "")))
		swap.get_popup().set_item_tooltip(index + 1, String(option.get("description", "")))
		if String(option.get("id", "")) == gem_id:
			selected = index + 1
	swap.select(selected)
	swap.item_selected.connect(func(index: int) -> void:
		var chosen := String(swap.get_item_metadata(index))
		if chosen != gem_id:
			gem_slot_requested.emit(slot, chosen)
	)
	if _compact:
		swap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(swap)
	else:
		header.add_child(swap)
	if empty:
		return
	if not String(skill.get("description", "")).is_empty():
		var description := Label.new()
		description.text = String(skill["description"])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_color_override("font_color", TEXT)
		column.add_child(description)

	var stats := Label.new()
	var values := PackedStringArray()
	for spec in [["power", "Dano por acerto"], ["barrier", "Barreira"], ["healing", "Cura por pulso"]]:
		if float(skill.get(spec[0], 0.0)) > 0.0:
			values.append("%s %.0f" % [spec[1], float(skill[spec[0]])])
	values.append("Recarga %.1f s" % float(skill.get("cooldown", 0.0)))
	values.append("Folego %.0f" % float(skill.get("breath_cost", 0.0)))
	values.append("Cargas %d" % int(skill.get("charges", 1)))
	stats.text = "   |   ".join(values)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_color_override("font_color", MUTED)
	column.add_child(stats)
	var scaling := skill.get("scaling", []) as Array
	if not scaling.is_empty():
		var parts := PackedStringArray()
		for entry: Dictionary in scaling:
			parts.append("%s +%.1f%% por ponto (%.0f)" % [_stat_label(String(entry["stat"])), float(entry["per_point"]) * 100.0, float(entry["points"])])
		var scaling_label := Label.new()
		scaling_label.text = "Escala: %s   =   x%.2f sobre a base %.0f" % [", ".join(parts), float(skill.get("power_multiplier", 1.0)), float(skill.get("base_power", 0.0))]
		scaling_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scaling_label.add_theme_color_override("font_color", MUTED)
		column.add_child(scaling_label)
	if not String(skill.get("unique_weapon", "")).is_empty():
		var unique_label := Label.new()
		unique_label.text = String(skill["unique_weapon"])
		unique_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unique_label.add_theme_color_override("font_color", GOLD)
		column.add_child(unique_label)
	# Requisitos de atributo do nível atual (decisão 588): em vermelho o que falta.
	var requirements := skill.get("requirements", []) as Array
	if not requirements.is_empty():
		var needs := RichTextLabel.new()
		needs.bbcode_enabled = true
		needs.fit_content = true
		needs.scroll_active = false
		var parts := PackedStringArray()
		for need: Dictionary in requirements:
			parts.append("[color=#%s]%s %d[/color] [color=#8f7a6a](tem %d, proximo nivel %d)[/color]" % ["93c25a" if bool(need["met"]) else "e87a6a",
				_stat_label(String(need["stat"])).capitalize(), int(need["value"]), int(need["have"]), int(need["next"])])
		needs.text = "[color=#aaa59a]Requisitos:[/color] " + "   ".join(parts)
		if int(skill.get("effective_level", level)) < level:
			needs.text += "\n[color=#e87a6a]Sem os requisitos, a gema age no nivel %d.[/color]" % int(skill["effective_level"])
		column.add_child(needs)
	var evolutions := Label.new()
	var next_mastery := int(skill.get("next_mastery", 0))
	evolutions.text = "Modificadores: " + (", ".join(PackedStringArray(skill.get("chosen", []) as Array)) if not (skill.get("chosen", []) as Array).is_empty() else "nenhum") + ("   |   proximo no nivel %d" % next_mastery if next_mastery > 0 else "")
	evolutions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	evolutions.add_theme_color_override("font_color", MUTED)
	column.add_child(evolutions)
	_build_skill_controls(column, skill, safe)


func _build_skill_controls(column: VBoxContainer, skill: Dictionary, safe: bool) -> void:
	var slot := int(skill.get("slot", 0))
	var gem_id := String(skill.get("id", ""))

	var supports_row := VBoxContainer.new()
	supports_row.add_theme_constant_override("separation", 6)
	column.add_child(supports_row)
	var supports_label := Label.new()
	supports_label.text = "Suportes:"
	supports_label.add_theme_color_override("font_color", GOLD)
	supports_row.add_child(supports_label)
	for support: Dictionary in skill.get("supports", []) as Array:
		var chip := Button.new()
		chip.text = "%s (%d)  x" % [String(support.get("name", "")), int(support.get("drain", 0))]
		if not bool(support.get("active", true)):
			chip.text = "%s (inativo)  x" % String(support.get("name", ""))
		chip.tooltip_text = "%s\n%s\nRemover suporte" % ["Mecanica" if String(support.get("category", "")) == "mechanic" else "Buff", String(support.get("description", ""))]
		chip.disabled = not safe
		var support_id := String(support.get("id", ""))
		chip.pressed.connect(func() -> void: support_detach_requested.emit(slot, support_id))
		supports_row.add_child(chip)
	var available: Array = skill.get("available_supports", []) as Array
	if (skill.get("supports", []) as Array).size() < 2 and not available.is_empty():
		var add := OptionButton.new()
		add.disabled = not safe
		add.add_item("+ adicionar suporte")
		add.set_item_metadata(0, "")
		for index in range(available.size()):
			var support := available[index] as Dictionary
			var first_change := String(support.get("preview", "")).split(", ")[0]
			add.add_item("%s | %s (%d)   %s" % ["Mecanica" if String(support.get("category", "")) == "mechanic" else "Buff", String(support.get("name", "")), int(support.get("drain", 0)), first_change])
			add.set_item_metadata(index + 1, String(support.get("id", "")))
			var fits := int(support.get("drain", 0)) <= int(skill.get("capacity", 3)) - int(skill.get("capacity_used", 0))
			add.set_item_disabled(index + 1, not fits)
			add.get_popup().set_item_tooltip(index + 1, String(support.get("description", "")) + "\nNesta gema: " + String(support.get("preview", "")) + ("" if fits else "\nCapacidade insuficiente"))
		add.item_selected.connect(func(index: int) -> void:
			var support_id := String(add.get_item_metadata(index))
			if not support_id.is_empty():
				support_attach_requested.emit(slot, support_id)
		)
		supports_row.add_child(add)

	var pending: Array = skill.get("pending_choices", []) as Array
	if not pending.is_empty():
		var hint := Label.new()
		var mastery := int(skill.get("pending_tier", 5))
		hint.text = ("Nivel 21: escolha o grande modificador desta gema:" if mastery >= 21 else "Nivel %d: escolha um modificador:" % mastery)
		hint.add_theme_color_override("font_color", GOLD)
		column.add_child(hint)
		var choices_row := GridContainer.new()
		choices_row.columns = 1 if _compact else 3
		choices_row.add_theme_constant_override("h_separation", 8)
		choices_row.add_theme_constant_override("v_separation", 8)
		column.add_child(choices_row)
		for choice: Dictionary in pending:
			var button := Button.new()
			# Prévia (decisão 589): o que muda na gema com este modificador, já com seus atributos.
			button.text = "%s\n%s" % [String(choice.get("name", "")), String(choice.get("preview", _describe_modifiers(choice.get("modifiers", {}) as Dictionary)))]
			button.tooltip_text = "%s\n%s" % [_describe_modifiers(choice.get("modifiers", {}) as Dictionary), String(choice.get("preview", ""))]
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size = Vector2(0.0, 64.0)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.disabled = not safe
			var choice_id := String(choice.get("id", ""))
			button.pressed.connect(func() -> void: gem_evolution_requested.emit(gem_id, choice_id))
			choices_row.add_child(button)


const MODIFIER_NAMES := {
	"allies_receive_barrier": "barreira em aliados", "arrival_area": "area na chegada", "arrival_barrier": "barreira na chegada",
	"arrival_damage": "dano na chegada", "attack_interval": "intervalo de ataque", "barrier": "barreira",
	"barrier_per_hit": "barreira por acerto", "breath_cost": "custo de folego", "chain_count": "saltos",
	"chain_range": "alcance do salto", "contact_damage": "dano de contato", "cooldown": "recarga",
	"critical_chance": "chance critica", "damage_taken": "vulnerabilidade", "distance": "distancia",
	"duration": "duracao", "enemy_damage_per_tick": "dano por pulso", "expire_damage": "dano ao expirar",
	"expire_nova_damage": "explosao ao expirar", "expire_radius": "raio ao expirar", "extra_charge": "carga extra",
	"field_follows_player": "campo segue", "follows_player": "segue o portador", "heal_per_chain": "cura por salto",
	"healing": "cura", "homing": "teleguiado", "impact_area": "area no impacto", "inherits_support_one": "herda suporte",
	"knockback": "repulsao", "life_steal": "roubo de vida", "overheal_barrier": "excesso vira barreira",
	"pierce": "perfuracao", "power": "potencia", "projectile_count": "projeteis", "pull_strength": "atracao",
	"radius": "raio", "range": "alcance", "repeat_count": "repeticoes", "repeat_delay": "atraso do eco",
	"repeat_last_target": "repete no ultimo alvo", "return_projectile": "retorna", "ricochet": "ricochetes",
	"slow": "lentidao", "speed": "velocidade", "stability": "estabilidade", "summon_count": "invocacoes",
	"summon_follows_player": "invocacao segue", "trail_damage": "dano no rastro",
	"angle": "abertura", "width": "largura", "angular_speed": "rotacao", "orbit_count": "orbitas",
	"arm_delay": "tempo de armar", "meteor_count": "impactos", "delay": "atraso", "fork_count": "bifurcacoes",
	"remote_nova": "pulso remoto", "inner_radius": "centro vazio", "invulnerability": "invulnerabilidade",
	"breath_per_hit": "Folego por acerto", "breath_on_kill": "Folego por abate", "arrow_count": "flechas",
	"poison_growth": "crescimento do veneno", "spread_radius": "espalhamento", "poison_linger": "toxina apos sair",
	"trigger_radius": "gatilho", "collision_radius": "largura das laminas", "spread": "espalhamento",
	"breath_per_second": "Folego por segundo", "tick_interval": "intervalo das rajadas",
}


func _describe_modifiers(modifiers: Dictionary) -> String:
	var parts: Array[String] = []
	for key: Variant in modifiers:
		var raw := String(key)
		var value: Variant = modifiers[key]
		if raw.ends_with("_multiplier"):
			parts.append("%s x%s" % [_modifier_name(raw.trim_suffix("_multiplier")), str(value)])
		elif raw.ends_with("_add"):
			parts.append("%s %s%s" % [_modifier_name(raw.trim_suffix("_add")), "+" if float(value) >= 0.0 else "", str(value)])
		elif value is bool:
			parts.append(_modifier_name(raw))
		else:
			parts.append("%s %s" % [_modifier_name(raw), str(value)])
	return ", ".join(PackedStringArray(parts))


func _modifier_name(key: String) -> String:
	return String(MODIFIER_NAMES.get(key, key.replace("_", " ")))


func _section(title: String, detail: String) -> void:
	var row: BoxContainer = VBoxContainer.new() if _compact else HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var title_label := Label.new()
	var detail_label := Label.new()
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", GOLD)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.text = detail
	detail_label.add_theme_color_override("font_color", MUTED)
	row.add_child(title_label)
	row.add_child(detail_label)
	_content.add_child(row)


## Rótulo + seletor; emite a chave escolhida.
func _add_choice(parent: Container, title: String, options: Array, current: String, on_pick: Callable, hint: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", MUTED)
	parent.add_child(label)
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(170.0, 30.0)
	for index in range(options.size()):
		picker.add_item(String(options[index][1]))
		picker.set_item_metadata(index, String(options[index][0]))
		if String(options[index][0]) == current:
			picker.select(index)
	picker.item_selected.connect(func(index: int) -> void: on_pick.call(String(picker.get_item_metadata(index))))
	parent.add_child(picker)
	DescriptionHover.attach(picker, hint)


## Ícone do item em assets/sprites/items; nulo quando a peça ainda não tem arte.
static func item_icon(item_id: String) -> Texture2D:
	return SpriteLibraryScript.texture("items/" + item_id) if not item_id.is_empty() else null


## Texto do botão na cor da raridade, mantida também ao passar o mouse e ao focar.
func _add_text(value: String, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	_content.add_child(label)


func _friendly(value: String) -> String:
	return value.replace("_", " ").capitalize()


func _stat_label(stat_id: String) -> String:
	return {
		"vitality": "VITALIDADE", "strength": "FORCA", "intelligence": "INTELIGENCIA",
		"agility": "AGILIDADE", "fortune": "SORTE", "wisdom": "SABEDORIA",
	}.get(stat_id, stat_id.to_upper())
