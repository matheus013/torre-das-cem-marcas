extends Control

signal action_requested(action: String)
var npc_id := ""
var _panel: PanelContainer
var _title: Label
var _dialogue: Label
var _objective: Label
var _journal: Label
var _reward: Label
var _reaction: Label
var _preparation: Label
var _rumor: Label
var _action: Button
var _secondary: Button
var _close: Button
var _selected_action := ""
var _secondary_action := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202923")
	style.border_color = Color("829382")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_panel.add_child(column)
	_title = _label(column, 20)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 16)
	scroll.add_child(text)
	_dialogue = _label(text, 16)
	_reaction = _label(text, 15)
	_rumor = _label(text, 15)
	_objective = _label(text, 16)
	_preparation = _label(text, 14)
	_journal = _label(text, 15)
	_reward = _label(text, 14)
	for label: Label in [_dialogue, _reaction, _rumor, _objective, _preparation, _journal, _reward]:
		label.focus_mode = Control.FOCUS_ALL
		label.focus_entered.connect(func() -> void: label.modulate = Color("e8b84a"))
		label.focus_exited.connect(func() -> void: label.modulate = Color.WHITE)
	_action = Button.new()
	_action.custom_minimum_size.y = 46
	_action.pressed.connect(func() -> void: action_requested.emit(_selected_action))
	column.add_child(_action)
	_secondary = Button.new()
	_secondary.custom_minimum_size.y = 46
	_secondary.pressed.connect(func() -> void: action_requested.emit(_secondary_action))
	column.add_child(_secondary)
	_close = Button.new()
	_close.text = "Fechar"
	_close.custom_minimum_size.y = 46
	_close.pressed.connect(close)
	column.add_child(_close)
	resized.connect(_layout)
	visible = false
	_layout()

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _layout() -> void:
	if _panel == null:
		return
	_panel.size = Vector2(minf(520, maxf(240, size.x - 32)), minf(560, maxf(300, size.y - 32)))
	_panel.position = (size - _panel.size) * 0.5

func open(model: Dictionary, near_npc: bool) -> void:
	npc_id = String(model.get("npc_id", "nara_quiral")) if near_npc else ""
	visible = true
	refresh(model)
	_layout()
	if _action.visible:
		_action.grab_focus.call_deferred()
	elif _secondary.visible and not _secondary.disabled:
		_secondary.grab_focus.call_deferred()
	else:
		_close.grab_focus.call_deferred()

func refresh(model: Dictionary, in_range: bool = true) -> void:
	_title.text = String(model.get("npc_name", "Nara Quiral")) if not npc_id.is_empty() else "Diario de expedicao"
	_dialogue.visible = not npc_id.is_empty()
	_dialogue.text = String(model.get("dialogue", ""))
	_reaction.text = String(model.get("reaction", ""))
	_reaction.visible = not _reaction.text.is_empty()
	_rumor.text = "Rumor nao confirmado\n" + String(model.get("rumor", ""))
	_rumor.visible = not String(model.get("rumor", "")).is_empty()
	_objective.text = "%s\n%s" % [String(model.get("title", "")), String(model.get("objective", ""))]
	var journal := model.get("journal", []) as Array
	_journal.text = "\n\n".join(PackedStringArray(journal)) if not journal.is_empty() else "Nenhuma observacao registrada."
	var preparation := model.get("preparation", []) as Array
	_preparation.text = "Preparo da expedicao\n" + "\n".join(PackedStringArray(preparation)) + "\n\n" + String(model.get("preparation_text", ""))
	_preparation.visible = not preparation.is_empty() and npc_id in ["", "nara_quiral"]
	var reward := model.get("reward", {}) as Dictionary
	_reward.text = "Reservas de expedicao: %d %s%s" % [int(reward.get("quantity", 0)), String(reward.get("name", "")), " (entregue)" if model.get("stage", "") == "completed" else " (ao entregar o relato)"]
	_reward.visible = npc_id in ["", "nara_quiral"]
	_selected_action = String(model.get("action", ""))
	var had_focus := _action.has_focus()
	_action.visible = not npc_id.is_empty() and not _selected_action.is_empty()
	_action.text = String(model.get("action_label", ""))
	_action.disabled = not in_range
	_action.tooltip_text = "Fora do alcance de conversa." if not in_range else ""
	_secondary_action = String(model.get("secondary_action", ""))
	var secondary_focus := _secondary.has_focus()
	_secondary.visible = not npc_id.is_empty() and not _secondary_action.is_empty()
	_secondary.text = String(model.get("secondary_action_label", ""))
	_secondary.disabled = not in_range or not bool(model.get("secondary_enabled", true))
	_secondary.tooltip_text = _action.tooltip_text
	if had_focus and (not _action.visible or _action.disabled):
		_close.grab_focus()
	if secondary_focus and (not _secondary.visible or _secondary.disabled):
		_close.grab_focus()

func close() -> void:
	visible = false
	npc_id = ""
