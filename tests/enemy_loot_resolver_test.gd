extends SceneTree

const LootResolverScript := preload("res://src/gameplay/loot/enemy_loot_resolver.gd")


func _init() -> void:
	var resolver: RefCounted = LootResolverScript.new()
	var table := {
		"id": "test_multi_drop",
		"entries": [
			{"item_id": "pedra_regenerativa", "chance": 1.0, "minimum": 1, "maximum": 1},
			{"item_id": "escama_de_reboco", "chance": 1.0, "minimum": 2, "maximum": 2},
			{"item_id": "nunca", "chance": 0.0, "minimum": 1, "maximum": 1},
		],
	}
	var drops: Array = resolver.call("resolve", table, 7301, 1)
	if drops.size() != 2 or drops[0]["item_id"] != "pedra_regenerativa" or int(drops[1]["quantity"]) != 2:
		push_error("Independent loot entries did not produce multiple deterministic drops")
		quit(1)
		return
	if resolver.call("resolve", table, 7301, 1) != drops:
		push_error("Loot resolution is not deterministic for host replication")
		quit(1)
		return
	print("ENEMY_LOOT_OK: multiple independent deterministic drops validated")
	quit(0)
