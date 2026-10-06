extends RefCounted

## Each district faces a connected street; production stays outside the residential core.
const SIZE := Vector2(3840.0, 2400.0)
const WAREHOUSE := Vector2(385.0, 495.0)
const ROADS: Array[Rect2] = [
	Rect2(120, 500, 3460, 110), Rect2(120, 1020, 3460, 110),
	Rect2(120, 1640, 3460, 110), Rect2(580, 420, 110, 1880),
	Rect2(1080, 500, 110, 1250), Rect2(2180, 420, 110, 1880),
	Rect2(3440, 500, 110, 1800), Rect2(580, 2180, 2970, 100),
]
const DISTRICTS: Array[Dictionary] = [
	{"name": "Centro e expedicoes", "rect": Rect2(120, 250, 1950, 700), "tile": "tiles/road"},
	{"name": "Praca e feira", "rect": Rect2(1250, 1150, 800, 400), "tile": "tiles/road"},
	{"name": "Oficinas", "rect": Rect2(750, 1800, 1200, 330), "tile": "tiles/road"},
	{"name": "Fazendas Campelo", "rect": Rect2(140, 1800, 390, 330), "tile": "tiles/road"},
	{"name": "Pedreira", "rect": Rect2(2480, 1800, 750, 330), "tile": "tiles/floor_tower"},
]

static func pieces() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Array in [
		["armazem", Vector2(385, 400), "ARMAZEM COMUNITARIO"],
		["house", Vector2(850, 470), "CASA DE ELEN"],
		["expedicoes", Vector2(1340, 440), "EXPEDICOES"],
		["torre", Vector2(1665, 395), "TORRE"],
		["posto_guarda", Vector2(1900, 455), "GUARDA"],
		["conselho", Vector2(1500, 990), "CONSELHO"],
		["enfermaria", Vector2(1800, 990), "ENFERMARIA"],
		["arquivo", Vector2(2050, 990), "ARQUIVO"],
		["forja", Vector2(1000, 1980), "FORJA"],
		["cabin", Vector2(1800, 1980), "ALQUIMIA"],
		["cabin", Vector2(1350, 1980), "OFICINA PEDRALVA"],
		["cabin", Vector2(3150, 1470), "SERRARIA"],
		["cabin", Vector2(2550, 1970), "POSTO DA PEDREIRA"],
	]:
		result.append(_building(String(item[0]), item[1] as Vector2, String(item[2])))
	for row in range(3):
		for column in range(4):
			var base := Vector2(2420 + column * 280, [470, 990, 1610][row])
			result.append(_building(["house_blue", "house_stone", "house"][column % 3], base, ""))
	for base: Vector2 in [Vector2(300, 990), Vector2(850, 990), Vector2(300, 1610), Vector2(850, 1610)]:
		result.append(_building("house_blue", base, ""))
	for item: Array in [
		["fonte", Vector2(1650, 1350)], ["barraca_frutas", Vector2(1370, 1250)],
		["barraca_tecidos", Vector2(1940, 1250)], ["barraca_frutas", Vector2(1370, 1480)],
		["banco", Vector2(1800, 1450)], ["banco", Vector2(1800, 1250)],
		["well", Vector2(460, 1880)], ["cart", Vector2(240, 420)],
		["crates", Vector2(495, 415)], ["crates", Vector2(1550, 1990)],
		["workbench", Vector2(1150, 1990)], ["andaime_vila", Vector2(1480, 2090)],
		["bandeira", Vector2(1380, 990)], ["bandeira", Vector2(1620, 990)],
	]:
		result.append(_prop(String(item[0]), item[1] as Vector2))
	for x in [220, 360]:
		for y in [1920, 2060]:
			result.append(_prop("plantacao", Vector2(x, y)))
	for x in range(2700, 3300, 160):
		result.append(_prop("rocks", Vector2(x, 1900)))
		result.append(_prop("rocks", Vector2(x + 40, 2090)))
	for x in range(2530, 3100, 170):
		for y in [1200, 1380]:
			result.append(_prop("pines", Vector2(x, y)))
	var buildings := result.filter(func(piece: Dictionary) -> bool: return String(piece["sprite"]).begins_with("buildings/"))
	for road in ROADS:
		if road.size.x > road.size.y:
			for x in range(int(road.position.x) + 40, int(road.end.x), 300):
				var spot := Vector2(x, road.position.y - 16)
				# Poste nunca na frente de uma entrada: bloquearia a porta e o ponto de chegada.
				if buildings.any(func(piece: Dictionary) -> bool: return absf(spot.x - (piece["base"] as Vector2).x) < 80.0 and spot.y >= (piece["base"] as Vector2).y and spot.y - (piece["base"] as Vector2).y < 140.0):
					continue
				result.append(_prop("lamp", spot))
	return result

static func _building(id: String, base: Vector2, label: String) -> Dictionary:
	return {"sprite": "buildings/" + id, "base": base, "solid": Rect2(-62, -100, 124, 75), "label": label}

static func _prop(id: String, base: Vector2) -> Dictionary:
	var footprint := Rect2(-18, -16, 36, 14)
	var visual_scale := 1.0
	if id in ["barraca_frutas", "barraca_tecidos", "banco"]:
		visual_scale = 2.0
		footprint = Rect2(-30, -30, 60, 28)
	if id in ["plantacao", "fonte", "rocks", "pines"]:
		footprint = Rect2(-35, -26, 70, 24)
	return {"sprite": "props/" + id, "base": base, "solid": footprint, "visual_scale": visual_scale}

static func spots() -> Dictionary:
	var homes: Array[Vector2] = [Vector2(850, 570), Vector2(300, 1050), Vector2(850, 1050), Vector2(300, 1670), Vector2(850, 1670)]
	for row in range(3):
		for column in range(4):
			homes.append(Vector2(2420 + column * 280, [530, 1050, 1670][row]))
	var nodes: Array[Dictionary] = []
	for index in range(4):
		nodes.append({"id": "campo_%d" % index, "resource": "alimentos", "position": Vector2(220 + (index % 2) * 140, 1970 + (index / 2) * 140)})
		nodes.append({"id": "mina_%d" % index, "resource": "minerio", "position": Vector2(2700 + index * 160, 1960)})
		nodes.append({"id": "bosque_%d" % index, "resource": "madeira", "position": Vector2(2530 + index * 170, 1440)})
	return {"work": {
		"conselho": Vector2(1500, 1090), "vigilia": Vector2(1620, 1090),
		"expedicoes": Vector2(1340, 560), "forja": Vector2(1000, 2080), "alquimia": Vector2(1800, 2080),
		"armazem": WAREHOUSE, "posto_guarda": Vector2(1900, 520),
		"enfermaria": Vector2(1800, 1090), "campos": Vector2(350, 1970),
		"obra": Vector2(1350, 2080), "arquivo": Vector2(2050, 1090),
		"casa_elen": Vector2(850, 570), "feira": Vector2(1460, 1310),
		"praca": Vector2(1650, 1450), "mina": Vector2(2780, 1960), "madeira": Vector2(2820, 1440),
	}, "homes": homes, "home_by_id": {"elen": Vector2(850, 570)}, "warehouse": WAREHOUSE,
	"resources": nodes, "size": SIZE,
	"social": [Vector2(1550, 1420), Vector2(1810, 1350), Vector2(1320, 560), Vector2(850, 1100)],
	"patrol": [Vector2(1665, 550), Vector2(2200, 550), Vector2(2250, 1080), Vector2(650, 1080), Vector2(650, 550)]}
