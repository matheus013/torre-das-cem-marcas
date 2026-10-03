extends Control

const MajorEncounterDefinitionScript := preload("res://src/gameplay/encounters/major_encounter_definition.gd")

@export var storage_path := "user://aresta_dev_content.json"
@export var export_path := "res://data/generated/dev_content.json"

var _mode := &"enemy"
var _enemies: Array[Dictionary] = []
var _items: Array[Dictionary] = []
var _enemy_modifiers: Array[Dictionary] = []
var _active_gems: Array[Dictionary] = []
var _support_gems: Array[Dictionary] = []
var _summons: Array[Dictionary] = []
var _major_encounters: Array[Dictionary] = []
var _selected_index := -1
var _fields: Dictionary = {}

var _list: ItemList
var _search: LineEdit
var _form: GridContainer
var _mode_title: Label
var _status: Label
var _preview: Label
var _enemy_button: Button
var _item_button: Button
var _modifier_button: Button
var _active_gem_button: Button
var _support_gem_button: Button
var _summon_button: Button
var _encounter_button: Button


func _ready() -> void:
	_build_interface()
	_load_library()
	var initial_mode := &"enemy"
	for argument in OS.get_cmdline_user_args():
		if argument == "--mode=item":
			initial_mode = &"item"
		elif argument == "--mode=modifier":
			initial_mode = &"modifier"
		elif argument == "--mode=active-gem":
			initial_mode = &"active_gem"
		elif argument == "--mode=support-gem":
			initial_mode = &"support_gem"
		elif argument == "--mode=summon":
			initial_mode = &"summon"
		elif argument == "--mode=encounter":
			initial_mode = &"encounter"
	_show_mode(initial_mode)


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("181b1f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.name = "RootColumn"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20.0
	root.offset_top = 16.0
	root.offset_right = -20.0
	root.offset_bottom = -16.0
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.add_theme_constant_override("separation", 8)
	root.add_child(toolbar)
	var back := Button.new()
	back.text = "Voltar"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/prototype/network/network_prototype.tscn")
	)
	toolbar.add_child(back)
	var title := Label.new()
	title.text = "CENTRAL DE CONTEUDO"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(title)
	var persist := Button.new()
	persist.text = "Salvar biblioteca"
	persist.pressed.connect(_persist_library)
	toolbar.add_child(persist)
	var export := Button.new()
	export.text = "Exportar para o projeto"
	export.pressed.connect(_export_library)
	toolbar.add_child(export)

	var modes := HBoxContainer.new()
	modes.name = "Modes"
	modes.add_theme_constant_override("separation", 6)
	root.add_child(modes)
	_enemy_button = Button.new()
	_enemy_button.text = "Inimigos"
	_enemy_button.toggle_mode = true
	_enemy_button.pressed.connect(func() -> void: _show_mode(&"enemy"))
	modes.add_child(_enemy_button)
	_item_button = Button.new()
	_item_button.text = "Itens"
	_item_button.toggle_mode = true
	_item_button.pressed.connect(func() -> void: _show_mode(&"item"))
	modes.add_child(_item_button)
	_modifier_button = Button.new()
	_modifier_button.text = "Afixos de inimigos"
	_modifier_button.toggle_mode = true
	_modifier_button.pressed.connect(func() -> void: _show_mode(&"modifier"))
	modes.add_child(_modifier_button)
	_active_gem_button = Button.new()
	_active_gem_button.text = "Gemas Ativas"
	_active_gem_button.toggle_mode = true
	_active_gem_button.pressed.connect(func() -> void: _show_mode(&"active_gem"))
	modes.add_child(_active_gem_button)
	_support_gem_button = Button.new()
	_support_gem_button.text = "Suportes"
	_support_gem_button.toggle_mode = true
	_support_gem_button.pressed.connect(func() -> void: _show_mode(&"support_gem"))
	modes.add_child(_support_gem_button)
	_summon_button = Button.new()
	_summon_button.text = "Summons"
	_summon_button.toggle_mode = true
	_summon_button.pressed.connect(func() -> void: _show_mode(&"summon"))
	modes.add_child(_summon_button)
	_encounter_button = Button.new()
	_encounter_button.text = "Boss e Raid"
	_encounter_button.toggle_mode = true
	_encounter_button.pressed.connect(func() -> void: _show_mode(&"encounter"))
	modes.add_child(_encounter_button)

	var body := HSplitContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 330
	root.add_child(body)

	var browser := VBoxContainer.new()
	browser.name = "Browser"
	browser.custom_minimum_size = Vector2(300.0, 0.0)
	browser.add_theme_constant_override("separation", 8)
	body.add_child(browser)
	_search = LineEdit.new()
	_search.name = "Search"
	_search.placeholder_text = "Buscar por ID, nome ou tipo"
	_search.text_changed.connect(func(_value: String) -> void: _refresh_list())
	browser.add_child(_search)
	_list = ItemList.new()
	_list.name = "Entries"
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_select_visible_entry)
	browser.add_child(_list)
	var list_actions := HBoxContainer.new()
	list_actions.add_theme_constant_override("separation", 6)
	browser.add_child(list_actions)
	var create := Button.new()
	create.text = "Novo"
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create.pressed.connect(_new_entry)
	list_actions.add_child(create)
	var duplicate := Button.new()
	duplicate.text = "Duplicar"
	duplicate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duplicate.pressed.connect(_duplicate_entry)
	list_actions.add_child(duplicate)
	var remove := Button.new()
	remove.text = "Excluir"
	remove.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove.pressed.connect(_delete_entry)
	list_actions.add_child(remove)

	var editor_scroll := ScrollContainer.new()
	editor_scroll.name = "EditorScroll"
	editor_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(editor_scroll)
	var editor := VBoxContainer.new()
	editor.name = "Editor"
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.add_theme_constant_override("separation", 12)
	editor_scroll.add_child(editor)
	_mode_title = Label.new()
	_mode_title.add_theme_font_size_override("font_size", 20)
	editor.add_child(_mode_title)
	_form = GridContainer.new()
	_form.name = "Form"
	_form.columns = 2
	_form.add_theme_constant_override("h_separation", 14)
	_form.add_theme_constant_override("v_separation", 9)
	editor.add_child(_form)
	_preview = Label.new()
	_preview.name = "Preview"
	_preview.custom_minimum_size = Vector2(0.0, 86.0)
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.add_theme_color_override("font_color", Color("c7d0d6"))
	editor.add_child(_preview)
	var save_entry := Button.new()
	save_entry.name = "SaveEntry"
	save_entry.text = "Aplicar entrada"
	save_entry.pressed.connect(_save_entry)
	editor.add_child(save_entry)

	_status = Label.new()
	_status.name = "Status"
	_status.text = "Rascunhos: %s" % storage_path
	_status.add_theme_color_override("font_color", Color("aeb9c0"))
	root.add_child(_status)


func _show_mode(mode: StringName) -> void:
	_mode = mode
	_selected_index = -1
	_enemy_button.set_pressed_no_signal(mode == &"enemy")
	_item_button.set_pressed_no_signal(mode == &"item")
	_modifier_button.set_pressed_no_signal(mode == &"modifier")
	_active_gem_button.set_pressed_no_signal(mode == &"active_gem")
	_support_gem_button.set_pressed_no_signal(mode == &"support_gem")
	_summon_button.set_pressed_no_signal(mode == &"summon")
	_encounter_button.set_pressed_no_signal(mode == &"encounter")
	match mode:
		&"enemy":
			_mode_title.text = "EDITOR DE INIMIGOS"
		&"item":
			_mode_title.text = "EDITOR DE ITENS"
		&"modifier":
			_mode_title.text = "EDITOR DE AFIXOS DE INIMIGOS"
		&"active_gem":
			_mode_title.text = "EDITOR DE GEMAS ATIVAS"
		&"support_gem":
			_mode_title.text = "EDITOR DE GEMAS DE SUPORTE"
		&"summon":
			_mode_title.text = "EDITOR DE SUMMONS"
		&"encounter":
			_mode_title.text = "EDITOR DE BOSS E RAID"
	_build_form()
	_refresh_list()
	_clear_form()


func _build_form() -> void:
	for child in _form.get_children():
		child.queue_free()
	_fields.clear()
	_add_line_field(&"id", "ID estavel")
	_add_line_field(&"name", "Nome")
	if _mode == &"enemy":
		_add_option_field(&"kind", "Comportamento", ["melee", "ranged", "ambusher", "mimic", "support", "boss", "raid"])
		_add_option_field(&"encounter_class", "Classe de encontro", ["common", "elite", "boss", "raid"])
		_add_option_field(&"race_id", "Raca", ["juntideo", "calcario", "rebocado", "moldado", "enxertado"])
		_add_option_field(&"rank_id", "Grau", ["nascente", "maduro", "evoluido", "alfa", "apice"])
		_add_number_field(&"health", "Vida maxima", 1.0, 100000.0, 60.0)
		_add_number_field(&"speed", "Velocidade", 0.0, 1000.0, 42.0)
		_add_number_field(&"damage", "Dano", 0.0, 10000.0, 12.0)
		_add_number_field(&"attack_interval", "Intervalo de ataque", 0.05, 60.0, 0.8, 0.05)
		_add_number_field(&"loot_value", "Valor de loot", 0.0, 10000.0, 1.0)
	elif _mode == &"item":
		_add_option_field(&"item_type", "Tipo", ["weapon", "offhand", "armor", "accessory", "relic", "consumable", "material"])
		_add_option_field(&"tier", "Tier", ["common", "uncommon", "rare", "epic", "legendary"])
		_add_option_field(&"slot", "Slot", ["none", "weapon", "offhand", "amulet", "armor", "gloves", "boots", "pants", "ring", "relic"])
		_add_number_field(&"power", "Orcamento de poder", 0.0, 100000.0, 1.0)
		_add_multiline_field(&"description", "Descricao mecanica")
	elif _mode == &"modifier":
		_add_option_field(&"position", "Posicao no nome", ["prefix", "suffix"])
		_add_number_field(&"weight", "Peso de sorteio", 1.0, 10000.0, 100.0)
		_add_number_field(&"health_multiplier", "Multiplicador de Vida", 0.05, 20.0, 1.0, 0.05)
		_add_number_field(&"speed_multiplier", "Multiplicador de velocidade", 0.05, 20.0, 1.0, 0.05)
		_add_number_field(&"damage_multiplier", "Multiplicador de dano", 0.05, 20.0, 1.0, 0.05)
		_add_number_field(&"attack_interval_multiplier", "Multiplicador de intervalo", 0.05, 20.0, 1.0, 0.05)
		_add_number_field(&"loot_multiplier", "Multiplicador de loot", 0.0, 20.0, 1.0, 0.05)
		_add_line_field(&"mechanic_id", "Mecanica opcional")
	elif _mode == &"active_gem":
		_add_option_field(&"mechanic", "Mecanica", ["projectile", "dash", "nova", "field", "barrier", "chain", "summon", "sanctuary"])
		_add_line_field(&"summon_definition_id", "Definicao de summon")
		_add_number_field(&"summon_count", "Quantidade de summons", 1.0, 8.0, 1.0)
		_add_line_field(&"tags", "Tags separadas por virgula")
		_add_number_field(&"cooldown", "Recarga", 0.05, 60.0, 2.0, 0.05)
		_add_number_field(&"breath_cost", "Custo de Folego", 0.0, 100.0, 0.0)
		_add_number_field(&"power", "Potencia base", 0.0, 100000.0, 20.0)
		_add_number_field(&"radius", "Raio base", 0.0, 2000.0, 60.0)
		_add_number_field(&"range", "Alcance base", 0.0, 5000.0, 300.0)
		_add_number_field(&"duration", "Duracao base", 0.0, 120.0, 0.0, 0.1)
		_add_multiline_field(&"evolutions", "Evolucoes em JSON")
	elif _mode == &"support_gem":
		_add_line_field(&"requires", "Tags exigidas por virgula")
		_add_number_field(&"drain", "Custo de capacidade", 1.0, 100.0, 2.0)
		_add_multiline_field(&"modifiers", "Modificadores em JSON")
	elif _mode == &"summon":
		_add_option_field(&"behavior", "Comportamento", ["stationary", "follow_owner", "chase_target"])
		_add_option_field(&"targeting", "Selecao de alvo", ["nearest_hostile", "owner_target", "lowest_health_hostile"])
		_add_option_field(&"replacement_policy", "Ao atingir o limite", ["oldest", "reject"])
		_add_number_field(&"health", "Vida maxima", 1.0, 100000.0, 45.0)
		_add_number_field(&"movement_speed", "Velocidade", 0.0, 1000.0, 0.0)
		_add_number_field(&"power", "Potencia", 0.0, 100000.0, 16.0)
		_add_number_field(&"attack_interval", "Intervalo de ataque", 0.05, 60.0, 0.8, 0.05)
		_add_number_field(&"range", "Alcance", 1.0, 5000.0, 300.0)
		_add_number_field(&"duration", "Duracao; zero e permanente", 0.0, 3600.0, 10.0, 0.1)
		_add_number_field(&"owner_limit", "Limite por proprietario", 1.0, 100.0, 2.0)
		_add_number_field(&"collision_radius", "Raio de colisao", 1.0, 200.0, 12.0)
	elif _mode == &"encounter":
		_add_line_field(&"enemy_definition_id", "ID do inimigo")
		_add_option_field(&"encounter_type", "Tipo de encontro", ["boss", "raid"])
		_add_number_field(&"enrage_seconds", "Tempo para enrage", 1.0, 3600.0, 180.0)
		_add_multiline_field(&"player_scaling", "Escalonamento em JSON")
		_add_multiline_field(&"break", "Ruptura em JSON")
		_add_multiline_field(&"objectives", "Objetivos em JSON")
		_add_multiline_field(&"phases", "Fases em JSON")
	await get_tree().process_frame
	_update_preview()


func _add_line_field(key: StringName, label_text: String) -> void:
	_add_field_label(label_text)
	var field := LineEdit.new()
	field.name = String(key).to_pascal_case()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_changed.connect(func(_value: String) -> void: _update_preview())
	_form.add_child(field)
	_fields[key] = field


func _add_option_field(key: StringName, label_text: String, options: Array[String]) -> void:
	_add_field_label(label_text)
	var field := OptionButton.new()
	field.name = String(key).to_pascal_case()
	for option in options:
		field.add_item(option)
	field.item_selected.connect(func(_index: int) -> void: _update_preview())
	_form.add_child(field)
	_fields[key] = field


func _add_number_field(key: StringName, label_text: String, minimum: float, maximum: float, initial: float, step := 1.0) -> void:
	_add_field_label(label_text)
	var field := SpinBox.new()
	field.name = String(key).to_pascal_case()
	field.min_value = minimum
	field.max_value = maximum
	field.step = step
	field.value = initial
	field.value_changed.connect(func(_value: float) -> void: _update_preview())
	_form.add_child(field)
	_fields[key] = field


func _add_multiline_field(key: StringName, label_text: String) -> void:
	_add_field_label(label_text)
	var field := TextEdit.new()
	field.name = String(key).to_pascal_case()
	field.custom_minimum_size = Vector2(0.0, 100.0)
	field.text_changed.connect(_update_preview)
	_form.add_child(field)
	_fields[key] = field


func _add_field_label(label_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(170.0, 0.0)
	_form.add_child(label)


func _current_collection() -> Array[Dictionary]:
	match _mode:
		&"enemy":
			return _enemies
		&"item":
			return _items
		&"modifier":
			return _enemy_modifiers
		&"active_gem":
			return _active_gems
		&"support_gem":
			return _support_gems
		&"summon":
			return _summons
		&"encounter":
			return _major_encounters
	return _enemies


func _refresh_list() -> void:
	_list.clear()
	var query := _search.text.strip_edges().to_lower()
	var collection := _current_collection()
	for index in range(collection.size()):
		var entry := collection[index]
		var category: Variant = entry.get("kind", entry.get("item_type", entry.get("position", "")))
		var searchable := "%s %s %s" % [entry.get("id", ""), entry.get("name", ""), category]
		if not query.is_empty() and query not in searchable.to_lower():
			continue
		var visible_index := _list.add_item("%s  |  %s" % [entry.get("id", "sem_id"), entry.get("name", "Sem nome")])
		_list.set_item_metadata(visible_index, index)


func _select_visible_entry(visible_index: int) -> void:
	_selected_index = int(_list.get_item_metadata(visible_index))
	var collection := _current_collection()
	if _selected_index < 0 or _selected_index >= collection.size():
		return
	_populate_form(collection[_selected_index])


func _new_entry() -> void:
	_selected_index = -1
	_clear_form()
	_status.text = "Nova entrada ainda nao aplicada."


func _duplicate_entry() -> void:
	var collection := _current_collection()
	if _selected_index < 0 or _selected_index >= collection.size():
		return
	var copy := collection[_selected_index].duplicate(true) as Dictionary
	copy["id"] = "%s_copy" % copy.get("id", "entry")
	copy["name"] = "%s (copia)" % copy.get("name", "Entrada")
	_selected_index = -1
	_populate_form(copy)
	_status.text = "Copia preparada; ajuste o ID e aplique."


func _delete_entry() -> void:
	var collection := _current_collection()
	if _selected_index < 0 or _selected_index >= collection.size():
		return
	collection.remove_at(_selected_index)
	_selected_index = -1
	_clear_form()
	_persist_library()
	_refresh_list()
	_status.text = "Entrada excluida."


func _save_entry() -> void:
	var entry := _collect_form()
	var entry_id := String(entry.get("id", "")).strip_edges()
	if not _valid_id(entry_id):
		_status.text = "ID invalido: use letras minusculas, numeros e sublinhado."
		return
	if String(entry.get("name", "")).strip_edges().is_empty():
		_status.text = "Nome e obrigatorio."
		return
	if _mode == &"active_gem":
		var evolutions := entry.get("evolutions", {}) as Dictionary
		for level in ["1", "2", "3"]:
			if not evolutions.has(level) or not evolutions[level] is Array or evolutions[level].size() < 2:
				_status.text = "Gema ativa exige duas evolucoes nos niveis 1, 2 e 3."
				return
		if entry.get("mechanic", "") == "summon" and String(entry.get("summon_definition_id", "")).is_empty():
			_status.text = "Gema de summon exige uma definicao de summon."
			return
	elif _mode == &"support_gem" and (entry.get("modifiers", {}) as Dictionary).is_empty():
		_status.text = "Gema de suporte exige ao menos um modificador."
		return
	elif _mode == &"summon" and (
		float(entry.get("health", 0.0)) <= 0.0
		or float(entry.get("attack_interval", 0.0)) <= 0.0
		or int(entry.get("owner_limit", 0)) <= 0
	):
		_status.text = "Summon exige Vida, intervalo e limite validos."
		return
	elif _mode == &"encounter":
		var encounter_definition: RefCounted = MajorEncounterDefinitionScript.from_dictionary(entry)
		if not bool(encounter_definition.call("is_valid_definition")):
			_status.text = "Encontro invalido: revise inimigo, fases, objetivos, ruptura e escalonamento."
			return
	var collection := _current_collection()
	for index in range(collection.size()):
		if index != _selected_index and String(collection[index].get("id", "")) == entry_id:
			_status.text = "Ja existe uma entrada com o ID %s." % entry_id
			return
	if _selected_index >= 0 and _selected_index < collection.size():
		collection[_selected_index] = entry
	else:
		collection.append(entry)
		_selected_index = collection.size() - 1
	_persist_library()
	_refresh_list()
	_status.text = "%s aplicado e salvo." % entry_id


func _collect_form() -> Dictionary:
	var entry := {"schema": String(_mode)}
	for key: StringName in _fields:
		var field := _fields[key] as Control
		if field is LineEdit:
			entry[String(key)] = field.text.strip_edges()
		elif field is OptionButton:
			entry[String(key)] = field.get_item_text(field.selected)
		elif field is SpinBox:
			entry[String(key)] = field.value
		elif field is TextEdit:
			entry[String(key)] = field.text.strip_edges()
	if _mode in [&"active_gem", &"support_gem"]:
		var list_key := "tags" if _mode == &"active_gem" else "requires"
		entry[list_key] = _comma_list(String(entry.get(list_key, "")))
		var json_key := "evolutions" if _mode == &"active_gem" else "modifiers"
		var json_text := String(entry.get(json_key, "{}")).strip_edges()
		var parsed: Variant = {} if json_text.is_empty() else JSON.parse_string(json_text)
		entry[json_key] = parsed if parsed is Dictionary else {}
	elif _mode == &"encounter":
		for json_key in ["player_scaling", "break"]:
			var dictionary_text := String(entry.get(json_key, "")).strip_edges()
			var parsed_dictionary: Variant = {} if dictionary_text.is_empty() else JSON.parse_string(dictionary_text)
			entry[json_key] = parsed_dictionary if parsed_dictionary is Dictionary else {}
		for json_key in ["objectives", "phases"]:
			var array_text := String(entry.get(json_key, "")).strip_edges()
			var parsed_array: Variant = [] if array_text.is_empty() else JSON.parse_string(array_text)
			entry[json_key] = parsed_array if parsed_array is Array else []
	return entry


func _populate_form(entry: Dictionary) -> void:
	for key: StringName in _fields:
		var field := _fields[key] as Control
		var value: Variant = entry.get(String(key), "")
		if field is LineEdit:
			field.text = ", ".join(value) if value is Array else String(value)
		elif field is OptionButton:
			_select_option(field, String(value))
		elif field is SpinBox:
			field.value = float(value)
		elif field is TextEdit:
			field.text = JSON.stringify(value, "  ") if value is Dictionary or value is Array else String(value)
	_update_preview()


func _clear_form() -> void:
	for field_value: Variant in _fields.values():
		var field := field_value as Control
		if field is LineEdit or field is TextEdit:
			field.text = ""
		elif field is OptionButton:
			field.select(0)
	_update_preview()


func _select_option(field: OptionButton, value: String) -> void:
	for index in range(field.item_count):
		if field.get_item_text(index) == value:
			field.select(index)
			return
	field.select(0)


func _valid_id(value: String) -> bool:
	if value.is_empty():
		return false
	var regex := RegEx.new()
	regex.compile("^[a-z0-9_]+$")
	return regex.search(value) != null


func _update_preview() -> void:
	if _preview == null or _fields.is_empty():
		return
	var entry := _collect_form()
	if _mode == &"enemy":
		_preview.text = "FORMA DE TESTE\n%s [%s]\nVida %.0f | Velocidade %.0f | Dano %.0f | Ataque %.2fs | Loot %.0f" % [
			entry.get("name", "Sem nome"), entry.get("kind", "melee"), entry.get("health", 0.0),
			entry.get("speed", 0.0), entry.get("damage", 0.0), entry.get("attack_interval", 0.0), entry.get("loot_value", 0.0)
		]
	elif _mode == &"item":
		_preview.text = "ITEM DE TESTE\n%s [%s / %s]\nSlot %s | Orcamento %.0f\n%s" % [
			entry.get("name", "Sem nome"), entry.get("item_type", "material"), entry.get("tier", "common"),
			entry.get("slot", "none"), entry.get("power", 0.0), entry.get("description", "")
		]
	elif _mode == &"modifier":
		_preview.text = "MODIFICADOR DE TESTE\n%s [%s]\nVida x%.2f | Velocidade x%.2f | Dano x%.2f | Intervalo x%.2f | Loot x%.2f\nMecanica: %s" % [
			entry.get("name", "Sem nome"), entry.get("position", "prefix"), entry.get("health_multiplier", 1.0),
			entry.get("speed_multiplier", 1.0), entry.get("damage_multiplier", 1.0),
			entry.get("attack_interval_multiplier", 1.0), entry.get("loot_multiplier", 1.0),
			entry.get("mechanic_id", "")
		]
	elif _mode == &"active_gem":
		_preview.text = "GEMA ATIVA\n%s [%s]\nRecarga %.2fs | Folego %.0f | Potencia %.0f | Raio %.0f | Alcance %.0f" % [
			entry.get("name", "Sem nome"), entry.get("mechanic", "projectile"), entry.get("cooldown", 0.0),
			entry.get("breath_cost", 0.0), entry.get("power", 0.0), entry.get("radius", 0.0), entry.get("range", 0.0)
		]
	elif _mode == &"support_gem":
		_preview.text = "GEMA DE SUPORTE\n%s\nCapacidade %.0f | Exige: %s" % [
			entry.get("name", "Sem nome"), entry.get("drain", 0.0), entry.get("requires", "")
		]
	elif _mode == &"summon":
		_preview.text = "SUMMON\n%s [%s / %s]\nVida %.0f | Potencia %.0f | Ataque %.2fs | Alcance %.0f | Duracao %.1fs | Limite %.0f" % [
			entry.get("name", "Sem nome"), entry.get("behavior", "stationary"), entry.get("targeting", "nearest_hostile"),
			entry.get("health", 0.0), entry.get("power", 0.0), entry.get("attack_interval", 0.0),
			entry.get("range", 0.0), entry.get("duration", 0.0), entry.get("owner_limit", 0.0)
		]
	else:
		_preview.text = "ENCONTRO MAIOR\n%s [%s]\nInimigo: %s | Fases: %d | Objetivos: %d | Enrage: %.0fs" % [
			entry.get("name", "Sem nome"), entry.get("encounter_type", "boss"), entry.get("enemy_definition_id", ""),
			(entry.get("phases", []) as Array).size(), (entry.get("objectives", []) as Array).size(), entry.get("enrage_seconds", 0.0)
		]


func _load_library() -> void:
	if not FileAccess.file_exists(storage_path):
		_load_beta_defaults()
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var data := parsed as Dictionary
	_enemies = _dictionary_array(data.get("enemies", []))
	_items = _dictionary_array(data.get("items", []))
	_enemy_modifiers = _dictionary_array(data.get("enemy_modifiers", []))
	_active_gems = _dictionary_array(data.get("active_gems", []))
	_support_gems = _dictionary_array(data.get("support_gems", []))
	_summons = _dictionary_array(data.get("summons", []))
	_major_encounters = _dictionary_array(data.get("major_encounters", []))
	if _enemies.is_empty() and _items.is_empty() and _enemy_modifiers.is_empty() and _active_gems.is_empty() and _support_gems.is_empty() and _summons.is_empty() and _major_encounters.is_empty():
		_load_beta_defaults()


func _persist_library() -> void:
	if _write_library(storage_path):
		_status.text = "Biblioteca salva em %s" % storage_path
	else:
		_status.text = "Falha ao salvar a biblioteca."


func _export_library() -> void:
	var absolute_directory := ProjectSettings.globalize_path(export_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(absolute_directory)
	if _write_library(export_path):
		_status.text = "Conteudo exportado para %s" % export_path
	else:
		_status.text = "Falha ao exportar o conteudo."


func _write_library(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"version": 2,
		"enemies": _enemies,
		"items": _items,
		"enemy_modifiers": _enemy_modifiers,
		"active_gems": _active_gems,
		"support_gems": _support_gems,
		"summons": _summons,
		"major_encounters": _major_encounters,
	}, "\t"))
	file.close()
	return true


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value:
			if item is Dictionary:
				result.append((item as Dictionary).duplicate(true))
	return result


func _comma_list(value: String) -> Array[String]:
	var result: Array[String] = []
	for part in value.split(","):
		var cleaned := part.strip_edges()
		if not cleaned.is_empty() and cleaned not in result:
			result.append(cleaned)
	return result


func _load_beta_defaults() -> void:
	var path := "res://data/beta/beta_content.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var beta := parsed as Dictionary
	_enemies = _dictionary_array(beta.get("enemies", []))
	_items = _dictionary_array(beta.get("items", []))
	_enemy_modifiers = _dictionary_array(beta.get("enemy_modifiers", []))
	_active_gems = _dictionary_array(beta.get("active_gems", []))
	_support_gems = _dictionary_array(beta.get("support_gems", []))
	_summons = _dictionary_array(beta.get("summons", []))
	_major_encounters = _dictionary_array(beta.get("major_encounters", []))
