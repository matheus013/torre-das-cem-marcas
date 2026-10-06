class_name VillageLife
extends RefCounted

## Moradores de Aresta (decisão 560). O host decide; clientes só recebem posição, ação e fala.
## Modo padrão: Utility AI determinística da NpcMind (ADR 0006) escolhe entre ações válidas e uma
## fala autoral é composta com fatos verdadeiros. Modo com IA: os moradores nomeados enviam ao
## modelo configurado a mesma lista fechada de ações; a resposta só é aceita se escolher uma delas,
## e a fala é limitada em tamanho. Sem resposta a tempo, a decisão padrão assume.

const NpcMindScript := preload("res://src/simulation/npc/npc_mind.gd")
const ContextScript := preload("res://src/simulation/npc/npc_decision_context.gd")
const OptionScript := preload("res://src/simulation/npc/npc_decision_option.gd")
const CONTENT_PATH := "res://data/village/village_content.json"
const PERIODS: Array[String] = ["manha", "tarde", "entardecer", "noite"]
const PERIOD_LABELS := {"manha": "Manha", "tarde": "Tarde", "entardecer": "Entardecer", "noite": "Noite"}
const SPEED := 48.0
const TALK_RADIUS := 95.0
const GREET_RADIUS := 300.0
const CHAT_RADIUS := 520.0
const SPEECH_SECONDS := 6.0
const AI_TIMEOUT := 9.0
const AI_INTERVAL := 25.0
const MAX_SPEECH := 160
const LOG_SIZE := 8

var npcs: Array[Dictionary] = []
var period_index := 0
var mode := "padrao"
var log: Array[Dictionary] = []
var _spots: Dictionary = {}
var _random := RandomNumberGenerator.new()
var _requests: Dictionary = {}
var _request_sequence := 1
var _outbox: Array[Dictionary] = []
var economy := preload("res://src/simulation/npc/village_economy.gd").new()
var _navigation := preload("res://src/simulation/npc/village_navigation.gd").new()


## `spots` traz os pontos do mapa: "work" (por local de trabalho), "homes", "social" e "patrol".
func setup(seed: int, spots: Dictionary) -> void:
	_random.seed = seed
	_spots = spots
	economy.setup(spots)
	_navigation.setup(spots.get("size", Vector2(3840, 2400)), spots.get("blocked", []))
	npcs.clear()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	var homes := spots.get("homes", [Vector2(400.0, 700.0)]) as Array
	var index := 0
	for raw: Variant in (parsed as Dictionary).get("npcs", []) if parsed is Dictionary else []:
		var definition := raw as Dictionary
		var mind: RefCounted = NpcMindScript.new(StringName(String(definition["id"])))
		for key: Variant in definition.get("traits", {}) as Dictionary:
			mind.call("set_trait", StringName(String(key)), float((definition["traits"] as Dictionary)[key]))
		for key: Variant in definition.get("values", {}) as Dictionary:
			mind.call("set_value", StringName(String(key)), float((definition["values"] as Dictionary)[key]))
		mind.call("set_need", &"repouso", 0.3)
		mind.call("set_need", &"pertencimento", 0.5)
		var work := _work_spot(String(definition.get("work", "praca")), index)
		var home := (spots.get("home_by_id", {}) as Dictionary).get(String(definition["id"]), homes[index % homes.size()]) as Vector2
		var routine := String(definition.get("routine", "roaming"))
		if routine == "resident":
			work = home
		npcs.append({
			"id": String(definition["id"]), "name": String(definition["name"]), "title": String(definition.get("title", "")),
			"named": bool(definition.get("named", false)), "sprite": String(definition.get("sprite", "")),
			"work_key": String(definition.get("work", "praca")), "work": work, "home": home,
			"personality": String(definition.get("personality", "")), "opinions": String(definition.get("opinions", "")),
			"position": work + Vector2(_random.randf_range(-30.0, 30.0), _random.randf_range(-20.0, 20.0)),
			"target": work, "action": "trabalhar", "action_label": "trabalhando", "action_timer": _random.randf_range(2.0, 10.0),
			"speech": "", "speech_ttl": 0.0, "facing_left": false, "moving": false, "mind": mind,
			"pending": 0, "ai_timer": _random.randf_range(4.0, AI_INTERVAL), "partner": "",
			"routine": routine, "resource": String(definition.get("resource", "")),
			"cargo": 0, "job_phase": "buscar", "work_timer": 0.0,
		})
		if routine in ["resident", "stationary"]:
			npcs.back()["position"] = work
		index += 1


func period() -> String:
	return PERIODS[period_index % PERIODS.size()]


## O tempo de Aresta avança por ações (decisão 20): cada retorno de expedição passa um período.
func advance_period() -> void:
	period_index = (period_index + 1) % PERIODS.size()
	for npc in npcs:
		npc["action_timer"] = _random.randf_range(0.5, 4.0)


## Lembrança compartilhada: a Casa das Expedições divulga relatórios, então todos os nomeados sabem.
func remember_event(tag: String, text: String, impact: float, target: String = "") -> void:
	for npc in npcs:
		if not bool(npc["named"]):
			continue
		var mind := npc["mind"] as RefCounted
		mind.call("remember", StringName(tag), StringName(target), impact, 0)
		var facts := npc.get("facts", []) as Array
		facts.append(text)
		while facts.size() > 6:
			facts.pop_front()
		npc["facts"] = facts


## `context` traz `players` ({peer: {name, position}}) e `world` (fatos verdadeiros do mundo).
func step(delta: float, context: Dictionary) -> void:
	var players := context.get("players", {}) as Dictionary
	economy.step(delta)
	for npc in npcs:
		npc["speech_ttl"] = maxf(0.0, float(npc["speech_ttl"]) - delta)
		if float(npc["speech_ttl"]) <= 0.0:
			npc["speech"] = ""
		_move(npc, delta)
		if not String(npc["resource"]).is_empty():
			if float(npc["speech_ttl"]) <= 0.0:
				economy.worker_step(npc, delta, period() == "noite")
			continue
		npc["action_timer"] = float(npc["action_timer"]) - delta
		npc["ai_timer"] = float(npc["ai_timer"]) - delta
		var pending := int(npc["pending"])
		if pending > 0 and _requests.has(pending) and float((_requests[pending] as Dictionary)["deadline"]) <= Time.get_ticks_msec() / 1000.0:
			_fallback(pending, context)
		if float(npc["action_timer"]) > 0.0 or pending > 0:
			continue
		var situation := {"kind": "rotina"}
		var candidates := _candidates(npc, players, context.get("world", {}) as Dictionary, situation)
		if mode == "ia" and bool(npc["named"]) and float(npc["ai_timer"]) <= 0.0 and not players.is_empty():
			npc["ai_timer"] = AI_INTERVAL + _random.randf_range(0.0, 10.0)
			_request_model(npc, candidates, situation, context)
			npc["action_timer"] = 2.0
			continue
		_apply(npc, _choose_default(npc, candidates), "", context)


## Jogador inicia conversa (tecla E). Responde na hora no modo padrão, ou pede ao modelo.
func talk(npc_id: String, peer_id: int, context: Dictionary) -> bool:
	var npc := find(npc_id)
	var players := context.get("players", {}) as Dictionary
	if npc.is_empty() or not players.has(peer_id):
		return false
	if ((players[peer_id] as Dictionary)["position"] as Vector2).distance_to(npc["position"] as Vector2) > TALK_RADIUS * 1.6:
		return false
	var situation := {"kind": "conversa", "peer": peer_id, "speaker": String((players[peer_id] as Dictionary)["name"])}
	var candidates := _talk_candidates(npc, peer_id, context.get("world", {}) as Dictionary)
	npc["target"] = npc["position"]
	(npc["mind"] as RefCounted).call("remember", &"conversa", StringName(str(peer_id)), 0.2, 0)
	if mode == "ia" and bool(npc["named"]):
		_request_model(npc, candidates, situation, context)
		npc["speech"] = "..."
		npc["speech_ttl"] = AI_TIMEOUT
		return true
	_apply(npc, _choose_default(npc, candidates), "", context)
	return true


func find(npc_id: String) -> Dictionary:
	for npc in npcs:
		if String(npc["id"]) == npc_id:
			return npc
	return {}


func nearest(position: Vector2, radius: float) -> Dictionary:
	var best := {}
	var best_distance := radius
	for npc in npcs:
		var distance := position.distance_to(npc["position"] as Vector2)
		if distance <= best_distance:
			best_distance = distance
			best = npc
	return best


## Pedidos ao modelo prontos para envio (lidos pelo cliente de IA do host).
func drain_requests() -> Array[Dictionary]:
	var result := _outbox.duplicate()
	_outbox.clear()
	return result


## Resposta do modelo: aceita só ação da lista enviada; fala é limpa e limitada.
func resolve_request(request_id: int, action_id: String, speech: String, context: Dictionary) -> bool:
	if not _requests.has(request_id):
		return false
	var request := _requests[request_id] as Dictionary
	_requests.erase(request_id)
	var npc := find(String(request["npc"]))
	if npc.is_empty():
		return false
	npc["pending"] = 0
	var chosen := {}
	for candidate: Dictionary in request["candidates"]:
		if String(candidate["id"]) == action_id:
			chosen = candidate
	if chosen.is_empty():
		_apply(npc, _choose_default(npc, request["candidates"] as Array), "", context)
		return false
	var clean := speech.strip_edges().replace("\n", " ").replace("\"", "")
	if clean.length() > MAX_SPEECH:
		clean = clean.substr(0, MAX_SPEECH - 3) + "..."
	_apply(npc, chosen, clean, context)
	return true


func _fallback(request_id: int, context: Dictionary) -> void:
	var request := _requests[request_id] as Dictionary
	_requests.erase(request_id)
	var npc := find(String(request["npc"]))
	if npc.is_empty():
		return
	npc["pending"] = 0
	_apply(npc, _choose_default(npc, request["candidates"] as Array), "", context)


# ---------------------------------------------------------------- candidatos e decisão

func _candidates(npc: Dictionary, players: Dictionary, world: Dictionary, situation: Dictionary) -> Array:
	if String(npc["routine"]) in ["resident", "stationary"]:
		return [_option("trabalhar", "Permanecer no seu local", 8.0, {}, {})]
	var current := period()
	var result: Array = []
	var work_weight := {"manha": 6.0, "tarde": 5.0, "entardecer": 2.0, "noite": 0.5}.get(current, 3.0) as float
	result.append(_option("trabalhar", "Ir ao trabalho (%s)" % String(npc["work_key"]), work_weight, {"ambition": 2.0}, {"dever": 3.0}))
	result.append(_option("passear", "Passear pela praca", {"manha": 1.5, "tarde": 2.5, "entardecer": 4.0, "noite": 1.0}.get(current, 2.0) as float, {"impulsivity": 2.0, "empathy": 1.0}, {"pertencimento": 1.0}))
	result.append(_option("descansar", "Voltar para casa e descansar", {"manha": 0.3, "tarde": 0.5, "entardecer": 2.5, "noite": 7.0}.get(current, 1.0) as float, {"caution": 1.5}, {}))
	if String(npc["work_key"]) == "posto_guarda":
		result.append(_option("vigiar", "Fazer a ronda da guarda", work_weight + 1.5, {"courage": 2.0}, {"dever": 3.0}))
	var partner := _chat_partner(npc)
	if not partner.is_empty():
		var option := _option("conversar:%s" % partner["id"], "Conversar com %s" % partner["name"], 3.0, {"empathy": 3.0, "impulsivity": 1.0}, {"pertencimento": 2.0})
		result.append(option)
	for peer_id: Variant in players:
		var state := players[peer_id] as Dictionary
		if (state["position"] as Vector2).distance_to(npc["position"] as Vector2) <= GREET_RADIUS:
			result.append(_option("cumprimentar:%s" % str(peer_id), "Cumprimentar %s" % String(state["name"]), 3.5 if bool(npc["named"]) else 2.0, {"empathy": 3.0, "courage": 1.0}, {"vila": 1.0}))
			if bool(npc["named"]) and not (npc.get("facts", []) as Array).is_empty():
				result.append(_option("comentar:%s" % str(peer_id), "Comentar com %s as noticias da Torre" % String(state["name"]), 3.0, {"empathy": 1.5, "ambition": 1.0}, {"conhecimento": 2.0}))
			break
	return result


func _talk_candidates(npc: Dictionary, peer_id: int, world: Dictionary) -> Array:
	var result: Array = []
	result.append(_option("responder", "Responder com cordialidade", 5.0, {"empathy": 3.0}, {"vila": 1.0}))
	result.append(_option("noticia", "Contar o que sabe sobre a Torre e a vila", 4.0, {"empathy": 1.0, "ambition": 1.0}, {"conhecimento": 3.0}))
	result.append(_option("pedido", "Pedir ajuda com algo do seu oficio", 3.5, {"ambition": 2.5}, {"dever": 2.0}))
	result.append(_option("conselho", "Dar um conselho sobre a proxima descida", 3.0, {"caution": 3.0}, {"vila": 1.5}))
	result.append(_option("encerrar", "Encerrar a conversa com educacao", 1.0, {"caution": 1.0}, {}))
	for option: Dictionary in result:
		option["target"] = str(peer_id)
	return result


func _option(id: String, label: String, base: float, traits: Dictionary, values: Dictionary) -> Dictionary:
	return {"id": id, "label": label, "base": base, "traits": traits, "values": values}


func _choose_default(npc: Dictionary, candidates: Array) -> Dictionary:
	var mind := npc["mind"] as RefCounted
	var options: Array[NpcDecisionOption] = []
	for candidate: Dictionary in candidates:
		var option: NpcDecisionOption = OptionScript.new(StringName(String(candidate["id"])))
		option.base_score = float(candidate["base"]) + _random.randf_range(0.0, 0.8)
		for key: Variant in candidate["traits"]:
			option.trait_weights[StringName(String(key))] = float(candidate["traits"][key])
		for key: Variant in candidate["values"]:
			option.value_weights[StringName(String(key))] = float(candidate["values"][key])
		options.append(option)
	var context: NpcDecisionContext = ContextScript.new()
	var chosen: NpcDecisionOption = mind.call("choose_action", options, context)
	for candidate: Dictionary in candidates:
		if chosen != null and String(candidate["id"]) == String(chosen.id):
			return candidate
	return candidates[0] if not candidates.is_empty() else {}


func _chat_partner(npc: Dictionary) -> Dictionary:
	for other in npcs:
		if String(other.get("routine", "roaming")) in ["resident", "stationary"] or not String(other.get("resource", "")).is_empty():
			continue
		if other == npc or String(other["action"]).begins_with("conversar"):
			continue
		if (other["position"] as Vector2).distance_to(npc["position"] as Vector2) <= CHAT_RADIUS:
			return other
	return {}


# ---------------------------------------------------------------- execução

func _apply(npc: Dictionary, candidate: Dictionary, model_speech: String, context: Dictionary) -> void:
	if candidate.is_empty():
		return
	var action := String(candidate["id"])
	var kind := action.get_slice(":", 0)
	var argument := action.get_slice(":", 1) if action.contains(":") else String(candidate.get("target", ""))
	var players := context.get("players", {}) as Dictionary
	npc["action"] = action
	npc["action_timer"] = _random.randf_range(8.0, 18.0)
	match kind:
		"trabalhar":
			npc["target"] = npc["work"] if String(npc["routine"]) in ["resident", "stationary"] else (npc["work"] as Vector2) + Vector2(_random.randf_range(-18.0, 18.0), _random.randf_range(0.0, 12.0))
			npc["action_label"] = "trabalhando"
		"vigiar":
			var patrol := _spots.get("patrol", [npc["work"]]) as Array
			npc["target"] = patrol[_random.randi_range(0, patrol.size() - 1)]
			npc["action_label"] = "de ronda"
			npc["action_timer"] = _random.randf_range(5.0, 9.0)
		"passear":
			var social := _spots.get("social", [npc["work"]]) as Array
			npc["target"] = (social[_random.randi_range(0, social.size() - 1)] as Vector2) + Vector2(_random.randf_range(-50.0, 50.0), _random.randf_range(-30.0, 30.0))
			npc["action_label"] = "passeando"
		"descansar":
			npc["target"] = npc["home"]
			npc["action_label"] = "em casa"
		"conversar":
			var partner := find(argument)
			if not partner.is_empty():
				npc["target"] = (partner["position"] as Vector2) + Vector2(36.0, 0.0)
				partner["target"] = partner["position"]
				partner["action"] = "conversar:%s" % npc["id"]
				partner["action_timer"] = npc["action_timer"]
				partner["action_label"] = "conversando"
				npc["partner"] = argument
			npc["action_label"] = "conversando"
		"cumprimentar", "comentar":
			if players.has(int(argument)):
				var spot := (players[int(argument)] as Dictionary)["position"] as Vector2
				npc["target"] = spot + ((npc["position"] as Vector2) - spot).normalized() * 50.0
			npc["action_label"] = "conversando"
			npc["action_timer"] = _random.randf_range(6.0, 10.0)
		_:
			npc["target"] = npc["position"]
			npc["action_label"] = "conversando"
	if String(npc["routine"]) in ["resident", "stationary"]:
		npc["target"] = npc["work"]
	var speech := model_speech if not model_speech.is_empty() else _authored_line(npc, kind, argument, context)
	if not speech.is_empty():
		_say(npc, speech, model_speech.is_empty())


func _say(npc: Dictionary, text: String, authored: bool) -> void:
	npc["speech"] = text
	npc["speech_ttl"] = SPEECH_SECONDS
	log.append({"npc": String(npc["name"]), "text": text, "source": "autoral" if authored else "modelo"})
	while log.size() > LOG_SIZE:
		log.pop_front()


func _move(npc: Dictionary, delta: float) -> void:
	var position := npc["position"] as Vector2
	var destination := npc["target"] as Vector2
	if destination != (npc.get("route_target", Vector2.INF) as Vector2):
		npc["route_target"] = destination
		npc["route"] = _navigation.route(position, destination)
	var route := npc.get("route", PackedVector2Array()) as PackedVector2Array
	while not route.is_empty() and position.distance_to(route[0]) <= 1.0:
		route.remove_at(0)
	npc["route"] = route
	var offset := (route[0] - position) if not route.is_empty() else Vector2.ZERO
	npc["moving"] = offset.length() > 0.5
	if not bool(npc["moving"]):
		return
	var speed := SPEED * (1.25 if String(npc["action"]).begins_with("vigiar") else 1.0)
	var step := offset.normalized() * minf(offset.length(), speed * delta)
	var next := position + step
	var blocked := _spots.get("blocked", []) as Array
	for rect: Rect2 in blocked:
		if rect.has_point(next):
			npc["moving"] = false
			npc["route_target"] = Vector2.INF
			return
	npc["position"] = next
	npc["facing_direction"] = step.normalized()
	if absf(step.x) > 0.05:
		npc["facing_left"] = step.x < 0.0


func _work_spot(work_key: String, index: int) -> Vector2:
	var work := _spots.get("work", {}) as Dictionary
	var base := work.get(work_key, work.get("praca", Vector2(900.0, 600.0))) as Vector2
	return base + Vector2(float(index % 3) * 26.0 - 26.0, float(index % 2) * 18.0)


# ---------------------------------------------------------------- falas autorais

## Falas compostas por intenção, personagem e fatos verdadeiros (documento 64).
func _authored_line(npc: Dictionary, kind: String, argument: String, context: Dictionary) -> String:
	var world := context.get("world", {}) as Dictionary
	var players := context.get("players", {}) as Dictionary
	var who := String((players.get(int(argument), {}) as Dictionary).get("name", "")) if argument.is_valid_int() else ""
	var facts := npc.get("facts", []) as Array
	var deepest := int(world.get("deepest_floor", 1))
	var named := bool(npc["named"])
	match kind:
		"cumprimentar":
			var greetings := ["Bom te ver inteira, %s.", "%s! A Torre te devolveu mais uma vez.", "Cuidado la embaixo, %s.", "Ola, %s. Aresta esta de pe gracas a voces."]
			return (greetings[_random.randi_range(0, greetings.size() - 1)] as String) % who if not who.is_empty() and (named or _random.randf() < 0.4) else ""
		"comentar", "noticia":
			if not facts.is_empty():
				return "Soube que %s." % String(facts[facts.size() - 1]).trim_suffix(".")
			return "O quadro ja chegou ao andar %d. Ninguem desceu tanto nesta geracao." % deepest
		"conversar":
			if not named:
				return _role_line(npc, world) if _random.randf() < 0.3 else ""
			var topics := ["Ouviu falar do andar %d?" % deepest, "A feira esta cheia hoje.", "A Regente quer relatorios completos.", "Dizem que a Torre mudou de novo."]
			return topics[_random.randi_range(0, topics.size() - 1)] if _random.randf() < 0.5 else ""
		"responder":
			return _role_line(npc, world)
		"pedido":
			return _request_line(npc, world)
		"conselho":
			return "Volte antes de esgotar o folego. Ninguem ganha nada com heroi caido."
		"encerrar":
			return "Preciso voltar ao trabalho. Ate logo, %s." % who
		"trabalhar":
			return _role_line(npc, world) if named and _random.randf() < 0.15 else ""
	return ""


func _role_line(npc: Dictionary, world: Dictionary) -> String:
	var deepest := int(world.get("deepest_floor", 1))
	var stone := int(world.get("banked_stone", 0))
	var lines := {
		"expedicoes": ["Relatorio na mesa: andar mais fundo %d. Quero o proximo ainda mais detalhado." % deepest, "Cada andar novo vira uma linha no meu mapa. Ja sao %d." % deepest, "Descam em grupo e voltem em grupo. E a unica regra que nao negocio."],
		"forja": ["Traga o material da Torre e eu digo se presta. Antes de usar, a gente entende.", "Metal que nao conheco nao entra na minha forja sem teste.", "Uma lamina mal temperada mata mais aventureiro que monstro."],
		"armazem": ["Pedra armazenada: %d. Isso e quase um contrato fechado." % stone, "Tudo tem preco em Aresta. Ate o que vem da Torre.", "Os compradores de fora pagam bem por material do Bosque."],
		"vigilia": ["A lei diz uma coisa; as consequencias, outra. Hoje estou ouvindo as duas.", "Fiscalizar nao e desconfiar. E lembrar que todos respondem a alguem.", "Poder de emergencia sem prazo vira poder permanente."],
		"posto_guarda": ["A entrada esta vigiada. Se algo subir da Torre, a guarda ve primeiro.", "Ja vi uma criatura profunda perto do portao. Nao quero ver outra.", "Volte antes de exaurir. A guarda nao desce para buscar ninguem."],
		"enfermaria": ["Se voltar ferido, venha direto aqui. Nada de esconder ferida.", "Substancia da Torre so entra no corpo depois de eu examinar.", "Descanse entre as descidas. Folego nao se compra."],
		"campos": ["O solo anda estranho. A Torre nao pode ser a unica coisa que nos alimenta.", "Colheita boa este ano, se a chuva ajudar.", "Uma vila que so come o que vem de baixo esta presa a Torre."],
		"obra": ["Com mais pedra regenerativa eu ergo reforcos que a vila inteira vai notar.", "Ja tenho %d pedras. Uma obra grande precisa de muito mais." % stone, "Fundacao primeiro, enfeite depois."],
		"arquivo": ["Todo mapa conta uma verdade. Alguns contam duas.", "Registre tudo que vir la embaixo. Ate o que parece inutil.", "Certas paginas sao lidas devagar por um bom motivo."],
		"conselho": ["Aresta precisa de expedicoes registradas, nao de lendas.", "A autonomia da vila depende de cada relatorio honesto.", "O conselho ouve resultados, nao promessas."],
		"casa_elen": ["Minha casa esta aberta para quem volta da Torre.", "Conte como foi la embaixo. Quero ouvir tudo.", "Deixei pao na mesa para o quadro de expedicao."],
		"feira": ["Fruta fresca! Mais barata que poção.", "Tecido bom para capa de expedicao!", "Hoje a feira esta cheia de gente de fora."],
		"praca": ["Eu vou ser aventureira quando crescer!", "Voce ja viu um monstro de verdade?", "A fonte fica mais bonita a noite."],
	}
	var options := lines.get(String(npc["work_key"]), ["Dia comum em Aresta. Ou quase.", "Boa sorte na Torre."]) as Array
	var pick := String(options[_random.randi_range(0, options.size() - 1)])
	if pick == String(npc.get("last_line", "")) and options.size() > 1:
		pick = String(options[(options.find(pick) + 1) % options.size()])
	npc["last_line"] = pick
	return pick


func _request_line(npc: Dictionary, world: Dictionary) -> String:
	match String(npc["work_key"]):
		"obra":
			return "Se puder, traga mais pedra regenerativa. A obra precisa."
		"forja":
			return "Quero ver um material do Bosque dos Ventos Presos. Traga um junco mineral."
		"expedicoes":
			return "Desca alem do andar %d e volte para contar." % int(world.get("deepest_floor", 1))
		"enfermaria":
			return "Traga ervas da Torre, se encontrar. A enfermaria esta no limite."
	return "Se encontrar algo estranho la embaixo, me conte primeiro."


# ---------------------------------------------------------------- modelo

func _request_model(npc: Dictionary, candidates: Array, situation: Dictionary, context: Dictionary) -> void:
	var request_id := _request_sequence
	_request_sequence += 1
	npc["pending"] = request_id
	var trimmed: Array = []
	for candidate: Dictionary in candidates:
		trimmed.append(candidate.duplicate(true))
	_requests[request_id] = {"npc": String(npc["id"]), "candidates": trimmed, "deadline": Time.get_ticks_msec() / 1000.0 + AI_TIMEOUT}
	_outbox.append({"id": request_id, "npc": String(npc["id"]), "system": _system_prompt(npc), "user": _user_prompt(npc, candidates, situation, context)})


func _system_prompt(npc: Dictionary) -> String:
	return ("Voce controla %s, %s, morador(a) da vila de Aresta, aos pes da Torre das Cem Marcas. " % [npc["name"], npc["title"]]
		+ "Personalidade: %s Opinioes publicas: %s " % [npc["personality"], npc["opinions"]]
		+ "Regras: escolha exatamente uma acao da lista pelo id; fale em portugues do Brasil, em primeira pessoa, "
		+ "com no maximo 140 caracteres; use apenas os fatos fornecidos; nunca invente acontecimentos, itens ou segredos. "
		+ "Responda somente com JSON no formato {\"acao\": \"id\", \"fala\": \"texto\"}.")


func _user_prompt(npc: Dictionary, candidates: Array, situation: Dictionary, context: Dictionary) -> String:
	var world := context.get("world", {}) as Dictionary
	var players := context.get("players", {}) as Dictionary
	var lines: Array[String] = []
	lines.append("Periodo: %s. Voce esta %s." % [PERIOD_LABELS.get(period(), period()), String(npc.get("action_label", ""))])
	var nearby: Array[String] = []
	for peer_id: Variant in players:
		var state := players[peer_id] as Dictionary
		if (state["position"] as Vector2).distance_to(npc["position"] as Vector2) <= GREET_RADIUS:
			nearby.append(String(state["name"]))
	lines.append("Perto de voce: %s." % (", ".join(PackedStringArray(nearby)) if not nearby.is_empty() else "ninguem do quadro de expedicao"))
	lines.append("Fatos da vila: andar mais fundo alcancado %d; pedra regenerativa armazenada %d; reforcos construidos %d." % [int(world.get("deepest_floor", 1)), int(world.get("banked_stone", 0)), int(world.get("village_progress", 0))])
	var facts := npc.get("facts", []) as Array
	if not facts.is_empty():
		lines.append("O que voce soube recentemente: %s." % "; ".join(PackedStringArray(facts)))
	if String(situation.get("kind", "")) == "conversa":
		lines.append("%s veio falar com voce agora." % String(situation.get("speaker", "Alguem")))
	lines.append("Acoes possiveis:")
	for candidate: Dictionary in candidates:
		lines.append("- %s: %s" % [candidate["id"], candidate["label"]])
	return "\n".join(PackedStringArray(lines))


# ---------------------------------------------------------------- rede e salvamento

func view() -> Array:
	var result: Array = []
	for npc in npcs:
		result.append({
			"id": npc["id"], "name": npc["name"], "title": npc["title"], "named": npc["named"], "sprite": npc["sprite"],
			"position": npc["position"], "facing_left": npc["facing_left"], "moving": npc["moving"],
			"facing_direction": npc.get("facing_direction", Vector2.DOWN),
			"speech": npc["speech"], "label": npc["action_label"], "thinking": int(npc["pending"]) > 0,
			"routine": npc["routine"], "resource": npc["resource"], "cargo": npc["cargo"],
		})
	return result


func snapshot() -> Dictionary:
	var minds := {}
	for npc in npcs:
		var mind := npc["mind"] as RefCounted
		minds[npc["id"]] = {"memories": (mind.get("memories") as Array).duplicate(true), "facts": (npc.get("facts", []) as Array).duplicate()}
	var workers := {}
	for npc in npcs:
		if not String(npc["resource"]).is_empty():
			workers[npc["id"]] = {"position": [npc["position"].x, npc["position"].y], "cargo": npc["cargo"], "job_phase": npc["job_phase"], "work_timer": npc["work_timer"]}
	return {"period": period_index, "minds": minds, "economy": economy.snapshot(), "workers": workers}


func restore(data: Dictionary) -> void:
	economy.restore(data.get("economy", {}) as Dictionary)
	for npc in npcs:
		var worker := (data.get("workers", {}) as Dictionary).get(npc["id"], {}) as Dictionary
		if String(npc["resource"]).is_empty() or worker.is_empty():
			continue
		var position := worker.get("position", []) as Array
		if position.size() == 2:
			var restored := Vector2(float(position[0]), float(position[1]))
			if Rect2(Vector2.ZERO, _spots.get("size", Vector2(3840, 2400))).has_point(restored):
				npc["position"] = restored
		npc["cargo"] = clampi(int(worker.get("cargo", 0)), 0, economy.LOAD)
		npc["job_phase"] = "entregar" if String(worker.get("job_phase", "")) == "entregar" else "buscar"
		npc["work_timer"] = clampf(float(worker.get("work_timer", 0.0)), 0.0, economy.WORK_SECONDS)
		npc["route_target"] = Vector2.INF
	period_index = clampi(int(data.get("period", 0)), 0, PERIODS.size() - 1)
	var minds := data.get("minds", {}) as Dictionary
	for npc in npcs:
		var saved := minds.get(npc["id"], {}) as Dictionary
		if saved.is_empty():
			continue
		var mind := npc["mind"] as RefCounted
		var memories := mind.get("memories") as Array
		memories.clear()
		for memory: Variant in saved.get("memories", []) as Array:
			if memory is Dictionary:
				var entry := (memory as Dictionary).duplicate()
				entry["tag"] = StringName(String(entry.get("tag", "")))
				entry["target_id"] = StringName(String(entry.get("target_id", "")))
				memories.append(entry)
		npc["facts"] = (saved.get("facts", []) as Array).duplicate()
