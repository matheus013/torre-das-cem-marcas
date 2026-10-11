class_name IntentGuard
extends RefCounted

## Guarda de comandos do host (G0.6, épico E1 fase 0). Antes de qualquer chamada à simulação:
## - argumentos sanos: vetores finitos e dentro do mundo, inteiros e textos com limites;
## - frequência: cada jogador remoto tem um balde de fichas por tipo de comando, para que um cliente
##   com defeito ou malicioso não inunde o host. O host local não passa pelo limite.

## Comandos por segundo (também o tamanho do balde: até 1 s de rajada).
const RATES := {"move": 120.0, "attack": 30.0, "skill": 20.0, "quick": 10.0, "default": 15.0}
const MAX_COORDINATE := 100000.0
const MAX_INTEGER := 100000
const MAX_TEXT := 64
const MAX_ARGS := 4

var _buckets: Dictionary = {}


## Argumentos aceitáveis para qualquer comando: até 4 valores, cada um bool, inteiro, texto curto
## ou vetor finito dentro do mundo.
static func valid_args(args: Array) -> bool:
	if args.size() > MAX_ARGS:
		return false
	for value: Variant in args:
		if value is bool:
			continue
		if value is int:
			if absi(int(value)) > MAX_INTEGER:
				return false
		elif value is String or value is StringName:
			if String(value).length() > MAX_TEXT:
				return false
		elif value is Vector2:
			if not valid_vector(value):
				return false
		else:
			return false
	return true


static func valid_vector(value: Variant) -> bool:
	if not value is Vector2:
		return false
	var vector := value as Vector2
	return vector.is_finite() and absf(vector.x) <= MAX_COORDINATE and absf(vector.y) <= MAX_COORDINATE


## Consome uma ficha do balde do jogador para este tipo de comando; falso se esgotou.
func allow(peer_id: int, kind: String, now: float) -> bool:
	var rate := float(RATES.get(kind, RATES["default"]))
	var peer := _buckets.get_or_add(peer_id, {}) as Dictionary
	var bucket := peer.get_or_add(kind, {"tokens": rate, "time": now}) as Dictionary
	bucket["tokens"] = minf(rate, float(bucket["tokens"]) + maxf(0.0, now - float(bucket["time"])) * rate)
	bucket["time"] = now
	if float(bucket["tokens"]) < 1.0:
		return false
	bucket["tokens"] = float(bucket["tokens"]) - 1.0
	return true


func forget(peer_id: int) -> void:
	_buckets.erase(peer_id)
