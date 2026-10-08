extends RefCounted

const ConfigStore := preload("res://src/core/persistence/config_store.gd")

const PATH := "user://aresta_settings.cfg"
const PAD_BUTTONS := {"skill_1": JOY_BUTTON_LEFT_SHOULDER, "skill_2": JOY_BUTTON_RIGHT_SHOULDER, "skill_3": JOY_BUTTON_X, "skill_4": JOY_BUTTON_Y, "interact": JOY_BUTTON_A, "inventory": JOY_BUTTON_BACK, "character": JOY_BUTTON_DPAD_UP, "skills": JOY_BUTTON_DPAD_LEFT, "tower": JOY_BUTTON_DPAD_DOWN, "switch_character": JOY_BUTTON_DPAD_RIGHT, "auto_aim": JOY_BUTTON_LEFT_STICK, "attack": JOY_BUTTON_B}
static var pad_device := -1
const SPECS := {
	"move_left": ["Mover à esquerda", KEY_LEFT, "all"],
	"move_right": ["Mover à direita", KEY_RIGHT, "all"],
	"move_up": ["Mover para cima", KEY_UP, "all"],
	"move_down": ["Mover para baixo", KEY_DOWN, "all"],
	"attack": ["Ataque normal (ou clique esquerdo)", KEY_SPACE, "tower"],
	"skill_1": ["Gema 1", KEY_Q, "tower"],
	"skill_2": ["Gema 2", KEY_W, "tower"],
	"skill_3": ["Gema 3", KEY_E, "tower"],
	"skill_4": ["Gema 4", KEY_R, "tower"],
	"interact": ["Conversar / Investigar", KEY_F, "all"],
	"inventory": ["Inventário", KEY_I, "all"],
	"character": ["Personagem", KEY_C, "all"],
	"skills": ["Gemas", KEY_G, "all"],
	"tower": ["Mapa da Torre", KEY_T, "all"],
	"switch_character": ["Trocar personagem", KEY_V, "village"],
	"quick_item": ["Item rápido", KEY_1, "tower"],
	"save": ["Salvar", KEY_F5, "all"],
	"load": ["Carregar", KEY_F9, "all"],
	"npc_mode": ["Modo dos moradores", KEY_F6, "all"],
	"auto_aim": ["Alternar mira automática", KEY_H, "all"],
	"auto_attack": ["Alternar ataque automático", KEY_J, "all"],
}


static func defaults() -> Dictionary:
	var values := {}
	for action: String in SPECS:
		values[action] = int(SPECS[action][1])
	return values


static func allowed(key: int) -> bool:
	return (key >= KEY_A and key <= KEY_Z) or (key >= KEY_0 and key <= KEY_9) or (key >= KEY_F1 and key <= KEY_F11 and key != KEY_F7) or key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE, KEY_TAB, KEY_BACKSPACE, KEY_INSERT, KEY_DELETE, KEY_HOME, KEY_END, KEY_PAGEUP, KEY_PAGEDOWN]


## Nenhuma tecla pode servir a duas ações, mesmo em contextos diferentes (regressão de 2026-10-07:
## Gema 3 e Conversar dividiam o E; quando a missão passou a investigar na Torre, o E disparava a gema).
static func conflict(values: Dictionary, action: String, key: int) -> String:
	for other: String in SPECS:
		if other != action and int(values.get(other, SPECS[other][1])) == key:
			return other
	return ""


## Atalhos salvos com tecla repetida ou inválida: cada ação em conflito volta ao padrão, sem apagar
## o resto da configuração da pessoa (ex.: saves com Conversar no E ganham o F).
static func repair(values: Dictionary) -> Dictionary:
	var fixed := values.duplicate()
	for action: String in SPECS:
		var key: Variant = fixed.get(action)
		if not key is int or not allowed(key) or not conflict(fixed, action, int(key)).is_empty():
			fixed[action] = int(SPECS[action][1])
	return fixed


static func valid(values: Dictionary) -> bool:
	for action: String in SPECS:
		var key: Variant = values.get(action)
		if not key is int or not allowed(key):
			return false
	for action: String in SPECS:
		if not conflict(values, action, int(values[action])).is_empty():
			return false
	return true


static func read(path: String = PATH) -> Dictionary:
	var values := defaults()
	var result := ConfigStore.read(path)
	var config: ConfigFile = result["config"]
	if result["error"] == OK:
		for action: String in SPECS:
			values[action] = config.get_value("controls", action, values[action])
	if not valid(values):
		values = repair(values)
	return values if valid(values) else defaults()


static func apply(values: Dictionary) -> void:
	var clean := values if valid(values) else defaults()
	for action: String in SPECS:
		var name := "aresta_" + action
		if not InputMap.has_action(name):
			InputMap.add_action(name)
		InputMap.action_erase_events(name)
		var event := InputEventKey.new()
		event.keycode = int(clean[action]) as Key
		InputMap.action_add_event(name, event)
		if PAD_BUTTONS.has(action):
			var button := InputEventJoypadButton.new()
			button.device = -1
			button.button_index = PAD_BUTTONS[action] as JoyButton
			InputMap.action_add_event(name, button)
		elif action.begins_with("move_"):
			var horizontal := action in ["move_left", "move_right"]
			_add_axis(name, JOY_AXIS_LEFT_X if horizontal else JOY_AXIS_LEFT_Y, -1.0 if action in ["move_left", "move_up"] else 1.0)
	_add_axis("aresta_quick_item", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	for action: String in ["aim_left", "aim_right", "aim_up", "aim_down"]:
		var name := "aresta_" + action
		if not InputMap.has_action(name):
			InputMap.add_action(name)
		InputMap.action_erase_events(name)
		_add_axis(name, JOY_AXIS_RIGHT_X if action in ["aim_left", "aim_right"] else JOY_AXIS_RIGHT_Y, -1.0 if action in ["aim_left", "aim_up"] else 1.0)
	if not InputMap.has_action("aresta_pause"):
		InputMap.add_action("aresta_pause")
	InputMap.action_erase_events("aresta_pause")
	var pause_key := InputEventKey.new()
	pause_key.keycode = KEY_ESCAPE
	InputMap.action_add_event("aresta_pause", pause_key)
	var pause_button := InputEventJoypadButton.new()
	pause_button.device = -1
	pause_button.button_index = JOY_BUTTON_START
	InputMap.action_add_event("aresta_pause", pause_button)
	var buttons := {"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B, "ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT, "ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN}
	for action: String in buttons:
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = buttons[action] as JoyButton
		if not InputMap.action_has_event(action, button):
			InputMap.action_add_event(action, button)
	for action: String in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		var motion := InputEventJoypadMotion.new()
		motion.device = -1
		motion.axis = JOY_AXIS_LEFT_X if action in ["ui_left", "ui_right"] else JOY_AXIS_LEFT_Y
		motion.axis_value = -1.0 if action in ["ui_left", "ui_up"] else 1.0
		if not InputMap.action_has_event(action, motion):
			InputMap.action_add_event(action, motion)


static func _add_axis(action: String, axis: JoyAxis, direction: float) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.device = -1
	motion.axis = axis
	motion.axis_value = direction
	InputMap.action_add_event(action, motion)
	InputMap.action_set_deadzone(action, 0.25 if axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y] else 0.5)


static func track(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25):
		pad_device = event.device
	elif event is InputEventKey or event is InputEventMouseButton:
		pad_device = -1


static func ensure() -> void:
	if not InputMap.has_action("aresta_inventory"):
		apply(read())


static func pressed(event: InputEvent, action: String) -> bool:
	return event.is_action_pressed("aresta_" + action)


static func label(action: String) -> String:
	ensure()
	if pad_device >= 0:
		if action == "auto_aim":
			return "L3"
		if action == "attack":
			return "○" if playstation() else "B"
		if action == "quick_item":
			return "R2" if playstation() else "RT"
		if PAD_BUTTONS.has(action):
			return pad_label(action, playstation())
	var events := InputMap.action_get_events("aresta_" + action)
	return key_label((events[0] as InputEventKey).keycode) if not events.is_empty() else ""


static func key_label(key: int) -> String:
	return {KEY_LEFT: "←", KEY_RIGHT: "→", KEY_UP: "↑", KEY_DOWN: "↓", KEY_SPACE: "Espaço", KEY_PAGEUP: "PgUp", KEY_PAGEDOWN: "PgDn", KEY_DELETE: "Del", KEY_INSERT: "Ins"}.get(key, OS.get_keycode_string(key as Key)) as String


static func playstation() -> bool:
	var name := Input.get_joy_name(pad_device).to_lower()
	for term in ["sony", "playstation", "dualshock", "dualsense", "ps4", "ps5"]:
		if name.contains(term):
			return true
	return false


static func pad_label(action: String, sony: bool) -> String:
	var xbox := {"skill_1": "LB", "skill_2": "RB", "skill_3": "X", "skill_4": "Y", "interact": "A", "inventory": "View", "character": "↑", "skills": "←", "tower": "↓", "switch_character": "→"}
	var ps := {"skill_1": "L1", "skill_2": "R1", "skill_3": "□", "skill_4": "△", "interact": "×", "inventory": "Share", "character": "↑", "skills": "←", "tower": "↓", "switch_character": "→"}
	return String((ps if sony else xbox).get(action, ""))
