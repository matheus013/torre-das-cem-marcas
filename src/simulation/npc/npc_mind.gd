class_name NpcMind
extends RefCounted

const MAX_MEMORIES := 32

var npc_id: StringName
var traits: Dictionary = {}
var values: Dictionary = {}
var needs: Dictionary = {}
var relations: Dictionary = {}
var memories: Array[Dictionary] = []


func _init(mind_id: StringName) -> void:
	npc_id = mind_id


func set_trait(key: StringName, amount: float) -> void:
	traits[key] = clampf(amount, 0.0, 1.0)


func set_value(key: StringName, amount: float) -> void:
	values[key] = clampf(amount, 0.0, 1.0)


func set_need(key: StringName, amount: float) -> void:
	needs[key] = clampf(amount, 0.0, 1.0)


func set_relation(target_id: StringName, dimension: StringName, amount: float) -> void:
	if not relations.has(target_id):
		relations[target_id] = {}
	var target_relations := relations[target_id] as Dictionary
	target_relations[dimension] = clampf(amount, -1.0, 1.0)


func remember(tag: StringName, target_id: StringName, impact: float, age_days: int = 0) -> void:
	memories.append({
		"tag": tag,
		"target_id": target_id,
		"impact": clampf(impact, -1.0, 1.0),
		"age_days": maxi(0, age_days),
	})
	if memories.size() > MAX_MEMORIES:
		memories.pop_front()


func choose_action(
	options: Array[NpcDecisionOption],
	context: NpcDecisionContext
) -> NpcDecisionOption:
	var chosen: NpcDecisionOption = null
	var chosen_score := -INF
	for option in options:
		if not option.is_available(context):
			continue
		var score := score_action(option, context)
		if chosen == null or score > chosen_score or (
			is_equal_approx(score, chosen_score) and String(option.id) < String(chosen.id)
		):
			chosen = option
			chosen_score = score
	return chosen


func score_action(option: NpcDecisionOption, context: NpcDecisionContext) -> float:
	if not option.is_available(context):
		return -INF
	var score := option.base_score
	score += _weighted_sum(traits, option.trait_weights)
	score += _weighted_sum(values, option.value_weights)
	score += _weighted_sum(needs, option.need_weights)
	score += _weighted_sum(_relation_to(context.target_id), option.relation_weights)
	score += _memory_score(option.memory_weights, context.target_id)
	score += context.urgency * option.urgency_weight
	var caution := float(traits.get(&"caution", 0.5))
	var integrity := float(values.get(&"integrity", 0.5))
	score -= option.risk * (0.5 + caution) * 10.0
	score -= option.moral_cost * integrity * 10.0
	return snappedf(score, 0.001)


func _relation_to(target_id: StringName) -> Dictionary:
	return relations.get(target_id, {}) as Dictionary


func _weighted_sum(source: Dictionary, weights: Dictionary) -> float:
	var result := 0.0
	for key: Variant in weights.keys():
		result += float(source.get(key, 0.0)) * float(weights[key])
	return result


func _memory_score(weights: Dictionary, target_id: StringName) -> float:
	var result := 0.0
	for memory in memories:
		if memory["target_id"] != target_id and memory["target_id"] != &"":
			continue
		var tag: StringName = memory["tag"]
		if not weights.has(tag):
			continue
		var age_days := int(memory["age_days"])
		var retention := 1.0 / (1.0 + float(age_days) / 30.0)
		result += float(memory["impact"]) * float(weights[tag]) * retention
	return result
