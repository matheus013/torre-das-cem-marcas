extends Control

## Tela inicial pública: sem laboratório, editores ou provas técnicas.

const SpriteLibraryScript := preload("res://src/presentation/art/sprite_library.gd")
const DevModeScript := preload("res://src/core/app/dev_mode.gd")
const SettingsDialogScript := preload("res://src/game/settings_dialog.gd")
const VILLAGE_SCENE := "res://src/prototype/village/village_exploration.tscn"
const GOLD := Color("e8b84a")
const TEXT := Color("f2e6c9")

var _time := 0.0
var _embers: Array[Vector3] = []
var _join_row: HBoxContainer
var _address_input: LineEdit
var _settings_dialog: ConfirmationDialog
var _new_game_dialog: ConfirmationDialog
var _game_version := "Beta jogável " + preload("res://src/core/app/app_version.gd").current()


func _ready() -> void:
	SettingsDialogScript.BindingsScript.ensure()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var random := RandomNumberGenerator.new()
	random.seed = 100
	for _index in range(40):
		_embers.append(Vector3(random.randf(), random.randf(), random.randf_range(0.3, 1.0)))
	var menu := VBoxContainer.new()
	menu.name = "Menu"
	menu.add_theme_constant_override("separation", 8)
	menu.position = Vector2(110.0, 304.0)
	menu.custom_minimum_size = Vector2(260.0, 0.0)
	add_child(menu)
	# Com save, CONTINUAR vem primeiro e JOGAR vira NOVO JOGO com confirmação (decisão 582).
	var has_save := SaveSlot.exists()
	var specs: Array = [["Continue", "CONTINUAR", _continue]] if has_save else []
	specs.append_array([["Play", "NOVO JOGO" if has_save else "JOGAR", _play], ["CoopHost", "HOSPEDAR CO-OP", _host], ["CoopJoin", "ENTRAR EM CO-OP", _toggle_join], ["Villagers", "MORADORES (IA)", _toggle_npc_panel], ["Settings", "OPÇÕES", _open_settings], ["Quit", "SAIR", _quit]])
	for spec: Array in specs:
		var button := _make_button(String(spec[0]), String(spec[1]), Vector2(260.0, 48.0), 20)
		button.pressed.connect(spec[2])
		menu.add_child(button)
		if spec[0] == "Continue":
			var details := Label.new()
			details.name = "SaveSummary"
			details.text = save_summary_text(SaveSlot.summary())
			details.add_theme_color_override("font_color", Color("8f7a6a"))
			details.add_theme_font_size_override("font_size", 13)
			menu.add_child(details)
		if spec[0] == "CoopJoin":
			_join_row = HBoxContainer.new()
			_join_row.name = "JoinRow"
			_join_row.visible = false
			_join_row.add_theme_constant_override("separation", 8)
			menu.add_child(_join_row)
			_address_input = LineEdit.new()
			_address_input.name = "Address"
			_address_input.text = "127.0.0.1"
			_address_input.placeholder_text = "IP do host"
			_address_input.custom_minimum_size = Vector2(160.0, 40.0)
			_address_input.text_submitted.connect(func(_text: String) -> void: _join())
			_join_row.add_child(_address_input)
			var connect_button := _make_button("Connect", "CONECTAR", Vector2(92.0, 40.0), 15)
			connect_button.pressed.connect(_join)
			_join_row.add_child(connect_button)
	(menu.get_child(0) as Button).grab_focus()
	_settings_dialog = SettingsDialogScript.new()
	add_child(_settings_dialog)
	_new_game_dialog = ConfirmationDialog.new()
	_new_game_dialog.name = "NewGameDialog"
	_new_game_dialog.title = "Novo jogo"
	_new_game_dialog.dialog_text = "Comecar um novo jogo?\nO progresso salvo sera substituido no proximo salvamento automatico."
	_new_game_dialog.ok_button_text = "Comecar do zero"
	_new_game_dialog.cancel_button_text = "Voltar"
	_new_game_dialog.confirmed.connect(_start_new_game)
	add_child(_new_game_dialog)


func _open_settings() -> void:
	_settings_dialog.call("open")


func _make_button(button_name: String, text: String, minimum: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_stylebox_override("normal", _button_style(Color("2f2a35e6"), Color("8f7a6a")))
	button.add_theme_stylebox_override("hover", _button_style(Color("4a3f4fee"), GOLD))
	button.add_theme_stylebox_override("pressed", _button_style(Color("1b1a1fee"), GOLD))
	button.add_theme_stylebox_override("focus", _button_style(Color("4a3f4fee"), GOLD))
	return button


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12 and DevModeScript.can_toggle():
		DevModeScript.set_enabled(true)
		get_tree().change_scene_to_file(DevModeScript.DEV_HOME)


func _input(event: InputEvent) -> void:
	SettingsDialogScript.BindingsScript.track(event)


func _draw() -> void:
	var screen := size
	draw_rect(Rect2(Vector2.ZERO, screen), Color("1b1a1f"))
	var ground_y := screen.y * 0.66
	for band in range(12):
		var ratio := float(band) / 12.0
		draw_rect(Rect2(0.0, ground_y * ratio, screen.x, ground_y / 12.0 + 1.0), Color("2f2a35").lerp(Color("4a3f4f"), ratio))
	var grass := SpriteLibraryScript.texture("tiles/grass")
	if grass != null:
		draw_texture_rect(grass, Rect2(0.0, ground_y, screen.x, screen.y - ground_y), true, Color(0.55, 0.55, 0.6))
	else:
		draw_rect(Rect2(0.0, ground_y, screen.x, screen.y - ground_y), Color("2b3b2a"))
	_draw_scaled("buildings/torre", Vector2(screen.x * 0.72, ground_y + 24.0), 3.0, Color(0.85, 0.82, 0.9))
	_draw_scaled("props/pines", Vector2(screen.x * 0.52, ground_y + 30.0), 2.0, Color(0.6, 0.62, 0.7))
	_draw_scaled("props/tree", Vector2(screen.x * 0.95, ground_y + 40.0), 2.0, Color(0.6, 0.62, 0.7))
	var glow := 0.5 + 0.5 * sin(_time * 2.0)
	draw_circle(Vector2(screen.x * 0.72, ground_y - 60.0), 70.0 + glow * 6.0, Color(0.91, 0.72, 0.29, 0.07))
	var lineup: Array[String] = ["eloa", "sena", "cira", "rui"]
	for index in range(lineup.size()):
		var x := screen.x * 0.5 + float(index) * 74.0
		var bob := sin(_time * 2.2 + float(index)) * 1.5
		draw_circle(Vector2(x, ground_y + 64.0), 22.0, Color(0.0, 0.0, 0.0, 0.25))
		_draw_scaled("characters/" + lineup[index], Vector2(x, ground_y + 66.0 + bob), 2.0, Color.WHITE)
	for ember in _embers:
		var y := fposmod(ember.y - _time * 0.03 * ember.z, 1.0) * screen.y
		var x := ember.x * screen.x + sin(_time + ember.y * 20.0) * 12.0
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(2.0, 2.0)), Color(0.91, 0.62, 0.29, 0.35 * ember.z))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(114.0, 214.0), "ARESTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 92, Color("1b1a1f"))
	draw_string(font, Vector2(110.0, 210.0), "ARESTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 92, GOLD)
	draw_string(font, Vector2(114.0, 256.0), "A TORRE DAS CEM MARCAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, TEXT)
	draw_line(Vector2(114.0, 272.0), Vector2(420.0, 272.0), Color(GOLD, 0.6), 2.0)
	draw_string(font, Vector2(20.0, screen.y - 18.0), _game_version, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("8f7a6a"))


func _draw_scaled(key: String, base: Vector2, scale: float, tint: Color) -> void:
	var texture := SpriteLibraryScript.texture(key)
	if texture == null:
		return
	var size_scaled := texture.get_size() * scale
	draw_texture_rect(texture, Rect2((base - Vector2(size_scaled.x * 0.5, size_scaled.y)).round(), size_scaled), false, tint)


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	return style


func _toggle_npc_panel() -> void:
	var panel := get_node_or_null("NpcAiPanel") as Control
	if panel == null:
		panel = (load("res://src/game/npc_ai_panel.gd") as GDScript).new() as Control
		panel.position = Vector2(420.0, 160.0)
		add_child(panel)
		return
	panel.visible = not panel.visible


## Linha embaixo do CONTINUAR: personagem, nível, andar mais fundo e data do salvamento.
static func save_summary_text(summary: Dictionary) -> String:
	if summary.is_empty():
		return "Salvamento encontrado"
	var when := Time.get_datetime_dict_from_unix_time(int(summary["saved_at"]) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%s  |  nivel %d  |  andar %d  |  %02d/%02d %02d:%02d" % [String(summary["character_id"]).capitalize(), int(summary["level"]),
		int(summary["deepest_floor"]), int(when["day"]), int(when["month"]), int(when["hour"]), int(when["minute"])]


func _continue() -> void:
	SessionLaunch.request(&"solo", "127.0.0.1", SessionLaunch.DEFAULT_PORT, true)
	get_tree().change_scene_to_file(VILLAGE_SCENE)


## Sem save começa direto; com save pede confirmação, porque o salvamento automático
## gravaria o mundo novo por cima do progresso.
func _play() -> void:
	if SaveSlot.exists():
		_new_game_dialog.popup_centered()
		return
	_start_new_game()


func _start_new_game() -> void:
	SessionLaunch.request(&"solo")
	get_tree().change_scene_to_file(VILLAGE_SCENE)


## Hospedar continua o mundo salvo quando houver um.
func _host() -> void:
	SessionLaunch.request(&"host", "127.0.0.1", SessionLaunch.DEFAULT_PORT, SaveSlot.exists())
	get_tree().change_scene_to_file(VILLAGE_SCENE)


func _toggle_join() -> void:
	_join_row.visible = not _join_row.visible
	if _join_row.visible:
		_address_input.grab_focus()


func _join() -> void:
	var address := _address_input.text.strip_edges()
	if address.is_empty():
		return
	SessionLaunch.request(&"client", address)
	get_tree().change_scene_to_file(VILLAGE_SCENE)


func _quit() -> void:
	get_tree().quit()
