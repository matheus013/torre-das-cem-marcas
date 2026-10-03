class_name WorldLayout
extends RefCounted

## Mapa compartilhado pela simulação (colisão e transições) e pela apresentação (desenho).
## Peças são posicionadas pela base do sprite; "solid" é a área de colisão relativa à base.

const WORLD_SIZE := Vector2(2880.0, 1620.0)
const INTERIOR_SIZE := Vector2(1280.0, 720.0)
const WORLD_SPAWN := Vector2(370.0, 650.0)
const HOUSE_RETURN := Vector2(850.0, 555.0)
const TOWER_RETURN := Vector2(1665.0, 470.0)
const HOUSE_DOOR := Rect2(824.0, 448.0, 52.0, 72.0)
const INTERIOR_EXIT := Rect2(578.0, 618.0, 124.0, 62.0)
const TOWER_DOOR := Rect2(1632.0, 358.0, 66.0, 86.0)
const TOWER_EXIT := Rect2(24.0, 300.0, 80.0, 120.0)
const BOSS_ROOM_DOOR := Rect2(1190.0, 278.0, 66.0, 164.0)
const BOSS_ROOM_EXIT := Rect2(24.0, 300.0, 80.0, 120.0)
const BOSS_ROOM_SPAWN := Vector2(850.0, 360.0)
const BOSS_ROOM_PLAYER_SPAWN := Vector2(160.0, 360.0)
const MAJOR_SPAWN_POINT := Vector2(1080.0, 360.0)
const HOUSE_ROOM := Rect2(380.0, 220.0, 520.0, 400.0)
const RESPAWN_POINTS: Array[Vector2] = [
	Vector2(500.0, 170.0), Vector2(620.0, 530.0), Vector2(920.0, 260.0), Vector2(1120.0, 520.0),
	Vector2(1180.0, 110.0), Vector2(980.0, 640.0), Vector2(700.0, 110.0), Vector2(1200.0, 640.0),
]

const VILLAGE_PIECES: Array[Dictionary] = [
	{"sprite": "buildings/armazem", "base": Vector2(385.0, 400.0), "solid": Rect2(-58.0, -78.0, 116.0, 60.0)},
	{"sprite": "buildings/house", "base": Vector2(850.0, 470.0), "solid": Rect2(-55.0, -100.0, 110.0, 70.0)},
	{"sprite": "buildings/expedicoes", "base": Vector2(1340.0, 720.0), "solid": Rect2(-62.0, -90.0, 124.0, 70.0)},
	{"sprite": "buildings/torre", "base": Vector2(1665.0, 395.0), "solid": Rect2(-62.0, -100.0, 124.0, 55.0)},
	{"sprite": "props/tree", "base": Vector2(130.0, 200.0), "solid": Rect2(-14.0, -22.0, 28.0, 16.0)},
	{"sprite": "props/tree_fruit", "base": Vector2(1070.0, 260.0), "solid": Rect2(-12.0, -18.0, 24.0, 14.0)},
	{"sprite": "props/pines", "base": Vector2(1440.0, 330.0), "solid": Rect2(-12.0, -16.0, 24.0, 12.0)},
	{"sprite": "props/tree", "base": Vector2(2050.0, 1470.0), "solid": Rect2(-14.0, -22.0, 28.0, 16.0)},
	{"sprite": "props/pines", "base": Vector2(190.0, 950.0), "solid": Rect2(-12.0, -16.0, 24.0, 12.0)},
	{"sprite": "props/tree_fruit", "base": Vector2(470.0, 900.0), "solid": Rect2(-12.0, -18.0, 24.0, 14.0)},
	{"sprite": "props/pines", "base": Vector2(1880.0, 140.0), "solid": Rect2(-12.0, -16.0, 24.0, 12.0)},
	{"sprite": "props/tree", "base": Vector2(1000.0, 1020.0), "solid": Rect2(-14.0, -22.0, 28.0, 16.0)},
	{"sprite": "props/well", "base": Vector2(780.0, 700.0), "solid": Rect2(-22.0, -24.0, 44.0, 20.0)},
	{"sprite": "props/crates", "base": Vector2(470.0, 420.0), "solid": Rect2(-20.0, -14.0, 40.0, 12.0)},
	{"sprite": "props/lamp", "base": Vector2(540.0, 495.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(990.0, 495.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(1590.0, 495.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(1180.0, 760.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "buildings/house_blue", "base": Vector2(300.0, 860.0), "solid": Rect2(-58.0, -96.0, 116.0, 70.0)},
	{"sprite": "buildings/house_stone", "base": Vector2(855.0, 920.0), "solid": Rect2(-55.0, -96.0, 110.0, 70.0)},
	{"sprite": "buildings/house_stone", "base": Vector2(1250.0, 330.0), "solid": Rect2(-55.0, -96.0, 110.0, 70.0)},
	{"sprite": "buildings/cabin", "base": Vector2(1660.0, 980.0), "solid": Rect2(-55.0, -96.0, 110.0, 70.0)},
	{"sprite": "props/cart", "base": Vector2(300.0, 470.0), "solid": Rect2(-16.0, -12.0, 32.0, 10.0)},
	{"sprite": "props/sign", "base": Vector2(1575.0, 485.0), "solid": Rect2(-3.0, -5.0, 6.0, 5.0)},
	{"sprite": "deco/barrel_1", "base": Vector2(1440.0, 700.0), "solid": Rect2(-26.0, -16.0, 52.0, 14.0)},
	{"sprite": "deco/barrel_2", "base": Vector2(1015.0, 420.0), "solid": Rect2(-14.0, -12.0, 28.0, 10.0)},
	{"sprite": "deco/bush_1", "base": Vector2(1530.0, 700.0), "solid": Rect2(-28.0, -16.0, 56.0, 12.0)},
	{"sprite": "props/fence", "base": Vector2(130.0, 760.0), "solid": Rect2(-28.0, -8.0, 56.0, 6.0)},
	{"sprite": "props/fence", "base": Vector2(186.0, 760.0), "solid": Rect2(-28.0, -8.0, 56.0, 6.0)},
	{"sprite": "props/fence", "base": Vector2(1120.0, 160.0), "solid": Rect2(-28.0, -8.0, 56.0, 6.0)},
	{"sprite": "props/fence", "base": Vector2(1176.0, 160.0), "solid": Rect2(-28.0, -8.0, 56.0, 6.0)},
	# Bairros da ampliação (decisão 561): conselho, guarda, praça e feira, enfermaria, arquivo,
	# forja, obra da Pedralva, plantações dos Campelo e novas casas.
	{"sprite": "buildings/conselho", "base": Vector2(2420.0, 430.0), "solid": Rect2(-70.0, -95.0, 140.0, 75.0), "label": "CONSELHO"},
	{"sprite": "props/bandeira", "base": Vector2(2310.0, 470.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/bandeira", "base": Vector2(2530.0, 470.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "buildings/posto_guarda", "base": Vector2(1880.0, 330.0), "solid": Rect2(-40.0, -60.0, 80.0, 50.0), "label": "GUARDA"},
	{"sprite": "props/fonte", "base": Vector2(1960.0, 900.0), "solid": Rect2(-40.0, -40.0, 80.0, 34.0)},
	{"sprite": "props/barraca_frutas", "base": Vector2(1790.0, 800.0), "solid": Rect2(-30.0, -24.0, 60.0, 20.0)},
	{"sprite": "props/barraca_tecidos", "base": Vector2(2130.0, 800.0), "solid": Rect2(-30.0, -24.0, 60.0, 20.0)},
	{"sprite": "props/barraca_frutas", "base": Vector2(1800.0, 1010.0), "solid": Rect2(-30.0, -24.0, 60.0, 20.0)},
	{"sprite": "props/banco", "base": Vector2(2080.0, 990.0), "solid": Rect2(-18.0, -8.0, 36.0, 6.0)},
	{"sprite": "props/banco", "base": Vector2(1850.0, 900.0), "solid": Rect2(-18.0, -8.0, 36.0, 6.0)},
	{"sprite": "buildings/enfermaria", "base": Vector2(2580.0, 900.0), "solid": Rect2(-65.0, -90.0, 130.0, 70.0), "label": "ENFERMARIA"},
	{"sprite": "buildings/arquivo", "base": Vector2(2560.0, 1560.0), "solid": Rect2(-60.0, -110.0, 120.0, 85.0), "label": "ARQUIVO"},
	{"sprite": "buildings/forja", "base": Vector2(1520.0, 1230.0), "solid": Rect2(-62.0, -90.0, 124.0, 70.0), "label": "FORJA"},
	{"sprite": "props/andaime_vila", "base": Vector2(1400.0, 960.0), "solid": Rect2(-30.0, -20.0, 60.0, 18.0)},
	{"sprite": "props/plantacao", "base": Vector2(260.0, 1360.0), "solid": Rect2(-50.0, -30.0, 100.0, 26.0)},
	{"sprite": "props/plantacao", "base": Vector2(440.0, 1360.0), "solid": Rect2(-50.0, -30.0, 100.0, 26.0)},
	{"sprite": "props/plantacao", "base": Vector2(260.0, 1520.0), "solid": Rect2(-50.0, -30.0, 100.0, 26.0)},
	{"sprite": "props/plantacao", "base": Vector2(440.0, 1520.0), "solid": Rect2(-50.0, -30.0, 100.0, 26.0)},
	{"sprite": "props/fence", "base": Vector2(560.0, 1440.0), "solid": Rect2(-28.0, -8.0, 56.0, 6.0)},
	{"sprite": "buildings/house_blue", "base": Vector2(2720.0, 330.0), "solid": Rect2(-58.0, -96.0, 116.0, 70.0)},
	{"sprite": "buildings/house_stone", "base": Vector2(860.0, 1540.0), "solid": Rect2(-55.0, -96.0, 110.0, 70.0)},
	{"sprite": "buildings/cabin", "base": Vector2(1960.0, 1540.0), "solid": Rect2(-55.0, -96.0, 110.0, 70.0)},
	{"sprite": "buildings/house", "base": Vector2(2760.0, 1220.0), "solid": Rect2(-55.0, -100.0, 110.0, 70.0)},
	{"sprite": "props/lamp", "base": Vector2(2000.0, 495.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(2400.0, 495.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(1880.0, 760.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(2050.0, 1050.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(1300.0, 1240.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(700.0, 1240.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/lamp", "base": Vector2(2440.0, 1240.0), "solid": Rect2(-4.0, -6.0, 8.0, 6.0)},
	{"sprite": "props/crates", "base": Vector2(1660.0, 1250.0), "solid": Rect2(-20.0, -14.0, 40.0, 12.0)},
	{"sprite": "deco/barrel_3", "base": Vector2(2200.0, 1010.0), "solid": Rect2(-14.0, -12.0, 28.0, 10.0)},
]
## Locais de trabalho, casas, pontos de encontro e ronda dos moradores (decisão 560).
const VILLAGE_SPOTS := {
	"work": {
		"conselho": Vector2(2420.0, 480.0), "vigilia": Vector2(2330.0, 500.0), "expedicoes": Vector2(1340.0, 770.0),
		"forja": Vector2(1520.0, 1270.0), "armazem": Vector2(385.0, 440.0), "posto_guarda": Vector2(1860.0, 390.0),
		"enfermaria": Vector2(2580.0, 950.0), "campos": Vector2(350.0, 1440.0), "obra": Vector2(1400.0, 1000.0),
		"arquivo": Vector2(2560.0, 1590.0), "casa_elen": Vector2(850.0, 540.0), "feira": Vector2(1960.0, 820.0),
		"praca": Vector2(1960.0, 960.0),
	},
	"homes": [
		Vector2(850.0, 520.0), Vector2(300.0, 900.0), Vector2(855.0, 960.0), Vector2(1250.0, 370.0), Vector2(1660.0, 1020.0),
		Vector2(2720.0, 370.0), Vector2(860.0, 1580.0), Vector2(1960.0, 1580.0), Vector2(2760.0, 1260.0),
	],
	"social": [Vector2(1960.0, 960.0), Vector2(780.0, 740.0), Vector2(1960.0, 820.0), Vector2(1340.0, 800.0), Vector2(2080.0, 1020.0), Vector2(2420.0, 520.0)],
	"patrol": [Vector2(1700.0, 560.0), Vector2(1950.0, 600.0), Vector2(2250.0, 560.0), Vector2(1080.0, 600.0), Vector2(620.0, 600.0), Vector2(1080.0, 1300.0), Vector2(1900.0, 1300.0), Vector2(2230.0, 900.0)],
}
const SCATTER_SPRITES: Array[String] = [
	"deco/flower_4", "deco/flower_5", "deco/flower_6", "deco/flower_8",
	"deco/rock_4", "deco/rock_5", "deco/rock_6", "deco/bush_b_2", "deco/bush_b_3", "deco/bush_b_4",
]
const HOUSE_PIECES: Array[Dictionary] = [
	{"sprite": "props/bed", "base": Vector2(440.0, 300.0), "solid": Rect2(-27.0, -40.0, 54.0, 38.0)},
	{"sprite": "props/shelf", "base": Vector2(560.0, 262.0), "solid": Rect2(-27.0, -30.0, 54.0, 28.0)},
	{"sprite": "props/workbench", "base": Vector2(830.0, 290.0), "solid": Rect2(-27.0, -34.0, 54.0, 30.0)},
	{"sprite": "props/table", "base": Vector2(660.0, 440.0), "solid": Rect2(-26.0, -34.0, 52.0, 30.0)},
	{"sprite": "props/crates", "base": Vector2(860.0, 600.0), "solid": Rect2(-20.0, -14.0, 40.0, 12.0)},
	{"sprite": "deco/barrel_2", "base": Vector2(420.0, 600.0), "solid": Rect2(-14.0, -12.0, 28.0, 10.0)},
	{"sprite": "deco/flower_1", "base": Vector2(760.0, 250.0), "solid": Rect2(-10.0, -8.0, 20.0, 6.0)},
]
const TOWER_PIECES: Array[Dictionary] = [
	{"sprite": "props/pillar", "base": Vector2(400.0, 320.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
	{"sprite": "props/pillar", "base": Vector2(400.0, 160.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
	{"sprite": "props/pillar", "base": Vector2(825.0, 610.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
	{"sprite": "props/pillar", "base": Vector2(825.0, 450.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
	{"sprite": "props/pillar", "base": Vector2(1100.0, 240.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
]
const BOSS_ROOM_PIECES: Array[Dictionary] = [
	{"sprite": "props/pillar", "base": Vector2(360.0, 230.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
	{"sprite": "props/pillar", "base": Vector2(360.0, 560.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
	{"sprite": "props/pillar", "base": Vector2(1060.0, 230.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
	{"sprite": "props/pillar", "base": Vector2(1060.0, 560.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0)},
]
const VILLAGE_ROADS: Array[Rect2] = [
	Rect2(0.0, 500.0, 2880.0, 150.0),
	Rect2(560.0, 0.0, 150.0, 1620.0),
	Rect2(1000.0, 450.0, 160.0, 1170.0),
	Rect2(2160.0, 0.0, 140.0, 1620.0),
	Rect2(0.0, 1250.0, 2880.0, 130.0),
]
const REINFORCEMENT_PIECE := {"sprite": "props/pillar", "base": Vector2(1250.0, 860.0), "solid": Rect2(-22.0, -36.0, 44.0, 34.0), "label": "REFORCO CONSTRUIDO"}

static var _scenery: Array[Dictionary] = []


static func map_size(zone: StringName) -> Vector2:
	return WORLD_SIZE if zone == &"village" else INTERIOR_SIZE


## Borda de floresta e detalhes espalhados, gerados sempre com as mesmas sementes.
static func village_scenery() -> Array[Dictionary]:
	if not _scenery.is_empty():
		return _scenery
	var tree_keys: Array[String] = ["props/tree", "props/pines", "props/tree_fruit"]
	var border_index := 0
	for x in range(40, int(WORLD_SIZE.x), 120):
		for y: float in [70.0, WORLD_SIZE.y + 20.0]:
			if (x > 540 and x < 730) or (x > 980 and x < 1180) or (x > 2140 and x < 2320):
				continue
			_scenery.append({"sprite": tree_keys[border_index % 3], "base": Vector2(x + (border_index % 2) * 30.0, y), "solid": Rect2(-14.0, -22.0, 28.0, 16.0)})
			border_index += 1
	for y in range(200, int(WORLD_SIZE.y) - 60, 130):
		for x: float in [10.0, WORLD_SIZE.x - 10.0]:
			if (y > 470 and y < 680) or (y > 1230 and y < 1400):
				continue
			_scenery.append({"sprite": tree_keys[border_index % 3], "base": Vector2(x, y), "solid": Rect2(-14.0, -22.0, 28.0, 16.0)})
			border_index += 1
	var blocked: Array[Rect2] = []
	for road in VILLAGE_ROADS:
		blocked.append(road.grow(12.0))
	for piece in VILLAGE_PIECES + _scenery:
		var solid := piece["solid"] as Rect2
		blocked.append(Rect2((piece["base"] as Vector2) + solid.position, solid.size).grow(48.0))
	var random := RandomNumberGenerator.new()
	random.seed = 1201
	for _attempt in range(620):
		var position := Vector2(random.randf_range(60.0, WORLD_SIZE.x - 60.0), random.randf_range(120.0, WORLD_SIZE.y - 40.0))
		var free := true
		for rect in blocked:
			if rect.has_point(position):
				free = false
				break
		if free:
			_scenery.append({"sprite": SCATTER_SPRITES[random.randi() % SCATTER_SPRITES.size()], "base": position})
	return _scenery


## Pontos dos moradores mais as áreas bloqueadas por construções e árvores.
static func village_spots() -> Dictionary:
	var spots := VILLAGE_SPOTS.duplicate(true)
	spots["blocked"] = obstacles(&"village", 1)
	return spots


static func pieces(zone: StringName, village_progress: int) -> Array[Dictionary]:
	match zone:
		&"village":
			var result := VILLAGE_PIECES + village_scenery()
			if village_progress > 0:
				result.append(REINFORCEMENT_PIECE)
			return result
		&"house":
			return HOUSE_PIECES
		&"boss_room":
			return BOSS_ROOM_PIECES
	return TOWER_PIECES


static func obstacles(zone: StringName, village_progress: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for piece in pieces(zone, village_progress):
		if piece.has("solid"):
			var solid := piece["solid"] as Rect2
			result.append(Rect2((piece["base"] as Vector2) + solid.position, solid.size))
	if zone == &"house":
		result.append(Rect2(0.0, 0.0, INTERIOR_SIZE.x, HOUSE_ROOM.position.y))
		result.append(Rect2(0.0, 0.0, HOUSE_ROOM.position.x, INTERIOR_SIZE.y))
		result.append(Rect2(HOUSE_ROOM.end.x, 0.0, INTERIOR_SIZE.x - HOUSE_ROOM.end.x, INTERIOR_SIZE.y))
		result.append(Rect2(0.0, HOUSE_ROOM.end.y, INTERIOR_EXIT.position.x, INTERIOR_SIZE.y))
		result.append(Rect2(INTERIOR_EXIT.end.x, HOUSE_ROOM.end.y, INTERIOR_SIZE.x, INTERIOR_SIZE.y))
	return result


static func equipment_slot_specs() -> Array[Array]:
	var result: Array[Array] = [
		["ARMA", EquipmentItemDefinition.Slot.WEAPON, 0], ["OFFHAND", EquipmentItemDefinition.Slot.OFFHAND, 0],
		["AMULETO", EquipmentItemDefinition.Slot.AMULET, 0], ["ARMADURA", EquipmentItemDefinition.Slot.ARMOR, 0],
		["LUVAS", EquipmentItemDefinition.Slot.GLOVES, 0], ["BOTAS", EquipmentItemDefinition.Slot.BOOTS, 0],
		["CALCA", EquipmentItemDefinition.Slot.PANTS, 0],
	]
	for index in range(EquipmentLoadout.RING_SLOT_COUNT):
		result.append(["ANEL %d" % (index + 1), EquipmentItemDefinition.Slot.RING, index])
	for index in range(EquipmentLoadout.RELIC_SLOT_COUNT):
		result.append(["RELIQUIA %d" % (index + 1), EquipmentItemDefinition.Slot.RELIC, index])
	return result


static func slot_label(slot: EquipmentItemDefinition.Slot) -> String:
	return {
		EquipmentItemDefinition.Slot.WEAPON: "ARMA", EquipmentItemDefinition.Slot.OFFHAND: "OFFHAND",
		EquipmentItemDefinition.Slot.AMULET: "AMULETO", EquipmentItemDefinition.Slot.ARMOR: "ARMADURA",
		EquipmentItemDefinition.Slot.GLOVES: "LUVAS", EquipmentItemDefinition.Slot.BOOTS: "BOTAS",
		EquipmentItemDefinition.Slot.PANTS: "CALCA", EquipmentItemDefinition.Slot.RING: "ANEL",
		EquipmentItemDefinition.Slot.RELIC: "RELIQUIA",
	}.get(slot, "EQUIPAMENTO")
