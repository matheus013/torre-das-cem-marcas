extends SceneTree

const UiSkin := preload("res://src/presentation/ui/game_ui_skin.gd")
const Menu := preload("res://src/prototype/village/player_menu.gd")
const Cell := preload("res://src/prototype/village/item_cell.gd")

var _activated := false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for id: String in UiSkin.ICON_CELLS.keys() + ["info"]:
		var texture := UiSkin.icon(id)
		if texture == null or texture.get_image().is_invisible():
			return _fail("Missing icon: " + id)
	for style: StyleBoxTexture in [UiSkin.frame(), UiSkin.frame(true), UiSkin.slot(), UiSkin.slot(true), UiSkin.button_style(), UiSkin.button_style(true)]:
		if style.texture == null or style.texture.get_image().is_invisible():
			return _fail("Missing frame region")
	var theme := UiSkin.theme()
	if theme != UiSkin.theme() or theme.get_stylebox("focus", "Button").border_color != UiSkin.CYAN:
		return _fail("Shared theme or visible focus is missing")
	var button := Button.new()
	UiSkin.icon_button(button, "settings", "Configuracoes")
	if button.icon == null or not button.text.is_empty() or button.tooltip_text.is_empty():
		return _fail("Icon command lost its accessible description")
	button.free()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var menu := Menu.new()
	root.add_child(menu)
	menu.show()
	for dimensions: Vector2i in [Vector2i(640, 720), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dimensions
		await process_frame
		await process_frame
		menu._layout_shell()
		var frame: Control = menu._frame
		if frame.position.x < 0 or frame.position.y < 0 or frame.position.x + frame.size.x > dimensions.x or frame.position.y + frame.size.y > dimensions.y:
			return _fail("Menu frame exceeds viewport: " + str(dimensions))
		if menu._tabs.columns != (3 if dimensions.x < 800 else 5):
			return _fail("Tab grid did not reflow")
	var cell := Cell.new()
	root.add_child(cell)
	cell.pressed.connect(func() -> void: _activated = true)
	var event := InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = true
	cell._gui_input(event)
	if not _activated or cell.focus_mode != Control.FOCUS_ALL:
		return _fail("Inventory cell does not support focused activation")
	menu.queue_free()
	cell.queue_free()
	await process_frame
	print("UI_SKIN_OK: atlas coverage, shared theme, icon descriptions, responsive frame and item activation")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
