class_name Telegraph
extends RefCounted

## Áreas anunciadas no chão antes do golpe (decisão 553). Chefes e perigos de bioma criam
## telegrafias; ao fim do aviso a simulação aplica dano e efeito em quem estiver dentro.
## Formas: `circle` (raio), `ring` (entre `inner` e `radius`) e `rect` (linha de `length` x `width`
## a partir de `position` na direção `angle`).

static func circle(position: Vector2, radius: float, delay: float, damage: float, effect: Dictionary = {}) -> Dictionary:
	return {"shape": "circle", "position": position, "radius": radius, "delay": delay, "remaining": delay, "damage": damage, "effect": effect}


static func ring(position: Vector2, inner: float, radius: float, delay: float, damage: float, effect: Dictionary = {}) -> Dictionary:
	return {"shape": "ring", "position": position, "inner": inner, "radius": radius, "delay": delay, "remaining": delay, "damage": damage, "effect": effect}


static func line(origin: Vector2, angle: float, length: float, width: float, delay: float, damage: float, effect: Dictionary = {}) -> Dictionary:
	return {"shape": "rect", "position": origin, "angle": angle, "length": length, "width": width, "delay": delay, "remaining": delay, "damage": damage, "effect": effect}


static func contains(telegraph: Dictionary, point: Vector2, margin: float = 0.0) -> bool:
	var origin := telegraph["position"] as Vector2
	match String(telegraph.get("shape", "circle")):
		"ring":
			var distance := origin.distance_to(point)
			return distance >= float(telegraph["inner"]) - margin and distance <= float(telegraph["radius"]) + margin
		"rect":
			var local := (point - origin).rotated(-float(telegraph["angle"]))
			return local.x >= -margin and local.x <= float(telegraph["length"]) + margin and absf(local.y) <= float(telegraph["width"]) * 0.5 + margin
		_:
			return origin.distance_to(point) <= float(telegraph["radius"]) + margin


## Cria as telegrafias de uma habilidade. `context` traz `origin` (quem lança), `targets` (posições
## dos jogadores), `center` (centro da arena ou do grupo) e `random`. Habilidades sem área
## (`barrage`, `summon`) devolvem um pedido em `actions` para a simulação executar.
static func from_ability(ability: Dictionary, context: Dictionary, damage_scale: float) -> Dictionary:
	var result := {"telegraphs": [] as Array[Dictionary], "actions": [] as Array[Dictionary], "lock": 0.0}
	var telegraphs := result["telegraphs"] as Array[Dictionary]
	var origin := context["origin"] as Vector2
	var targets := context.get("targets", []) as Array
	var random := context["random"] as RandomNumberGenerator
	var delay := float(ability.get("delay", 1.2))
	var damage := float(ability.get("damage", 20.0)) * damage_scale
	var first_target: Vector2 = targets[0] if not targets.is_empty() else origin + Vector2.DOWN * 200.0
	var aim := (first_target - origin).angle()
	match String(ability.get("type", "slam")):
		"slam":
			var shuffled := targets.duplicate()
			shuffled.shuffle()
			for index in range(mini(int(ability.get("targets", 1)), maxi(1, shuffled.size()))):
				var spot: Vector2 = shuffled[index] if index < shuffled.size() else first_target
				telegraphs.append(circle(spot, float(ability.get("radius", 80.0)), delay, damage))
		"nova":
			telegraphs.append(circle(origin, float(ability.get("radius", 150.0)), delay, damage))
			result["lock"] = delay
		"donut":
			telegraphs.append(ring(origin, float(ability.get("inner", 110.0)), float(ability.get("radius", 300.0)), delay, damage))
			result["lock"] = delay
		"line", "gust":
			var count := int(ability.get("count", 1))
			var spread := float(ability.get("spread", 0.3))
			var effect := {"push": float(ability.get("push", 0.0))} if String(ability["type"]) == "gust" else {}
			var start := origin if String(ability["type"]) == "line" else first_target - Vector2.RIGHT.rotated(aim) * float(ability.get("length", 520.0)) * 0.5
			for index in range(count):
				var angle := aim + (float(index) - float(count - 1) * 0.5) * spread
				telegraphs.append(line(start, angle, float(ability.get("length", 560.0)), float(ability.get("width", 80.0)), delay, damage, effect))
			result["lock"] = delay * 0.6
		"cross":
			var offset := 0.0 if random.randf() < 0.5 else PI * 0.25
			for index in range(4):
				telegraphs.append(line(origin, offset + PI * 0.5 * float(index), float(ability.get("length", 600.0)), float(ability.get("width", 80.0)), delay, damage))
			result["lock"] = delay
		"charge":
			var length := minf(origin.distance_to(first_target) + 80.0, 700.0)
			telegraphs.append(line(origin, aim, length, float(ability.get("width", 110.0)), delay, damage, {"charge_to": origin + Vector2.RIGHT.rotated(aim) * length}))
			result["lock"] = delay
		"meteor":
			var center := context.get("center", origin) as Vector2
			for index in range(int(ability.get("count", 5))):
				var spot := center + Vector2.RIGHT.rotated(random.randf() * TAU) * random.randf_range(0.0, float(ability.get("spread", 360.0)))
				if index < targets.size() and index % 2 == 0:
					spot = targets[index] as Vector2
				telegraphs.append(circle(spot, float(ability.get("radius", 80.0)), delay + random.randf_range(0.0, 0.5), damage))
		"zone":
			for index in range(mini(int(ability.get("targets", 2)), maxi(1, targets.size()))):
				var spot: Vector2 = targets[index] if index < targets.size() else first_target
				telegraphs.append(circle(spot, float(ability.get("radius", 95.0)), delay, damage * 0.5, {
					"zone": {"radius": float(ability.get("radius", 95.0)), "damage": damage, "duration": float(ability.get("duration", 5.0)), "slow": float(ability.get("slow", 0.0))},
				}))
		"pull":
			var radius := float(ability.get("radius", 360.0))
			telegraphs.append(circle(origin, radius * 0.38, delay, damage, {"pull_radius": radius, "pull_strength": float(ability.get("strength", 200.0))}))
			result["lock"] = delay
		"barrage":
			(result["actions"] as Array[Dictionary]).append({"type": "barrage", "count": int(ability.get("count", 12)), "speed": float(ability.get("speed", 260.0)), "damage": float(ability.get("damage", 18.0)) * damage_scale})
		"summon":
			(result["actions"] as Array[Dictionary]).append({"type": "summon", "count": int(ability.get("count", 2))})
	return result
