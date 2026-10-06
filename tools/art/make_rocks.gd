extends SceneTree

## Desenha props/rocks: aglomerado de pedras facetadas na paleta das Galerias Refeitas.
## Determinístico (semente fixa). Uso: godot --headless --path . --script tools/art/make_rocks.gd

const OUTPUT := "res://assets/sprites/props/rocks.png"
const SIZE := Vector2i(56, 44)
const OUTLINE := Color("1b1a1f")
## Da sombra ao brilho; mesmas cores do pilar e dos caixotes da Torre.
const RAMP: Array[Color] = [Color("4a3f4f"), Color("6b5a5e"), Color("858179"), Color("aaa59a"), Color("d9c2a0")]
const SPARK := Color("f2e6c9")
const LIGHT := Vector3(-0.55, -0.7, 0.62)
## centro, raios, altura do pico e número de vértices de cada pedra; as da frente vêm por último.
const ROCKS := [
	{"center": Vector2(29.0, 24.0), "radius": Vector2(18.0, 16.0), "height": 15.0, "sides": 8},
	{"center": Vector2(13.0, 33.0), "radius": Vector2(11.0, 9.0), "height": 9.0, "sides": 7},
	{"center": Vector2(43.0, 34.0), "radius": Vector2(10.5, 8.0), "height": 8.0, "sides": 6},
]
const CRACK: Array[Vector2i] = [Vector2i(31, 14), Vector2i(32, 15), Vector2i(32, 16), Vector2i(33, 17), Vector2i(34, 18), Vector2i(34, 19)]
const PEBBLES := [Vector2i(4, 40), Vector2i(52, 41), Vector2i(26, 42)]


func _init() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 7041
	var light := LIGHT.normalized()
	var owner := []
	var shade := []
	for y in range(SIZE.y):
		owner.append([])
		shade.append([])
		for x in range(SIZE.x):
			owner[y].append(-1)
			shade[y].append(0)
	for index in range(ROCKS.size()):
		var rock := ROCKS[index] as Dictionary
		var center := rock["center"] as Vector2
		var radius := rock["radius"] as Vector2
		var sides := int(rock["sides"])
		# Contorno irregular, com a base achatada para a pedra assentar no chão.
		var ring: Array[Vector2] = []
		for side in range(sides):
			var angle := TAU * (float(side) + random.randf_range(-0.25, 0.25)) / float(sides)
			var point := center + Vector2(cos(angle), sin(angle)) * radius * random.randf_range(0.82, 1.0)
			point.y = minf(point.y, center.y + radius.y * 0.55)
			ring.append(point)
		# Pico deslocado para cima-esquerda: as faces viradas para a luz ficam maiores.
		var peak := center + Vector2(-radius.x * 0.18, -radius.y * 0.3)
		var top := Vector3(peak.x, peak.y, float(rock["height"]))
		for side in range(sides):
			var a := ring[side]
			var b := ring[(side + 1) % sides]
			var normal := (Vector3(a.x, a.y, 0.0) - top).cross(Vector3(b.x, b.y, 0.0) - top).normalized()
			if normal.z < 0.0:
				normal = -normal
			var level := clampf(normal.dot(light) * 0.5 + 0.5, 0.0, 0.999)
			# Curva mais escura: a maior parte da pedra fica nos tons médios.
			var tone := clampi(int(pow(level, 1.6) * RAMP.size() + 0.35), 0, RAMP.size() - 1)
			var triangle := PackedVector2Array([peak, a, b])
			for y in range(SIZE.y):
				for x in range(SIZE.x):
					if Geometry2D.is_point_in_polygon(Vector2(x, y) + Vector2(0.5, 0.5), triangle):
						var near_ground := float(y) > center.y + radius.y * 0.35
						owner[y][x] = index
						shade[y][x] = maxi(0, tone - 1) if near_ground else tone
	var image := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var mine := int(owner[y][x])
			if mine < 0:
				continue
			var tone := int(shade[y][x])
			# Salpicado de um tom, como a pedra do pilar.
			var grain := random.randf()
			if grain < 0.05:
				tone = mini(tone + 1, RAMP.size() - 1)
			elif grain < 0.09:
				tone = maxi(tone - 1, 0)
			if Vector2i(x, y) in CRACK:
				tone = 0
			var color := RAMP[tone]
			# Divisa entre pedras: a de trás ganha contorno onde a da frente começa.
			for neighbor: Vector2i in [Vector2i(x, y + 1), Vector2i(x + 1, y), Vector2i(x - 1, y)]:
				if neighbor.x >= 0 and neighbor.x < SIZE.x and neighbor.y < SIZE.y and int(owner[neighbor.y][neighbor.x]) > mine:
					color = OUTLINE
			# Brilho na borda de cima-esquerda, de onde vem a luz.
			if color != OUTLINE and int(shade[y][x]) >= 3 and (y == 0 or int(owner[y - 1][x]) != mine) and (x == 0 or int(owner[y][x - 1]) == mine):
				color = SPARK
			image.set_pixel(x, y, color)
	for pebble: Vector2i in PEBBLES:
		image.set_pixel(pebble.x, pebble.y, RAMP[2])
		image.set_pixel(pebble.x + 1, pebble.y, RAMP[1])
	_outline(image)
	image.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("ROCKS_WRITTEN: %s %dx%d" % [OUTPUT, SIZE.x, SIZE.y])
	quit(0)


func _outline(image: Image) -> void:
	var source := image.duplicate() as Image
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			if source.get_pixel(x, y).a > 0.0:
				continue
			for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var other := Vector2i(x, y) + step
				if other.x >= 0 and other.y >= 0 and other.x < SIZE.x and other.y < SIZE.y and source.get_pixel(other.x, other.y).a > 0.0:
					image.set_pixel(x, y, OUTLINE)
					break
