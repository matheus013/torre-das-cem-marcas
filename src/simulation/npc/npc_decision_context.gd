class_name NpcDecisionContext
extends RefCounted

var target_id: StringName
var urgency: float
var known_facts: Dictionary = {}


func _init(
	context_target_id: StringName = &"",
	context_urgency: float = 0.0,
	context_known_facts: Array[StringName] = []
) -> void:
	target_id = context_target_id
	urgency = clampf(context_urgency, 0.0, 1.0)
	for fact in context_known_facts:
		known_facts[fact] = true


func knows(fact: StringName) -> bool:
	return known_facts.has(fact)
