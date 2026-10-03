class_name ItemTier
extends RefCounted

enum Value {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

const LABELS: Dictionary = {
	Value.COMMON: "Comum",
	Value.UNCOMMON: "Incomum",
	Value.RARE: "Raro",
	Value.EPIC: "Epico",
	Value.LEGENDARY: "Lendario",
}


static func label(value: Value) -> String:
	return LABELS.get(value, "Desconhecido") as String


static func is_at_least(value: Value, minimum: Value) -> bool:
	return int(value) >= int(minimum)
