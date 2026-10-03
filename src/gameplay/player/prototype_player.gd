class_name PrototypePlayer
extends CharacterBody2D

const SPEED := 220.0
const RADIUS := 22.0
const ARENA_RECT := Rect2(-610.0, -330.0, 1220.0, 660.0)
const COLORS: Array[Color] = [
	Color("f1c75b"),
	Color("e36e69"),
	Color("69c59a"),
	Color("8f83dc"),
]

const KEYBOARD_PROFILES: Array[Dictionary] = [
	{"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D},
	{"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT},
	{"up": KEY_I, "down": KEY_K, "left": KEY_J, "right": KEY_L},
	{"up": KEY_T, "down": KEY_G, "left": KEY_F, "right": KEY_H},
]

var slot := 0
var source: LocalPlayerRegistry.InputSource
var facing := Vector2.DOWN


func configure(new_slot: int, new_source: LocalPlayerRegistry.InputSource) -> void:
	slot = new_slot
	source = new_source


func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var direction := _read_direction()
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	velocity = direction.normalized() * SPEED if direction.length() > 1.0 else direction * SPEED
	move_and_slide()
	global_position = Vector2(
		clampf(global_position.x, ARENA_RECT.position.x, ARENA_RECT.end.x),
		clampf(global_position.y, ARENA_RECT.position.y, ARENA_RECT.end.y)
	)
	queue_redraw()


func _draw() -> void:
	var color := COLORS[slot]
	draw_circle(Vector2.ZERO, RADIUS + 6.0, Color("10171c"))
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, color.lightened(0.35), 3.0)
	draw_line(Vector2.ZERO, facing * 34.0, Color.WHITE, 4.0)
	draw_circle(facing * 34.0, 4.0, Color.WHITE)


func _read_direction() -> Vector2:
	if source == null:
		return Vector2.ZERO
	if source.kind == &"joypad":
		var raw := Vector2(
			Input.get_joy_axis(source.device_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(source.device_id, JOY_AXIS_LEFT_Y)
		)
		return raw if raw.length() >= 0.2 else Vector2.ZERO

	var profile: Dictionary = KEYBOARD_PROFILES[source.profile]
	return Input.get_vector(
		_key_action(profile["left"]),
		_key_action(profile["right"]),
		_key_action(profile["up"]),
		_key_action(profile["down"])
	)


func _key_action(keycode: Key) -> StringName:
	var action := StringName("prototype_key_%d" % keycode)
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)
	return action
