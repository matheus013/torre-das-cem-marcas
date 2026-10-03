class_name NpcDecisionOption
extends RefCounted

var id: StringName
var base_score: float = 0.0
var trait_weights: Dictionary = {}
var value_weights: Dictionary = {}
var need_weights: Dictionary = {}
var relation_weights: Dictionary = {}
var memory_weights: Dictionary = {}
var required_facts: Array[StringName] = []
var forbidden_facts: Array[StringName] = []
var urgency_weight: float = 0.0
var risk: float = 0.0
var moral_cost: float = 0.0


func _init(option_id: StringName, option_base_score: float = 0.0) -> void:
	id = option_id
	base_score = option_base_score


func is_available(context: NpcDecisionContext) -> bool:
	for fact in required_facts:
		if not context.knows(fact):
			return false
	for fact in forbidden_facts:
		if context.knows(fact):
			return false
	return true
