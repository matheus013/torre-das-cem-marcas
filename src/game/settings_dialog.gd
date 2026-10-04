extends ConfirmationDialog

signal leave_requested
signal session_action_requested(action: String)

const SettingsScript := preload("res://src/core/app/game_settings.gd")
const BindingsScript := preload("res://src/core/app/input_bindings.gd")

var _fullscreen: CheckButton
var _resolution: OptionButton
var _fps: OptionButton
var _vsync: CheckButton
var _volumes: Dictionary = {}
var _error: Label
var _paused_by_us := false
var _previous_focus: WeakRef
var _settings_path := SettingsScript.PATH
var _bindings: Dictionary = {}
var _binding_buttons: Dictionary = {}
var _capturing := ""
var _auto_aim: CheckButton
var _session_buttons: Array[Button] = []


func _ready() -> void:
	name = "SettingsDialog"
	title = "Opções"
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_hide_on_ok = false
	min_size = Vector2i(560, 520)
	size = min_size
	get_ok_button().text = "Aplicar"
	get_cancel_button().text = "Cancelar"
	add_button("Restaurar padrões", false, "defaults")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	var root_column := VBoxContainer.new()
	add_child(root_column)
	var tabs := TabContainer.new()
	tabs.name = "Tabs"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_column.add_child(tabs)
	column.name = "Vídeo e áudio"
	tabs.add_child(column)
	_fullscreen = CheckButton.new()
	_fullscreen.name = "Fullscreen"
	_add_row(column, "Tela cheia", _fullscreen)
	_resolution = OptionButton.new()
	_resolution.name = "Resolution"
	for resolution in SettingsScript.RESOLUTIONS:
		_resolution.add_item("%d x %d" % [resolution.x, resolution.y])
	_add_row(column, "Resolução da janela", _resolution)
	_fps = OptionButton.new()
	_fps.name = "FpsLimit"
	for limit in SettingsScript.FPS_LIMITS:
		_fps.add_item("Sem limite" if limit == 0 else str(limit), limit)
	_add_row(column, "Limite de FPS", _fps)
	_vsync = CheckButton.new()
	_vsync.name = "Vsync"
	_add_row(column, "VSync", _vsync)
	for spec: Array in [["master", "Volume geral"], ["music", "Música"], ["effects", "Efeitos"]]:
		var slider := HSlider.new()
		slider.name = String(spec[0]).capitalize() + "Volume"
		slider.max_value = 100.0
		slider.step = 1.0
		slider.custom_minimum_size.x = 160.0
		_volumes[spec[0]] = slider
		slider.value_changed.connect(func(value: float) -> void: slider.tooltip_text = "%d%%" % int(value))
		_add_row(column, String(spec[1]), slider)
	_error = Label.new()
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error.add_theme_color_override("font_color", Color("e88383"))
	root_column.add_child(_error)
	var scroll := ScrollContainer.new()
	scroll.name = "Controles"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var controls := VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(controls)
	_auto_aim = CheckButton.new()
	_auto_aim.name = "AutoAim"
	_add_row(controls, "Mira automática", _auto_aim)
	for action: String in BindingsScript.SPECS:
		var button := Button.new()
		button.name = action
		button.tooltip_text = "Alterar tecla"
		button.pressed.connect(_begin_capture.bind(action))
		_binding_buttons[action] = button
		_add_row(controls, String(BindingsScript.SPECS[action][0]), button)
	confirmed.connect(_apply)
	custom_action.connect(_custom_action)
	visibility_changed.connect(_on_visibility_changed)
	_fullscreen.toggled.connect(func(full: bool) -> void: _resolution.disabled = full)
	tabs.tab_changed.connect(func(_tab: int) -> void:
		_capturing = ""
		_update_bindings()
	)


func _add_row(column: VBoxContainer, text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	control.custom_minimum_size.x = 180.0
	row.add_child(control)
	column.add_child(row)


func open(pause_solo: bool = false) -> void:
	if visible:
		return
	var focus := get_parent().get_viewport().gui_get_focus_owner()
	_previous_focus = weakref(focus) if focus != null else null
	_fill(SettingsScript.read(_settings_path))
	_bindings = BindingsScript.read(_settings_path)
	_capturing = ""
	_update_bindings()
	_error.text = ""
	var stored := SettingsScript.ConfigStore.read(_settings_path)
	if stored["recovered"]:
		_error.text = "Opcoes e controles recuperados do backup. A ultima alteracao pode faltar."
	elif stored["error"] not in [OK, ERR_FILE_NOT_FOUND]:
		_error.text = "Configuracao indisponivel. Padroes em uso; arquivo anterior preservado."
	_paused_by_us = pause_solo and not get_tree().paused
	if _paused_by_us:
		get_tree().paused = true
	popup_centered()
	get_ok_button().grab_focus()


func enable_session_exit() -> void:
	get_cancel_button().text = "Continuar"
	add_button("Voltar ao menu", true, "leave")
	var session := VBoxContainer.new()
	session.name = "Sessão"
	(find_child("Tabs", true, false) as TabContainer).add_child(session)
	for spec: Array in [["save", "Salvar mundo"], ["load", "Carregar mundo"], ["npc_mode", "Alternar moradores"]]:
		var button := Button.new()
		button.text = String(spec[1])
		button.pressed.connect(func() -> void:
			hide()
			session_action_requested.emit(String(spec[0]))
		)
		session.add_child(button)
		_session_buttons.append(button)


func set_authority(authority: bool) -> void:
	for button in _session_buttons:
		button.disabled = not authority


func _fill(values: Dictionary) -> void:
	_fullscreen.set_pressed_no_signal(bool(values["fullscreen"]))
	_resolution.select(int(values["resolution"]))
	_resolution.disabled = bool(values["fullscreen"])
	_fps.select(SettingsScript.FPS_LIMITS.find(int(values["fps"])))
	_vsync.set_pressed_no_signal(bool(values["vsync"]))
	_auto_aim.set_pressed_no_signal(bool(values["auto_aim"]))
	for key: String in _volumes:
		(_volumes[key] as HSlider).value = float(values[key])


func _apply() -> void:
	var values := {"fullscreen": _fullscreen.button_pressed, "resolution": _resolution.selected, "fps": _fps.get_selected_id(), "vsync": _vsync.button_pressed}
	values["auto_aim"] = _auto_aim.button_pressed
	for key: String in _volumes:
		values[key] = (_volumes[key] as HSlider).value
	if not _capturing.is_empty():
		return
	var error := SettingsScript.save(values, _settings_path, _bindings)
	if error != OK:
		_error.text = "Não foi possível salvar as opções: " + error_string(error)
		return
	SettingsScript.apply(values)
	BindingsScript.apply(_bindings)
	hide()


func _custom_action(action: StringName) -> void:
	if action == &"defaults":
		_fill(SettingsScript.DEFAULTS)
		_bindings = BindingsScript.defaults()
		_capturing = ""
		_update_bindings()
	elif action == &"leave":
		hide()
		leave_requested.emit()


func _on_visibility_changed() -> void:
	if not visible:
		_capturing = ""
		_release_pause()
		if _previous_focus != null:
			var focus := _previous_focus.get_ref() as Control
			if focus != null and focus.is_visible_in_tree():
				focus.grab_focus()


func _release_pause() -> void:
	if _paused_by_us:
		get_tree().paused = false
		_paused_by_us = false


func _exit_tree() -> void:
	_release_pause()


func _begin_capture(action: String) -> void:
	_capturing = action
	_error.text = ""
	_update_bindings()


func _update_bindings() -> void:
	for action: String in _binding_buttons:
		(_binding_buttons[action] as Button).text = "..." if _capturing == action else BindingsScript.key_label(int(_bindings[action]))


func _input(event: InputEvent) -> void:
	BindingsScript.track(event)
	if _capturing.is_empty() and event.is_action_pressed("aresta_auto_aim"):
		var error := SettingsScript.toggle_auto_aim(_settings_path)
		_auto_aim.set_pressed_no_signal(SettingsScript.auto_aim)
		_error.text = "Não foi possível guardar a preferência de mira." if error != OK else ""
		set_input_as_handled()
		return
	if _capturing.is_empty() and event.is_action_pressed("aresta_pause"):
		hide()
		set_input_as_handled()
		return
	if _capturing.is_empty() or not event is InputEventKey or not event.pressed:
		return
	set_input_as_handled()
	if event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_capturing = ""
		_error.text = ""
		_update_bindings()
		return
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed or not BindingsScript.allowed(event.keycode):
		_error.text = "Tecla reservada ou combinação indisponível."
		return
	var conflict := BindingsScript.conflict(_bindings, _capturing, event.keycode)
	if not conflict.is_empty():
		_error.text = "Tecla já usada por " + String(BindingsScript.SPECS[conflict][0]) + "."
		return
	_bindings[_capturing] = int(event.keycode)
	_capturing = ""
	_error.text = ""
	_update_bindings()
