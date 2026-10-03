extends SceneTree

## Gera ícones provisórios das gemas em pixel art (28×28) enquanto o PixelForge não os fornece.
## Uso: godot --headless --path . --script tools/art/make_skill_icons.gd [-- --force]
## Sem --force, ícones já existentes (por exemplo, gerados pelo PixelForge) são preservados.

const OUTPUT := "res://assets/sprites/icons/"
const SIZE := 28
const DARK := Color("1b1a1f")
const INNER := Color("2f2a35")
const STONE := Color("8f7a6a")
const BRONZE := Color("d9824a")
const CYAN := Color("7fd6e0")
const PALE := Color("c8f2f0")
const PURPLE := Color("8a5f9e")
const DEEP := Color("5a3d6b")
const GREEN := Color("93a75a")
const MOSS := Color("5f7f45")
const GOLD := Color("e8b84a")
const RED := Color("b04a3a")
const GREY := Color("aaa59a")
const LIGHT := Color("f2e6c9")

var _image: Image


func _init() -> void:
	var force := "--force" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var made := 0
	for id: String in _painters():
		var path := ProjectSettings.globalize_path(OUTPUT + id + ".png")
		if FileAccess.file_exists(path) and not force:
			continue
		_image = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		var support := not id in ["agulha_lastro", "passo_vetorial", "pulso_cicatriz", "prisao_gravitica", "muralha_refeita", "elo_residual", "molde_vigilante", "semeadura_vital"]
		_frame(support)
		(_painters()[id] as Callable).call()
		_image.save_png(path)
		made += 1
	print("SKILL_ICONS: %d gerados" % made)
	quit(0)


func _painters() -> Dictionary:
	return {
		"agulha_lastro": func() -> void:
			_line(Vector2i(6, 21), Vector2i(20, 7), GREY, 2)
			_line(Vector2i(19, 8), Vector2i(21, 6), PALE, 1)
			_line(Vector2i(4, 23), Vector2i(8, 19), CYAN, 1),
		"passo_vetorial": func() -> void:
			_line(Vector2i(8, 14), Vector2i(21, 14), CYAN, 2)
			_line(Vector2i(16, 9), Vector2i(21, 14), CYAN, 2)
			_line(Vector2i(16, 19), Vector2i(21, 14), CYAN, 2)
			_line(Vector2i(4, 10), Vector2i(9, 10), STONE, 1)
			_line(Vector2i(3, 18), Vector2i(9, 18), STONE, 1),
		"pulso_cicatriz": func() -> void:
			_ring(Vector2i(14, 14), 9, CYAN)
			_ring(Vector2i(14, 14), 5, PALE)
			_dot(Vector2i(14, 14), PALE),
		"prisao_gravitica": func() -> void:
			for step in range(36):
				var angle := float(step) * 0.42
				var radius := 2.0 + float(step) * 0.27
				_dot(Vector2i(14 + int(round(cos(angle) * radius)), 14 + int(round(sin(angle) * radius))), PURPLE if step % 3 else LIGHT)
			_dot(Vector2i(14, 14), DEEP),
		"muralha_refeita": func() -> void:
			for row in range(4):
				for column in range(3):
					var x := 6 + column * 6 + (3 if row % 2 else 0)
					_rect(Rect2i(x, 7 + row * 4, 5, 3), GREY)
			_line(Vector2i(6, 15), Vector2i(22, 15), CYAN, 1),
		"elo_residual": func() -> void:
			_line(Vector2i(5, 20), Vector2i(11, 8), CYAN, 1)
			_line(Vector2i(11, 8), Vector2i(17, 20), CYAN, 1)
			_line(Vector2i(17, 20), Vector2i(23, 8), CYAN, 1)
			for point: Vector2i in [Vector2i(5, 20), Vector2i(11, 8), Vector2i(17, 20), Vector2i(23, 8)]:
				_rect(Rect2i(point - Vector2i(1, 1), Vector2i(3, 3)), PALE),
		"molde_vigilante": func() -> void:
			_rect(Rect2i(9, 8, 10, 12), GREY)
			_rect(Rect2i(7, 20, 14, 3), STONE)
			_rect(Rect2i(12, 11, 4, 3), CYAN)
			_dot(Vector2i(13, 12), PALE),
		"semeadura_vital": func() -> void:
			_ring(Vector2i(14, 15), 9, MOSS)
			_line(Vector2i(14, 21), Vector2i(14, 11), GREEN, 1)
			_rect(Rect2i(9, 10, 5, 3), GREEN)
			_rect(Rect2i(15, 8, 5, 3), GREEN),
		"projeteis_gemeos": func() -> void:
			_line(Vector2i(6, 11), Vector2i(21, 11), CYAN, 1)
			_line(Vector2i(6, 17), Vector2i(21, 17), CYAN, 1)
			_dot(Vector2i(21, 11), PALE)
			_dot(Vector2i(21, 17), PALE),
		"perfuracao_refeita": func() -> void:
			_rect(Rect2i(12, 7, 4, 14), STONE)
			_line(Vector2i(5, 14), Vector2i(23, 14), CYAN, 1)
			_dot(Vector2i(23, 14), PALE),
		"ricochete_de_junta": func() -> void:
			_line(Vector2i(5, 8), Vector2i(12, 20), CYAN, 1)
			_line(Vector2i(12, 20), Vector2i(19, 8), CYAN, 1)
			_line(Vector2i(19, 8), Vector2i(23, 15), CYAN, 1),
		"area_expandida": func() -> void:
			_ring(Vector2i(14, 14), 4, CYAN)
			_ring(Vector2i(14, 14), 8, STONE)
			_ring(Vector2i(14, 14), 11, CYAN),
		"foco_concentrado": func() -> void:
			_line(Vector2i(5, 5), Vector2i(13, 13), CYAN, 1)
			_line(Vector2i(23, 5), Vector2i(15, 13), CYAN, 1)
			_line(Vector2i(5, 23), Vector2i(13, 15), CYAN, 1)
			_line(Vector2i(23, 23), Vector2i(15, 15), CYAN, 1)
			_rect(Rect2i(13, 13, 3, 3), GOLD),
		"eco_atrasado": func() -> void:
			_ring(Vector2i(11, 14), 5, CYAN)
			_ring(Vector2i(17, 14), 5, Color(CYAN, 0.5)),
		"fluxo_rapido": func() -> void:
			_line(Vector2i(9, 7), Vector2i(19, 7), GOLD, 1)
			_line(Vector2i(9, 21), Vector2i(19, 21), GOLD, 1)
			_line(Vector2i(9, 7), Vector2i(19, 21), LIGHT, 1)
			_line(Vector2i(19, 7), Vector2i(9, 21), LIGHT, 1)
			_line(Vector2i(3, 12), Vector2i(7, 12), CYAN, 1)
			_line(Vector2i(3, 16), Vector2i(7, 16), CYAN, 1),
		"duracao_estendida": func() -> void:
			_ring(Vector2i(14, 14), 9, GOLD)
			_line(Vector2i(14, 14), Vector2i(14, 8), LIGHT, 1)
			_line(Vector2i(14, 14), Vector2i(19, 14), LIGHT, 1),
		"drenagem_vital": func() -> void:
			_rect(Rect2i(8, 9, 5, 5), RED)
			_rect(Rect2i(15, 9, 5, 5), RED)
			_rect(Rect2i(9, 13, 10, 4), RED)
			_rect(Rect2i(11, 17, 6, 3), RED)
			_rect(Rect2i(13, 20, 2, 2), RED)
			_dot(Vector2i(10, 10), LIGHT),
		"impulso_de_impacto": func() -> void:
			_rect(Rect2i(6, 10, 8, 8), GREY)
			_line(Vector2i(16, 9), Vector2i(22, 6), GOLD, 1)
			_line(Vector2i(16, 14), Vector2i(23, 14), GOLD, 1)
			_line(Vector2i(16, 19), Vector2i(22, 22), GOLD, 1),
		"busca_residual": func() -> void:
			for step in range(14):
				var x := 5 + step
				var y := 21 - int(round(pow(float(step) / 13.0, 2.0) * 13.0))
				_dot(Vector2i(x, y), CYAN)
			_ring(Vector2i(21, 8), 3, GOLD),
		"sobrecarga_instavel": func() -> void:
			_line(Vector2i(14, 5), Vector2i(21, 14), PURPLE, 1)
			_line(Vector2i(21, 14), Vector2i(14, 23), PURPLE, 1)
			_line(Vector2i(14, 23), Vector2i(7, 14), PURPLE, 1)
			_line(Vector2i(7, 14), Vector2i(14, 5), PURPLE, 1)
			_line(Vector2i(12, 9), Vector2i(15, 15), GOLD, 1)
			_line(Vector2i(15, 15), Vector2i(13, 20), GOLD, 1),
	}


func _frame(support: bool) -> void:
	_image.fill(DARK)
	_rect(Rect2i(1, 1, SIZE - 2, SIZE - 2), INNER)
	var edge := BRONZE if support else STONE
	for i in range(SIZE):
		for border in [0, SIZE - 1]:
			_image.set_pixel(i, border, edge)
			_image.set_pixel(border, i, edge)
	if support:
		for corner: Vector2i in [Vector2i(1, 1), Vector2i(SIZE - 2, 1), Vector2i(1, SIZE - 2), Vector2i(SIZE - 2, SIZE - 2)]:
			_image.set_pixelv(corner, GOLD)


func _dot(point: Vector2i, color: Color) -> void:
	if point.x > 1 and point.y > 1 and point.x < SIZE - 2 and point.y < SIZE - 2:
		_image.set_pixelv(point, color)


func _rect(rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_dot(Vector2i(x, y), color)


func _line(from: Vector2i, to: Vector2i, color: Color, width: int) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for step in range(steps + 1):
		var point := Vector2(from).lerp(Vector2(to), float(step) / float(maxi(1, steps)))
		for offset in range(width):
			_dot(Vector2i(int(round(point.x)) + offset, int(round(point.y))), color)


func _ring(center: Vector2i, radius: int, color: Color) -> void:
	for step in range(radius * 8):
		var angle := TAU * float(step) / float(radius * 8)
		_dot(center + Vector2i(int(round(cos(angle) * radius)), int(round(sin(angle) * radius))), color)
