extends RefCounted

const RESOURCES := ["madeira", "minerio", "alimentos"]
const CAPACITY := 1000
const NODE_CAPACITY := 12
const WORK_SECONDS := 8.0
const REGEN_SECONDS := 60.0
const LOAD := 6
var stock := {"madeira": 0, "minerio": 0, "alimentos": 0}
var deliveries := 0
var nodes: Array[Dictionary] = []
var warehouse := Vector2.ZERO

func setup(spots: Dictionary) -> void:
	stock = {"madeira": 0, "minerio": 0, "alimentos": 0}
	deliveries = 0
	warehouse = spots.get("warehouse", Vector2(385, 455)) as Vector2
	nodes.clear()
	for definition: Dictionary in spots.get("resources", []):
		var node := definition.duplicate(true)
		node["amount"] = NODE_CAPACITY
		node["regen"] = REGEN_SECONDS
		nodes.append(node)

func step(delta: float) -> void:
	for node in nodes:
		node["regen"] = float(node["regen"]) - delta
		if float(node["regen"]) <= 0.0:
			node["amount"] = mini(NODE_CAPACITY, int(node["amount"]) + 2)
			node["regen"] = REGEN_SECONDS

func worker_step(npc: Dictionary, delta: float, night: bool) -> void:
	var resource := String(npc["resource"])
	var cargo := int(npc.get("cargo", 0))
	var phase := String(npc.get("job_phase", "buscar"))
	var slot := Vector2(float(posmod(String(npc["id"]).hash(), 5) - 2) * 16.0, 24.0)
	if cargo >= LOAD or phase == "entregar" or (night and cargo > 0):
		npc["job_phase"] = "entregar"
		npc["target"] = warehouse + slot
		npc["action_label"] = "entregando %s (%d)" % [resource, cargo]
		if (npc["position"] as Vector2).distance_to(warehouse + slot) <= 5.0:
			var accepted := mini(cargo, CAPACITY - int(stock[resource]))
			stock[resource] = int(stock[resource]) + accepted
			npc["cargo"] = cargo - accepted
			if accepted > 0:
				deliveries += 1
			if int(npc["cargo"]) == 0:
				npc["job_phase"] = "buscar"
			else:
				npc["action_label"] = "armazem cheio"
		return
	if night:
		npc["target"] = npc["home"]
		npc["action_label"] = "em casa"
		npc["job_phase"] = "buscar"
		npc["work_timer"] = 0.0
		return
	var chosen := {}
	var nearest := INF
	for node in nodes:
		if String(node["resource"]) != resource or int(node["amount"]) <= 0:
			continue
		var distance := (npc["position"] as Vector2).distance_squared_to((node["position"] as Vector2) + slot)
		if distance < nearest:
			nearest = distance
			chosen = node
	if chosen.is_empty():
		npc["target"] = warehouse if cargo > 0 else npc["work"]
		npc["job_phase"] = "entregar" if cargo > 0 else "buscar"
		npc["action_label"] = "aguardando recursos"
		npc["work_timer"] = 0.0
		return
	npc["target"] = (chosen["position"] as Vector2) + slot
	npc["action_label"] = "coletando %s" % resource if nearest <= 25.0 else "indo coletar %s" % resource
	if nearest > 25.0:
		npc["work_timer"] = 0.0
		return
	npc["work_timer"] = float(npc.get("work_timer", 0.0)) + delta
	if float(npc["work_timer"]) >= WORK_SECONDS:
		var harvested := mini(2, int(chosen["amount"]))
		chosen["amount"] = int(chosen["amount"]) - harvested
		npc["cargo"] = cargo + harvested
		npc["work_timer"] = 0.0

func view() -> Dictionary:
	return {"stock": stock.duplicate(), "capacity": CAPACITY, "deliveries": deliveries, "position": warehouse, "nodes": nodes.duplicate(true)}

func snapshot() -> Dictionary:
	var saved_nodes := {}
	for node in nodes:
		saved_nodes[node["id"]] = {"amount": node["amount"], "regen": node["regen"]}
	return {"stock": stock.duplicate(), "deliveries": deliveries, "nodes": saved_nodes}

func restore(data: Dictionary) -> void:
	var saved_stock := data.get("stock", {}) as Dictionary
	for resource in RESOURCES:
		stock[resource] = clampi(int(saved_stock.get(resource, 0)), 0, CAPACITY)
	deliveries = maxi(0, int(data.get("deliveries", 0)))
	for node in nodes:
		var saved := (data.get("nodes", {}) as Dictionary).get(node["id"], {}) as Dictionary
		node["amount"] = clampi(int(saved.get("amount", NODE_CAPACITY)), 0, NODE_CAPACITY)
		node["regen"] = clampf(float(saved.get("regen", REGEN_SECONDS)), 0.0, REGEN_SECONDS)
