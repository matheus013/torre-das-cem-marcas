extends RefCounted

## Relógio do mundo (épico E1, fase 3; G8.1; documento 76, seção 1; decisão 597). Um dia dura 2 horas
## de jogo: manhã 30 min, tarde 30, entardecer 20 e noite 40. Corre na vila e na Torre e para junto
## com a simulação (pausa de marco). O host é a fonte; clientes recebem a hora no snapshot; fica no
## save. A cada 3 noites a noite é de Lua da Cicatriz.

const PERIODS: Array[String] = ["manha", "tarde", "entardecer", "noite"]
const PERIOD_LABELS := {"manha": "Manha", "tarde": "Tarde", "entardecer": "Entardecer", "noite": "Noite"}
## Segundos de cada período, na ordem de PERIODS.
const PERIOD_SECONDS: Array[float] = [1800.0, 1800.0, 1200.0, 2400.0]
const DAY_SECONDS := 7200.0
const SCAR_MOON_EVERY := 3
## Aviso antes de anoitecer e de amanhecer.
const WARNING_SECONDS := 60.0
## Noite (decisão 597): EXP +25%, saque +30%, Vida e dano dos inimigos +10%. Na Lua da Cicatriz os
## bônus dobram até as marés da fase 4 (valores provisórios).
const NIGHT := {"exp": 1.25, "loot": 1.3, "enemy": 1.1}
const SCAR_MOON := {"exp": 1.5, "loot": 1.6, "enemy": 1.2}
const DAY := {"exp": 1.0, "loot": 1.0, "enemy": 1.0}

## Segundos desde o início do dia atual (0 = começo da manhã).
var time := 0.0
## Dia corrente, a partir de 1.
var day := 1


## Avança o relógio e devolve os eventos na ordem: {"type": "warning"|"period", "period": ...}.
func step(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if delta <= 0.0:
		return events
	var remaining := delta
	# Passos grandes (salto de tempo) atravessam vários limites; cada um gera o próprio evento.
	while remaining > 0.0:
		var to_boundary := seconds_to_next_period()
		var to_warning := to_boundary - WARNING_SECONDS
		if to_warning > 0.0 and remaining >= to_warning and _warns_before(next_period()):
			_advance(to_warning)
			remaining -= to_warning
			events.append({"type": "warning", "period": next_period()})
			continue
		if remaining < to_boundary:
			_advance(remaining)
			break
		_advance(to_boundary)
		remaining -= to_boundary
		events.append({"type": "period", "period": period(), "scar_moon": is_scar_moon()})
	return events


func _advance(seconds: float) -> void:
	time += seconds
	while time >= DAY_SECONDS - 0.0001:
		time -= DAY_SECONDS
		day += 1
	time = maxf(0.0, time)


func _warns_before(next: String) -> bool:
	return next in ["noite", "manha"]


func period_index() -> int:
	var elapsed := 0.0
	for index in range(PERIODS.size()):
		elapsed += PERIOD_SECONDS[index]
		if time < elapsed - 0.0001:
			return index
	return PERIODS.size() - 1


func period() -> String:
	return PERIODS[period_index()]


func next_period() -> String:
	return PERIODS[(period_index() + 1) % PERIODS.size()]


func period_start(index: int) -> float:
	var result := 0.0
	for previous in range(index):
		result += PERIOD_SECONDS[previous]
	return result


func seconds_to_next_period() -> float:
	var index := period_index()
	return maxf(0.0, period_start(index) + PERIOD_SECONDS[index] - time)


func is_night() -> bool:
	return period() == "noite"


## A noite do dia 3, 6, 9... é de Lua da Cicatriz.
func is_scar_moon() -> bool:
	return is_night() and day % SCAR_MOON_EVERY == 0


func bonuses() -> Dictionary:
	return SCAR_MOON if is_scar_moon() else (NIGHT if is_night() else DAY)


## Leva o relógio ao início de um período (desenvolvimento, testes e capturas).
func set_period(period_id: String) -> void:
	var index := PERIODS.find(period_id)
	if index >= 0:
		time = period_start(index)


## Hora no estilo de relógio: o dia de 2 h vira 24 h (manhã às 6:00).
func clock_text() -> String:
	var hours := fmod(6.0 + time / DAY_SECONDS * 24.0, 24.0)
	return "%02d:%02d" % [int(hours), int(fmod(hours, 1.0) * 60.0)]


func view() -> Dictionary:
	return {
		"time": time, "day": day, "period": period(), "next_period": next_period(),
		"seconds_to_next": seconds_to_next_period(), "night": is_night(), "scar_moon": is_scar_moon(),
		"clock": clock_text(),
	}


## Texto do relógio para HUD e menus: "DIA 3 · 22:40 NOITE · AMANHECE EM 12 MIN".
static func describe(view: Dictionary) -> String:
	if view.is_empty():
		return ""
	var next := String(view.get("next_period", ""))
	var minutes := int(ceil(float(view.get("seconds_to_next", 0.0)) / 60.0))
	var turn := {"noite": "ANOITECE", "manha": "AMANHECE"}.get(next, String(PERIOD_LABELS.get(next, next)).to_upper()) as String
	var text := "DIA %d · %s %s · %s EM %d MIN" % [int(view.get("day", 1)), String(view.get("clock", "")), String(PERIOD_LABELS.get(String(view.get("period", "")), "")).to_upper(), turn, maxi(1, minutes)]
	if bool(view.get("scar_moon", false)):
		text += " · LUA DA CICATRIZ"
	return text


func save() -> Dictionary:
	return {"time": time, "day": day}


func restore(data: Dictionary) -> void:
	time = clampf(float(data.get("time", 0.0)), 0.0, DAY_SECONDS - 0.001)
	day = maxi(1, int(data.get("day", 1)))
