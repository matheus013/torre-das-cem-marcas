extends Node2D

const ARENA_RECT := Rect2(-640.0, -360.0, 1280.0, 720.0)
const GRID_SIZE := 64


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(ARENA_RECT, Color("182027"), true)

	for x in range(int(ARENA_RECT.position.x), int(ARENA_RECT.end.x) + 1, GRID_SIZE):
		draw_line(
			Vector2(x, ARENA_RECT.position.y),
			Vector2(x, ARENA_RECT.end.y),
			Color("243039"),
			1.0
		)

	for y in range(int(ARENA_RECT.position.y), int(ARENA_RECT.end.y) + 1, GRID_SIZE):
		draw_line(
			Vector2(ARENA_RECT.position.x, y),
			Vector2(ARENA_RECT.end.x, y),
			Color("243039"),
			1.0
		)

	draw_rect(ARENA_RECT, Color("8aa1ad"), false, 4.0)
	draw_circle(Vector2.ZERO, 92.0, Color("223c43"))
	draw_arc(Vector2.ZERO, 92.0, 0.0, TAU, 64, Color("66c7c2"), 3.0)

	_draw_landmark(Vector2(-430.0, -210.0), Color("dbb768"))
	_draw_landmark(Vector2(430.0, -210.0), Color("d87771"))
	_draw_landmark(Vector2(-430.0, 210.0), Color("7abf75"))
	_draw_landmark(Vector2(430.0, 210.0), Color("8e82cf"))


func _draw_landmark(position: Vector2, color: Color) -> void:
	draw_rect(Rect2(position - Vector2(30.0, 30.0), Vector2(60.0, 60.0)), color, true)
	draw_rect(Rect2(position - Vector2(38.0, 38.0), Vector2(76.0, 76.0)), color.lightened(0.2), false, 3.0)
