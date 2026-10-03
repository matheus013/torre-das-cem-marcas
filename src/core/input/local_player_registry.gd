class_name LocalPlayerRegistry
extends Node

signal player_joined(slot: int, source: InputSource)
signal player_left(slot: int)
signal roster_changed

const MAX_PLAYERS := 4


class InputSource:
	var kind: StringName
	var device_id: int
	var profile: int

	func _init(new_kind: StringName, new_device_id: int, new_profile: int = -1) -> void:
		kind = new_kind
		device_id = new_device_id
		profile = new_profile


var _slots: Array[InputSource] = []


func _ready() -> void:
	_slots.resize(MAX_PLAYERS)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var profile := _keyboard_profile_for_key(event.keycode)
		if profile >= 0:
			_toggle_keyboard(profile)
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton:
		if event.pressed and event.button_index == JOY_BUTTON_START:
			_join_joypad(event.device)
			get_viewport().set_input_as_handled()


func player_count() -> int:
	var count := 0
	for source in _slots:
		if source != null:
			count += 1
	return count


func _keyboard_profile_for_key(keycode: Key) -> int:
	match keycode:
		KEY_F1:
			return 0
		KEY_F2:
			return 1
		KEY_F3:
			return 2
		KEY_F4:
			return 3
		_:
			return -1


func _toggle_keyboard(profile: int) -> void:
	var existing_slot := _find_source(&"keyboard", profile)
	if existing_slot >= 0:
		_leave(existing_slot)
		return

	var slot := _first_open_slot()
	if slot < 0:
		return
	_join(slot, InputSource.new(&"keyboard", -1, profile))


func _join_joypad(device_id: int) -> void:
	if _find_source(&"joypad", device_id) >= 0:
		return
	var slot := _first_open_slot()
	if slot < 0:
		return
	_join(slot, InputSource.new(&"joypad", device_id))


func _join(slot: int, source: InputSource) -> void:
	_slots[slot] = source
	player_joined.emit(slot, source)
	roster_changed.emit()


func _leave(slot: int) -> void:
	_slots[slot] = null
	player_left.emit(slot)
	roster_changed.emit()


func _first_open_slot() -> int:
	for slot in range(MAX_PLAYERS):
		if _slots[slot] == null:
			return slot
	return -1


func _find_source(kind: StringName, identity: int) -> int:
	for slot in range(MAX_PLAYERS):
		var source := _slots[slot]
		if source == null or source.kind != kind:
			continue
		if kind == &"keyboard" and source.profile == identity:
			return slot
		if kind == &"joypad" and source.device_id == identity:
			return slot
	return -1


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		return
	var slot := _find_source(&"joypad", device_id)
	if slot >= 0:
		_leave(slot)
