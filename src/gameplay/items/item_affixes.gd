class_name ItemAffixes
extends RefCounted

## Afixos aleatórios de equipamento (decisão 583). Cada peça sorteia, ao ser criada, afixos
## distintos conforme a raridade: comum 1, incomum 2, raro 3, épico 3, lendário 3 ou 4. O valor
## cresce com a raridade. `stat` soma ao atributo da peça; `mod` entra nos mesmos modificadores
## lidos por `_mod` (passivas e marcos): `_mult` multiplica, o resto soma.

const COUNT := {"common": [1, 1], "uncommon": [2, 2], "rare": [3, 3], "epic": [3, 3], "legendary": [3, 4]}
const SCALE := {"common": 1.0, "uncommon": 1.25, "rare": 1.5, "epic": 1.75, "legendary": 2.0}
const MAX_AFFIXES := 5
const MAX_ITEM_LEVEL := 100
## Cada nível do item soma 2% aos atributos-base e aos afixos: andar 100 vale ~3x o andar 1.
const LEVEL_STEP := 0.02

## id: tipo, chave, faixa do comum e rótulo. Valores de `mod` em fração (0.06 = 6%).
const POOL := {
	"forca": {"kind": "stat", "key": "strength", "min": 2.0, "max": 5.0, "label": "Forca"},
	"inteligencia": {"kind": "stat", "key": "intelligence", "min": 2.0, "max": 5.0, "label": "Inteligencia"},
	"agilidade": {"kind": "stat", "key": "agility", "min": 2.0, "max": 5.0, "label": "Agilidade"},
	"vitalidade": {"kind": "stat", "key": "vitality", "min": 2.0, "max": 5.0, "label": "Vitalidade"},
	"sabedoria": {"kind": "stat", "key": "wisdom", "min": 2.0, "max": 5.0, "label": "Sabedoria"},
	"sorte": {"kind": "stat", "key": "fortune", "min": 2.0, "max": 5.0, "label": "Sorte"},
	"vida": {"kind": "stat", "key": "health", "min": 8.0, "max": 20.0, "label": "Vida"},
	"folego": {"kind": "stat", "key": "breath", "min": 5.0, "max": 12.0, "label": "Folego"},
	"defesa": {"kind": "stat", "key": "defense", "min": 3.0, "max": 8.0, "label": "Defesa"},
	"velocidade": {"kind": "stat", "key": "movement_speed", "min": 2.0, "max": 5.0, "label": "Velocidade", "percent": true},
	"cadencia": {"kind": "stat", "key": "attack_speed", "min": 2.0, "max": 5.0, "label": "Cadencia de ataque", "percent": true},
	"critico": {"kind": "stat", "key": "critical_chance", "min": 1.0, "max": 3.0, "label": "Chance critica", "percent": true},
	"recarga": {"kind": "stat", "key": "cooldown_recovery", "min": 2.0, "max": 4.0, "label": "Recuperacao de recarga", "percent": true},
	"area": {"kind": "stat", "key": "area", "min": 2.0, "max": 5.0, "label": "Area", "percent": true},
	"dano_fogo": {"kind": "mod", "key": "power_fire_mult", "min": 0.04, "max": 0.1, "label": "dano de fogo"},
	"dano_gelo": {"kind": "mod", "key": "power_ice_mult", "min": 0.04, "max": 0.1, "label": "dano de gelo"},
	"dano_raio": {"kind": "mod", "key": "power_lightning_mult", "min": 0.04, "max": 0.1, "label": "dano de raio"},
	"dano_trevas": {"kind": "mod", "key": "power_dark_mult", "min": 0.04, "max": 0.1, "label": "dano de trevas"},
	"dano_sagrado": {"kind": "mod", "key": "power_holy_mult", "min": 0.04, "max": 0.1, "label": "dano sagrado"},
	"dano_natureza": {"kind": "mod", "key": "power_nature_mult", "min": 0.04, "max": 0.1, "label": "dano de natureza"},
	"dano_acido": {"kind": "mod", "key": "power_acid_mult", "min": 0.04, "max": 0.1, "label": "dano acido"},
	"dano_terra": {"kind": "mod", "key": "power_earth_mult", "min": 0.04, "max": 0.1, "label": "dano de terra"},
	"dano_arcano": {"kind": "mod", "key": "power_arcane_mult", "min": 0.04, "max": 0.1, "label": "dano arcano"},
	"dano_fisico": {"kind": "mod", "key": "power_physical_mult", "min": 0.04, "max": 0.1, "label": "dano fisico"},
	"dano_magico": {"kind": "mod", "key": "power_magic_mult", "min": 0.03, "max": 0.08, "label": "dano magico"},
	"autoataque": {"kind": "mod", "key": "auto_damage_mult", "min": 0.05, "max": 0.12, "label": "dano do autoataque"},
	"invocacoes": {"kind": "mod", "key": "power_summon_mult", "min": 0.05, "max": 0.12, "label": "dano de invocacoes"},
	"regeneracao_folego": {"kind": "mod", "key": "breath_regen_mult", "min": 0.05, "max": 0.12, "label": "regeneracao de Folego"},
	"roubo_vida": {"kind": "mod", "key": "life_steal_add", "min": 0.01, "max": 0.02, "label": "roubo de Vida"},
	"resistencia": {"kind": "mod", "key": "damage_taken_mult", "min": -0.05, "max": -0.02, "label": "dano recebido"},
	# Resistências e penetração (E1 fase 1): somam; teto de 75% na personagem.
	"resistencia_todas": {"kind": "mod", "key": "resist_all_add", "min": 0.02, "max": 0.05, "label": "resistencia a tudo"},
	"resistencia_fisica": {"kind": "mod", "key": "resist_physical_add", "min": 0.04, "max": 0.1, "label": "resistencia fisica"},
	"resistencia_fogo": {"kind": "mod", "key": "resist_fire_add", "min": 0.04, "max": 0.1, "label": "resistencia a fogo"},
	"resistencia_gelo": {"kind": "mod", "key": "resist_ice_add", "min": 0.04, "max": 0.1, "label": "resistencia a gelo"},
	"resistencia_raio": {"kind": "mod", "key": "resist_lightning_add", "min": 0.04, "max": 0.1, "label": "resistencia a raio"},
	"resistencia_acido": {"kind": "mod", "key": "resist_acid_add", "min": 0.04, "max": 0.1, "label": "resistencia a acido"},
	"resistencia_natureza": {"kind": "mod", "key": "resist_nature_add", "min": 0.04, "max": 0.1, "label": "resistencia a natureza"},
	"resistencia_trevas": {"kind": "mod", "key": "resist_dark_add", "min": 0.04, "max": 0.1, "label": "resistencia a trevas"},
	"resistencia_sagrado": {"kind": "mod", "key": "resist_holy_add", "min": 0.04, "max": 0.1, "label": "resistencia sagrada"},
	"resistencia_terra": {"kind": "mod", "key": "resist_earth_add", "min": 0.04, "max": 0.1, "label": "resistencia a terra"},
	"resistencia_arcano": {"kind": "mod", "key": "resist_arcane_add", "min": 0.04, "max": 0.1, "label": "resistencia arcana"},
	"penetracao": {"kind": "mod", "key": "penetration_add", "min": 0.03, "max": 0.06, "label": "penetracao de resistencia"},
	# Fixo de certos lendários (fora do sorteio comum): faixa exata, sem escala de raridade ou nível.
	"proliferacao": {"kind": "mod", "key": "poison_spread_mult", "min": 0.3, "max": 1.0, "label": "alcance de proliferacao de veneno", "random": false},
}


static func count_range(tier: String) -> Array:
	return COUNT.get(tier, [1, 1]) as Array


static func level_factor(item_level: int) -> float:
	return 1.0 + LEVEL_STEP * float(clampi(item_level, 1, MAX_ITEM_LEVEL) - 1)


## Sorteia afixos distintos para uma peça da raridade e do nível dados.
static func roll(tier: String, random: RandomNumberGenerator, item_level: int = 1) -> Array[Dictionary]:
	var bounds := count_range(tier)
	var count := random.randi_range(int(bounds[0]), int(bounds[1]))
	var ids: Array = POOL.keys().filter(func(id: String) -> bool: return bool((POOL[id] as Dictionary).get("random", true)))
	var result: Array[Dictionary] = []
	for index in range(count):
		var pick := random.randi_range(index, ids.size() - 1)
		var swap: Variant = ids[index]
		ids[index] = ids[pick]
		ids[pick] = swap
		var spec := POOL[ids[index]] as Dictionary
		var value := random.randf_range(float(spec["min"]), float(spec["max"])) * float(SCALE.get(tier, 1.0)) * level_factor(item_level)
		result.append({"id": String(ids[index]), "value": _round(spec, value)})
	return result


## Afixos fixos de um item (`fixed_affixes` nos dados): sempre presentes, valor sorteado na faixa
## declarada pelo item, sem escala de raridade ou nível (Presa da Serpente: proliferação +30% a +100%).
static func roll_fixed(specs: Array, random: RandomNumberGenerator) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec: Dictionary in specs:
		var id := String(spec.get("id", ""))
		if not POOL.has(id):
			continue
		var pool_spec := POOL[id] as Dictionary
		var value := random.randf_range(float(spec.get("min", pool_spec["min"])), float(spec.get("max", pool_spec["max"])))
		result.append({"id": id, "value": snappedf(value, 0.05)})
	return result


static func _round(spec: Dictionary, value: float) -> float:
	if String(spec["kind"]) == "mod":
		return snappedf(value, 0.005)
	return float(roundi(value)) if not bool(spec.get("percent", false)) else snappedf(value, 0.5)


## Afixos válidos de um save: ids conhecidos, valores finitos, no máximo quatro.
static func sanitize(raw: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not raw is Array:
		return result
	for entry: Variant in raw:
		if result.size() >= MAX_AFFIXES or not entry is Dictionary:
			continue
		var id := String((entry as Dictionary).get("id", ""))
		var value := float((entry as Dictionary).get("value", 0.0))
		if POOL.has(id) and is_finite(value):
			result.append({"id": id, "value": value})
	return result


## Soma dos afixos de atributo (mesmas chaves dos atributos de item).
static func stats(affixes: Array) -> Dictionary:
	var result := {}
	for affix: Dictionary in affixes:
		var spec := POOL.get(String(affix["id"]), {}) as Dictionary
		if String(spec.get("kind", "")) == "stat":
			var key := StringName(String(spec["key"]))
			result[key] = float(result.get(key, 0.0)) + float(affix["value"])
	return result


## Modificadores dos afixos: `_mult` vira fator (1 + valor) e multiplica; o resto soma.
static func mods(affixes: Array) -> Dictionary:
	var result := {}
	for affix: Dictionary in affixes:
		var spec := POOL.get(String(affix["id"]), {}) as Dictionary
		if String(spec.get("kind", "")) != "mod":
			continue
		var key := String(spec["key"])
		if key.ends_with("_mult"):
			result[key] = float(result.get(key, 1.0)) * (1.0 + float(affix["value"]))
		else:
			result[key] = float(result.get(key, 0.0)) + float(affix["value"])
	return result


static func describe(affix: Dictionary) -> String:
	var spec := POOL.get(String(affix.get("id", "")), {}) as Dictionary
	if spec.is_empty():
		return ""
	var value := float(affix["value"])
	if String(spec["kind"]) == "mod":
		return "%s%.1f%% %s" % ["+" if value >= 0.0 else "", value * 100.0, spec["label"]]
	if bool(spec.get("percent", false)):
		return "+%.1f%% %s" % [value, spec["label"]]
	return "+%d %s" % [int(value), spec["label"]]
