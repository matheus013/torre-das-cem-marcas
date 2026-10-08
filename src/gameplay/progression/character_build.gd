class_name CharacterBuild
extends RefCounted

const PRIMARY_STATS: Array[StringName] = [
	&"vitality", &"strength", &"intelligence", &"agility", &"fortune", &"wisdom"
]
const MAX_LEVEL := 100
const STAT_POINTS_PER_REGULAR_LEVEL := 5
const EVOLUTION_INTERVAL := 10

var character_id: StringName
var signature_passive: SignaturePassiveDefinition
var max_level := MAX_LEVEL
var level := 1
var unspent_stat_points := STAT_POINTS_PER_REGULAR_LEVEL
var milestone_choices: Dictionary = {}
var selected_milestones: Dictionary = {}
var base_stats: Dictionary = {}
var unlocked_mechanics: Array[StringName] = []


func _init(build_character_id: StringName, build_max_level: int = MAX_LEVEL) -> void:
	character_id = build_character_id
	max_level = clampi(build_max_level, EVOLUTION_INTERVAL, MAX_LEVEL)
	for stat in PRIMARY_STATS:
		base_stats[stat] = 0.0


func assign_signature_passive(passive: SignaturePassiveDefinition) -> bool:
	if signature_passive != null or passive.owner_character_id != character_id:
		return false
	signature_passive = passive
	return true


func is_ready_for_play() -> bool:
	return signature_passive != null


func add_milestone_choice(milestone_level: int, choice: EvolutionChoice) -> bool:
	if milestone_level < EVOLUTION_INTERVAL or milestone_level > max_level:
		return false
	if milestone_level % EVOLUTION_INTERVAL != 0:
		return false
	if milestone_level == max_level and choice.kind != EvolutionChoice.Kind.MECHANIC:
		return false
	if not milestone_choices.has(milestone_level):
		milestone_choices[milestone_level] = []
	var choices := milestone_choices[milestone_level] as Array
	for existing_value: Variant in choices:
		if (existing_value as EvolutionChoice).id == choice.id:
			return false
	choices.append(choice)
	return true


func has_pending_milestone() -> bool:
	return level % EVOLUTION_INTERVAL == 0 and not selected_milestones.has(level)


func choose_milestone(choice_id: StringName) -> bool:
	if not has_pending_milestone() or not milestone_choices.has(level):
		return false
	var choice: EvolutionChoice = null
	for candidate_value: Variant in milestone_choices[level]:
		var candidate := candidate_value as EvolutionChoice
		if candidate.id == choice_id:
			choice = candidate
			break
	if choice == null:
		return false
	selected_milestones[level] = choice.id
	for stat: Variant in choice.stat_modifiers.keys():
		if base_stats.has(stat):
			base_stats[stat] = float(base_stats[stat]) + float(choice.stat_modifiers[stat])
	if choice.kind == EvolutionChoice.Kind.MECHANIC and not choice.mechanic_id.is_empty():
		unlocked_mechanics.append(choice.mechanic_id)
	return true


func level_up() -> bool:
	if level >= max_level or has_pending_milestone():
		return false
	level += 1
	if level % EVOLUTION_INTERVAL != 0:
		unspent_stat_points += STAT_POINTS_PER_REGULAR_LEVEL
	return true


func allocate_stat(stat: StringName, amount: int) -> bool:
	if not base_stats.has(stat) or amount <= 0 or amount > unspent_stat_points:
		return false
	base_stats[stat] = float(base_stats[stat]) + float(amount)
	unspent_stat_points -= amount
	return true


## Pontos de atributo ganhos até o nível atual: 5 no nível 1 e 5 por nível que não é de evolução.
func earned_stat_points() -> int:
	var points := STAT_POINTS_PER_REGULAR_LEVEL
	for reached in range(2, level + 1):
		if reached % EVOLUTION_INTERVAL != 0:
			points += STAT_POINTS_PER_REGULAR_LEVEL
	return points


## Atributos que vêm das evoluções escolhidas (não voltam no reset).
func milestone_stat_bonus() -> Dictionary:
	var bonus := {}
	for milestone_level: Variant in selected_milestones:
		for candidate_value: Variant in milestone_choices.get(milestone_level, []) as Array:
			var choice := candidate_value as EvolutionChoice
			if choice.id == selected_milestones[milestone_level]:
				for stat: Variant in choice.stat_modifiers:
					bonus[stat] = float(bonus.get(stat, 0.0)) + float(choice.stat_modifiers[stat])
	return bonus


## Devolve todos os pontos distribuídos; os bônus das evoluções ficam. Retorna os pontos livres.
func reset_stats() -> int:
	var bonus := milestone_stat_bonus()
	for stat in PRIMARY_STATS:
		base_stats[stat] = float(bonus.get(stat, 0.0))
	unspent_stat_points = earned_stat_points()
	return unspent_stat_points


func derived_stats() -> Dictionary:
	return StatResolver.resolve(base_stats)


func snapshot() -> Dictionary:
	var selected: Dictionary = {}
	for milestone: Variant in selected_milestones:
		selected[str(milestone)] = str(selected_milestones[milestone])
	return {
		"character_id": str(character_id),
		"level": level,
		"unspent_stat_points": unspent_stat_points,
		"base_stats": base_stats.duplicate(true),
		"selected_milestones": selected,
		"unlocked_mechanics": unlocked_mechanics.map(func(value: StringName) -> String: return str(value)),
	}


func restore(data: Dictionary) -> void:
	if StringName(String(data.get("character_id", character_id))) != character_id:
		return
	level = clampi(int(data.get("level", 1)), 1, max_level)
	unspent_stat_points = maxi(0, int(data.get("unspent_stat_points", STAT_POINTS_PER_REGULAR_LEVEL)))
	var saved_stats := data.get("base_stats", {}) as Dictionary
	for stat in PRIMARY_STATS:
		base_stats[stat] = maxf(0.0, float(saved_stats.get(String(stat), saved_stats.get(stat, 0.0))))
	selected_milestones.clear()
	var selected := data.get("selected_milestones", {}) as Dictionary
	for milestone: Variant in selected:
		selected_milestones[int(milestone)] = StringName(String(selected[milestone]))
	unlocked_mechanics.clear()
	for mechanic: Variant in data.get("unlocked_mechanics", []) as Array:
		unlocked_mechanics.append(StringName(String(mechanic)))
