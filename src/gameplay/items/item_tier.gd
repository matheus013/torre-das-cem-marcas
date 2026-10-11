class_name ItemTier
extends RefCounted

enum Value {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	## Divino (decisão 608): acima de lendário, só da dificuldade 4 em diante.
	DIVINE,
}

const LABELS: Dictionary = {
	Value.COMMON: "Comum",
	Value.UNCOMMON: "Incomum",
	Value.RARE: "Raro",
	Value.EPIC: "Epico",
	Value.LEGENDARY: "Lendario",
	Value.DIVINE: "Divino",
}


const KEYS: Dictionary = {
	Value.COMMON: "common",
	Value.UNCOMMON: "uncommon",
	Value.RARE: "rare",
	Value.EPIC: "epic",
	Value.LEGENDARY: "legendary",
	Value.DIVINE: "divine",
}
## Uma cor por raridade, usada em menus, saque no chão e laboratório. O lendário é laranja
## para não se confundir com o dourado dos títulos da interface.
const COLORS: Dictionary = {
	"common": Color("c9c2b4"),
	"uncommon": Color("7fc95a"),
	"rare": Color("5ca7ff"),
	"epic": Color("b97be6"),
	"legendary": Color("f08a3c"),
	"divine": Color("f6e7a8"),
}


## Ordem crescente de raridade, para comparar chaves ("rare" acima de "uncommon").
const TIER_KEYS_ORDER: Array[String] = ["common", "uncommon", "rare", "epic", "legendary", "divine"]


static func key(value: Value) -> String:
	return KEYS.get(value, "common") as String


## Aceita a chave ("rare") ou o valor do enum.
static func color(tier: Variant) -> Color:
	var tier_key := key(tier as Value) if tier is int else String(tier)
	return COLORS.get(tier_key, COLORS["common"]) as Color


static func label(value: Value) -> String:
	return LABELS.get(value, "Desconhecido") as String


static func is_at_least(value: Value, minimum: Value) -> bool:
	return int(value) >= int(minimum)
