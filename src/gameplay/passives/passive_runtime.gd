class_name PassiveRuntime
extends RefCounted

## Estado em combate da Passiva Autoral. Reage a eventos e devolve pedidos de efeito;
## quem aplica dano, barreira ou cura é a simulação dona desses sistemas (ADR 0009).
## Os marcos de evolução (níveis 10 a 100) alteram os parâmetros abaixo por `configure`;
## sem marcos, os valores reproduzem a decisão 520.

const OPPORTUNITY_PICKUP_RADIUS := 24.0

const DEFAULTS := {
	# Luz Residual
	"max_residues": 3, "residue_lifetime": 4.0, "conduct_amount": 12.0, "conduct_range": 200.0,
	"conduct_return": 0.0, "conduct_barrier": 0.0, "overload_power": 0.0, "discard_breath": 0.0,
	"constellation_damage": 0.0, "prism_barrier": 0.0, "memory_every": 0,
	# Duas Correntes
	"max_currents": 3, "trace_power": 0.12, "deviation_speed": 0.06, "deviation_breath": 0.15,
	"trace_loss": 1, "shift_free": 0.0, "emergency_free": 0.0, "counter_damage": 0.0,
	"improv_echo": 0.0, "route_barrier": 0.0, "dual_flow": 0, "trace_echo": 0.0,
	# Placas Adaptativas
	"sample_reduction": 0.15, "sample_power": 0.35, "instability_gain": 0.8, "discharge_amount": 40.0,
	"discharge_radius": 120.0, "max_samples": 1, "discharge_keep": 0.0, "crisis_absorb": 0.0,
	"sample_barrier": 0.0, "sample_keep": 0, "cast_discharge": 0.0,
	# Oportunidade Estrutural
	"max_opportunities": 3, "opportunity_lifetime": 10.0, "opportunity_barrier": 12.0,
	"opportunity_damage": 18.0, "opportunity_radius": 90.0, "hits_per_opportunity": 4,
	"city_damage": 0.0, "collapse_chain": 0.0, "opportunity_breath": 0.0, "city_threshold": 3,
	"pickup_summon": 0.0,
}

var passive_id: StringName = &""
var display_name := ""
var params: Dictionary = DEFAULTS.duplicate()

var _residues: Array[Dictionary] = []
var _last_slot := -1
var _traced := 0
var _deviated := 0
var _samples := 0
var _instability := 0.0
var _opportunities: Array[Dictionary] = []
var _hit_counter := 0
var _conductions := 0
var _recent_pickups: Array[float] = []
var _clock := 0.0


func setup(id: StringName, name: String) -> void:
	passive_id = id
	display_name = name
	params = DEFAULTS.duplicate()
	_residues.clear()
	_opportunities.clear()
	_recent_pickups.clear()
	_last_slot = -1
	_traced = 0
	_deviated = 0
	_samples = 0
	_instability = 0.0
	_hit_counter = 0
	_conductions = 0


## Aplica ajustes dos marcos: chaves `X_add` somam, `X_mult` multiplicam e as demais substituem.
func configure(adjustments: Dictionary) -> void:
	params = DEFAULTS.duplicate()
	for raw_key: Variant in adjustments:
		var key := String(raw_key)
		var value: Variant = adjustments[raw_key]
		if key.ends_with("_add"):
			var target := key.trim_suffix("_add")
			params[target] = _typed(target, float(params.get(target, 0.0)) + float(value))
		elif key.ends_with("_mult"):
			var target := key.trim_suffix("_mult")
			params[target] = _typed(target, float(params.get(target, 0.0)) * float(value))
		else:
			params[key] = _typed(key, value)


func _typed(key: String, value: Variant) -> Variant:
	return int(round(float(value))) if DEFAULTS.get(key) is int else float(value)


func _p(key: String) -> float:
	return float(params.get(key, 0.0))


func tick(delta: float) -> void:
	_clock += delta
	for collection: Array[Dictionary] in [_residues, _opportunities]:
		for index in range(collection.size() - 1, -1, -1):
			collection[index]["ttl"] = float(collection[index]["ttl"]) - delta
			if float(collection[index]["ttl"]) <= 0.0:
				collection.remove_at(index)


## Acerto em inimigo. Devolve pedidos extras (por exemplo Fôlego ao descartar resíduo).
func on_enemy_hit(position: Vector2, near_obstacle: bool) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	match passive_id:
		&"luz_residual":
			if _residues.size() >= int(params["max_residues"]):
				_residues.pop_front()
				if _p("discard_breath") > 0.0:
					requests.append({"type": "breath", "amount": _p("discard_breath")})
			_residues.append({"position": position, "ttl": _p("residue_lifetime")})
		&"oportunidade_estrutural":
			_hit_counter += 1
			if (near_obstacle or _hit_counter % maxi(1, int(params["hits_per_opportunity"])) == 0) and _opportunities.size() < int(params["max_opportunities"]):
				_opportunities.append({"position": position, "ttl": _p("opportunity_lifetime")})
	return requests


## Chamado antes de executar uma Gema Ativa. Devolve multiplicadores da execução e pedidos extras.
## `free` dispensa custo e recarga; `echo` repete a gema com a fração indicada de potência.
func on_skill_used(slot: int) -> Dictionary:
	var result := {"power_multiplier": 1.0, "breath_multiplier": 1.0, "free": false, "echo": 0.0, "requests": [] as Array[Dictionary]}
	var requests := result["requests"] as Array[Dictionary]
	match passive_id:
		&"luz_residual":
			if not _residues.is_empty():
				var origins: Array[Vector2] = []
				var center := Vector2.ZERO
				for residue in _residues:
					origins.append(residue["position"] as Vector2)
					center += residue["position"] as Vector2
				center /= float(_residues.size())
				if _p("overload_power") > 0.0:
					result["power_multiplier"] = 1.0 + _p("overload_power") * float(_residues.size())
					result["breath_multiplier"] = 1.25
				if _p("constellation_damage") > 0.0 and _residues.size() >= 3:
					requests.append({"type": "nova", "position": center, "radius": 110.0, "amount": _p("constellation_damage")})
				_residues.clear()
				_conductions += 1
				var amount := _p("conduct_amount")
				requests.append({"type": "conduct", "origins": origins, "amount": amount, "range": _p("conduct_range")})
				var memory := int(params["memory_every"])
				if _p("conduct_return") > 0.0 or (memory > 0 and _conductions % memory == 0):
					var ratio := maxf(_p("conduct_return"), 1.0 if memory > 0 and _conductions % memory == 0 else 0.0)
					requests.append({"type": "conduct", "origins": origins, "amount": amount * ratio, "range": _p("conduct_range")})
				if _p("conduct_barrier") > 0.0:
					requests.append({"type": "barrier", "amount": _p("conduct_barrier")})
		&"duas_correntes":
			var maximum := int(params["max_currents"])
			var was_max_deviation := _deviated >= maximum
			if _last_slot >= 0 and slot == _last_slot:
				if _traced >= maximum and _p("trace_echo") > 0.0:
					result["echo"] = _p("trace_echo")
				_traced = mini(maximum, _traced + 1)
				if int(params["dual_flow"]) == 0:
					_deviated = maxi(0, _deviated - 1)
			elif _last_slot >= 0:
				if _p("shift_free") > 0.0 and _traced >= 2:
					_deviated = mini(maximum, _deviated + _traced)
					_traced = 0
					result["free"] = true
				else:
					_deviated = mini(maximum, _deviated + 1)
					_traced = maxi(0, _traced - int(params["trace_loss"]))
					if int(params["dual_flow"]) > 0:
						_traced = mini(maximum, _traced + 1)
				if was_max_deviation and _p("improv_echo") > 0.0:
					result["echo"] = _p("improv_echo")
				if was_max_deviation and _p("emergency_free") > 0.0:
					result["free"] = true
			_last_slot = slot
			result["power_multiplier"] = 1.0 + _p("trace_power") * float(_traced)
			result["breath_multiplier"] = maxf(0.0, 1.0 - _p("deviation_breath") * float(_deviated))
			if _p("route_barrier") > 0.0 and _traced > 0:
				requests.append({"type": "ally_barrier", "amount": _p("route_barrier") * float(_traced), "radius": 180.0})
		&"placas_adaptativas":
			if _samples > 0:
				if int(params["sample_keep"]) == 0:
					_samples -= 1
				_instability = maxf(0.0, _instability - 15.0)
				result["power_multiplier"] = 1.0 + _p("sample_power")
			if _p("cast_discharge") > 0.0 and _instability >= 50.0:
				_instability -= 50.0
				requests.append({"type": "nova", "radius": _p("discharge_radius") * 0.8, "amount": _p("discharge_amount") * _p("cast_discharge")})
	return result


## Chamado quando a personagem sofre dano já descontada a barreira.
func on_damage_taken(amount: float, health_ratio: float = 1.0) -> Dictionary:
	var result := {"amount": amount, "requests": [] as Array[Dictionary]}
	var requests := result["requests"] as Array[Dictionary]
	if amount <= 0.0:
		return result
	match passive_id:
		&"luz_residual":
			if _p("prism_barrier") > 0.0 and _residues.size() >= int(params["max_residues"]) and amount >= 10.0:
				_residues.clear()
				requests.append({"type": "barrier", "amount": _p("prism_barrier")})
				requests.append({"type": "nova", "radius": 120.0, "amount": _p("prism_barrier")})
		&"duas_correntes":
			if _p("counter_damage") > 0.0 and _traced > 0:
				requests.append({"type": "nova", "radius": 100.0, "amount": _p("counter_damage") * float(_traced)})
		&"placas_adaptativas":
			if _samples > 0:
				result["amount"] = amount * (1.0 - _p("sample_reduction"))
			if _p("crisis_absorb") > 0.0 and health_ratio < 0.35:
				var absorbed := float(result["amount"]) * _p("crisis_absorb")
				result["amount"] = float(result["amount"]) - absorbed
				_instability += absorbed
			if _samples < int(params["max_samples"]):
				_samples += 1
				if _p("sample_barrier") > 0.0:
					requests.append({"type": "barrier", "amount": _p("sample_barrier")})
			_instability = minf(100.0, _instability + amount * _p("instability_gain"))
			if _instability >= 100.0:
				_instability = 100.0 * _p("discharge_keep")
				_samples = 0
				requests.append({"type": "nova", "radius": _p("discharge_radius"), "amount": _p("discharge_amount")})
	return result


func on_player_moved(position: Vector2) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	if passive_id != &"oportunidade_estrutural":
		return requests
	for index in range(_opportunities.size() - 1, -1, -1):
		var spot := _opportunities[index]["position"] as Vector2
		if spot.distance_to(position) > OPPORTUNITY_PICKUP_RADIUS:
			continue
		_opportunities.remove_at(index)
		requests.append({"type": "barrier", "amount": _p("opportunity_barrier")})
		requests.append({"type": "nova", "position": spot, "radius": _p("opportunity_radius"), "amount": _p("opportunity_damage")})
		if _p("opportunity_breath") > 0.0:
			requests.append({"type": "breath", "amount": _p("opportunity_breath")})
		if _p("collapse_chain") > 0.0:
			for other in _opportunities:
				if (other["position"] as Vector2).distance_to(spot) <= 160.0:
					requests.append({"type": "nova", "position": other["position"], "radius": _p("opportunity_radius") * 0.7, "amount": _p("opportunity_damage") * _p("collapse_chain")})
		_recent_pickups.append(_clock)
		while not _recent_pickups.is_empty() and _clock - _recent_pickups[0] > 6.0:
			_recent_pickups.pop_front()
		if _p("pickup_summon") > 0.0:
			requests.append({"type": "summon", "position": spot, "duration": _p("pickup_summon")})
		if _p("city_damage") > 0.0 and _recent_pickups.size() >= maxi(1, int(params["city_threshold"])):
			_recent_pickups.clear()
			requests.append({"type": "nova", "position": spot, "radius": 170.0, "amount": _p("city_damage")})
	return requests


func move_speed_multiplier() -> float:
	return 1.0 + _p("deviation_speed") * float(_deviated) if passive_id == &"duas_correntes" else 1.0


func markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for residue in _residues:
		result.append({"kind": "residue", "position": residue["position"], "ttl": residue["ttl"]})
	for spot in _opportunities:
		result.append({"kind": "opportunity", "position": spot["position"], "ttl": spot["ttl"]})
	return result


func display() -> Dictionary:
	match passive_id:
		&"luz_residual":
			return {"name": display_name, "label": "RESIDUOS", "value": float(_residues.size()), "maximum": float(params["max_residues"]), "color": Color("7fd6e0")}
		&"duas_correntes":
			return {"name": display_name, "label": "TRACADO %d  DESVIO %d" % [_traced, _deviated], "value": float(_traced), "maximum": float(params["max_currents"]), "secondary": float(_deviated), "color": Color("e8b84a")}
		&"placas_adaptativas":
			var label := "AMOSTRA" if _samples == 1 else ("AMOSTRAS %d" % _samples if _samples > 1 else "INSTABILIDADE")
			return {"name": display_name, "label": label, "value": _instability, "maximum": 100.0, "color": Color("8a5f9e"), "flag": _samples > 0}
		&"oportunidade_estrutural":
			return {"name": display_name, "label": "OPORTUNIDADES", "value": float(_opportunities.size()), "maximum": float(params["max_opportunities"]), "color": Color("d9824a")}
	return {"name": display_name, "label": "", "value": 0.0, "maximum": 1.0, "color": Color.WHITE}


func residue_count() -> int:
	return _residues.size()


func opportunity_count() -> int:
	return _opportunities.size()


func has_sample() -> bool:
	return _samples > 0


func sample_count() -> int:
	return _samples


func instability() -> float:
	return _instability


func currents() -> Vector2i:
	return Vector2i(_traced, _deviated)
