class_name BetaContentCatalog
extends RefCounted

const MajorEncounterDefinitionScript := preload("res://src/gameplay/encounters/major_encounter_definition.gd")
const ItemPassivesScript := preload("res://src/gameplay/items/item_passives.gd")
const DEFAULT_PATH := "res://data/beta/beta_content.json"
const ACTIVE_MECHANICS: Array[String] = [
	"projectile", "dash", "nova", "field", "barrier", "chain", "summon", "sanctuary",
	"cone", "beam", "orbit", "mine", "meteor", "boomerang", "volley", "spores", "poison_pool",
]
const ENEMY_MECHANICS: Array[String] = [
	"swarm", "erode_cover", "telegraphed_shot", "wall_ambush", "loot_mimic",
	"enemy_barrier", "mark_target", "incorporate_objects", "raid_core",
]
const MODIFIER_MECHANICS: Array[String] = [
	"", "regeneration", "first_hit_shield", "split_on_death", "slowing_contact",
	"echo_attack", "life_leech", "gravity_pull", "wall_hide", "death_burst",
]
const ITEM_TIERS: Array[String] = ["common", "uncommon", "rare", "epic", "legendary"]
const SUMMON_BEHAVIORS: Array[String] = ["stationary", "follow_owner", "chase_target"]
const SUMMON_TARGETING: Array[String] = ["nearest_hostile", "owner_target", "lowest_health_hostile"]
const SUMMON_REPLACEMENT: Array[String] = ["oldest", "reject"]
const CHARACTER_BRANCHES: Array[String] = ["essence", "adaptation", "convergence"]
const CHARACTER_MAX_LEVEL := 100
## Mecânicas de marco executadas pela WorldSimulation (decisão 549).
const CHARACTER_MECHANICS: Array[String] = [
	"skill_echo", "kill_burst", "last_stand", "breath_shield", "auto_imprint", "auto_chain",
	"shared_condition", "cooldown_refund", "ally_link", "summon_on_kill", "rescue", "dash_nova", "ally_feed",
]
const ENCOUNTER_CLASSES: Array[String] = ["common", "elite", "boss", "raid"]

var data: Dictionary = {}


func load_from(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return false
	data = parsed as Dictionary
	return validation_errors().is_empty()


func collection(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var raw: Variant = data.get(key, [])
	if raw is Array:
		for value: Variant in raw:
			if value is Dictionary:
				result.append(value as Dictionary)
	return result


func find_definition(collection_name: String, definition_id: String) -> Dictionary:
	for definition in collection(collection_name):
		if String(definition.get("id", "")) == definition_id:
			return definition
	return {}


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if int(data.get("version", 0)) != 1:
		errors.append("Unsupported beta content version")
	_validate_unique_ids("active_gems", errors)
	_validate_unique_ids("playable_characters", errors)
	_validate_unique_ids("support_gems", errors)
	_validate_unique_ids("summons", errors)
	_validate_unique_ids("monster_races", errors)
	_validate_unique_ids("enemy_ranks", errors)
	_validate_unique_ids("enemies", errors)
	_validate_unique_ids("loot_tables", errors)
	_validate_unique_ids("major_encounters", errors)
	_validate_unique_ids("special_boss_rooms", errors)
	_validate_unique_ids("enemy_modifiers", errors)
	_validate_unique_ids("items", errors)
	for character in collection("playable_characters"):
		_validate_playable_character(character, errors)
	for item in collection("items"):
		var passive := item.get("passive", {}) as Dictionary
		if String(item.get("tier", "")) == "legendary" and passive.is_empty():
			errors.append("Legendary item without exclusive passive: %s" % item.get("id", ""))
		if not passive.is_empty():
			for problem in ItemPassivesScript.validate(passive):
				errors.append("%s: %s" % [item.get("id", ""), problem])
	for gem in collection("active_gems"):
		for stat: Variant in gem.get("scaling", []):
			if not CharacterBuild.PRIMARY_STATS.has(StringName(String(stat))):
				errors.append("Unknown scaling stat in %s: %s" % [gem.get("id", ""), stat])
		if float(gem.get("cooldown", 0.0)) <= 0.0:
			errors.append("Active gem has invalid cooldown: %s" % gem.get("id", ""))
		if String(gem.get("mechanic", "")) not in ACTIVE_MECHANICS:
			errors.append("Unknown active mechanic: %s" % gem.get("id", ""))
		if String(gem.get("mechanic", "")) == "summon":
			if find_definition("summons", String(gem.get("summon_definition_id", ""))).is_empty():
				errors.append("Summon gem has unknown definition: %s" % gem.get("id", ""))
			if int(gem.get("summon_count", 0)) <= 0:
				errors.append("Summon gem has invalid count: %s" % gem.get("id", ""))
		var evolutions: Variant = gem.get("evolutions", {})
		# Maestria (decisão 588): 3 modificadores nos níveis 5, 10, 15 e 20; 2 grandes no 21.
		for level in ["5", "10", "15", "20", "21"]:
			var needed := 2 if level == "21" else 3
			if not evolutions is Dictionary or not evolutions.has(level) or not evolutions[level] is Array or evolutions[level].size() < needed:
				errors.append("Active gem %s needs %d mastery choices at level %s" % [gem.get("id", ""), needed, level])
	for support in collection("support_gems"):
		for mechanic: Variant in support.get("allowed_mechanics", []):
			if String(mechanic) not in ACTIVE_MECHANICS:
				errors.append("Unknown support mechanic: %s" % support.get("id", ""))
		for modifier: Variant in support.get("modifiers", {}):
			var field := String(modifier).trim_suffix("_multiplier").trim_suffix("_add")
			if field not in SkillEffectResolver.SUPPORT_FIELDS:
				errors.append("Unknown support modifier in %s: %s" % [support.get("id", ""), modifier])
		if String(support.get("category", "")) not in ["mechanic", "buff"] or String(support.get("description", "")).is_empty():
			errors.append("Support needs category and description: %s" % support.get("id", ""))
		var compatible := false
		var resolver := SkillEffectResolver.new()
		for gem in collection("active_gems"):
			compatible = compatible or resolver.supports(gem, support)
		if not compatible:
			errors.append("Support has no compatible active gem: %s" % support.get("id", ""))
		if int(support.get("drain", 0)) <= 0:
			errors.append("Support gem has invalid drain: %s" % support.get("id", ""))
	for summon in collection("summons"):
		if String(summon.get("behavior", "")) not in SUMMON_BEHAVIORS:
			errors.append("Invalid summon behavior: %s" % summon.get("id", ""))
		if String(summon.get("targeting", "")) not in SUMMON_TARGETING:
			errors.append("Invalid summon targeting: %s" % summon.get("id", ""))
		if String(summon.get("replacement_policy", "")) not in SUMMON_REPLACEMENT:
			errors.append("Invalid summon replacement policy: %s" % summon.get("id", ""))
		if (
			float(summon.get("health", 0.0)) <= 0.0
			or float(summon.get("movement_speed", -1.0)) < 0.0
			or float(summon.get("power", -1.0)) < 0.0
			or float(summon.get("attack_interval", 0.0)) <= 0.0
			or float(summon.get("range", 0.0)) <= 0.0
			or float(summon.get("duration", -1.0)) < 0.0
			or int(summon.get("owner_limit", 0)) <= 0
			or float(summon.get("collision_radius", 0.0)) <= 0.0
		):
			errors.append("Invalid summon values: %s" % summon.get("id", ""))
	for race in collection("monster_races"):
		var profile := race.get("stat_profile", {}) as Dictionary
		for stat in ["health", "damage", "speed", "attack_interval"]:
			if float(profile.get(stat, 0.0)) <= 0.0:
				errors.append("Monster race has invalid stat profile: %s" % race.get("id", ""))
	for enemy in collection("enemies"):
		if String(enemy.get("mechanic", "")) not in ENEMY_MECHANICS:
			errors.append("Unknown enemy mechanic: %s" % enemy.get("id", ""))
		if float(enemy.get("health", 0.0)) <= 0.0:
			errors.append("Enemy has invalid health: %s" % enemy.get("id", ""))
		if find_definition("monster_races", String(enemy.get("race_id", ""))).is_empty():
			errors.append("Enemy has unknown race: %s" % enemy.get("id", ""))
		if find_definition("enemy_ranks", String(enemy.get("rank_id", ""))).is_empty():
			errors.append("Enemy has unknown rank: %s" % enemy.get("id", ""))
		if String(enemy.get("encounter_class", "")) not in ENCOUNTER_CLASSES:
			errors.append("Enemy has invalid encounter class: %s" % enemy.get("id", ""))
		if String(enemy.get("lore_basis", "")).is_empty():
			errors.append("Enemy has no lore basis: %s" % enemy.get("id", ""))
		if find_definition("loot_tables", String(enemy.get("loot_table_id", ""))).is_empty():
			errors.append("Enemy has unknown loot table: %s" % enemy.get("id", ""))
	for loot_table in collection("loot_tables"):
		var entries := loot_table.get("entries", []) as Array
		if entries.is_empty():
			errors.append("Loot table is empty: %s" % loot_table.get("id", ""))
		for raw_entry: Variant in entries:
			if not raw_entry is Dictionary:
				errors.append("Loot table has invalid entry: %s" % loot_table.get("id", ""))
				continue
			var entry := raw_entry as Dictionary
			if find_definition("items", String(entry.get("item_id", ""))).is_empty():
				errors.append("Loot table has unknown item: %s" % loot_table.get("id", ""))
			if (
				float(entry.get("chance", -1.0)) < 0.0
				or float(entry.get("chance", 2.0)) > 1.0
				or int(entry.get("minimum", 0)) <= 0
				or int(entry.get("maximum", 0)) < int(entry.get("minimum", 0))
			):
				errors.append("Loot table has invalid values: %s" % loot_table.get("id", ""))
	for encounter in collection("major_encounters"):
		var major_definition: RefCounted = MajorEncounterDefinitionScript.from_dictionary(encounter)
		if not bool(major_definition.call("is_valid_definition")):
			errors.append("Invalid major encounter: %s" % encounter.get("id", ""))
			continue
		var enemy := find_definition("enemies", String(encounter.get("enemy_definition_id", "")))
		if enemy.is_empty():
			errors.append("Major encounter has unknown enemy: %s" % encounter.get("id", ""))
		elif (
			String(enemy.get("encounter_class", "")) != String(encounter.get("encounter_type", ""))
			or String(enemy.get("rank_id", "")) != "apice"
			or bool(enemy.get("allow_affixes", true))
		):
			errors.append("Major encounter enemy must be matching Apex without random affixes: %s" % encounter.get("id", ""))
	for room in collection("special_boss_rooms"):
		var encounter := find_definition("major_encounters", String(room.get("encounter_id", "")))
		if encounter.is_empty() or String(encounter.get("encounter_type", "")) != "boss":
			errors.append("Special room has unknown boss encounter: %s" % room.get("id", ""))
		if not bool(room.get("exclusive_enemy", false)) or float(room.get("respawn_seconds", 0.0)) < 60.0:
			errors.append("Special boss room must be exclusive and have a long respawn: %s" % room.get("id", ""))
		if String(room.get("lore_basis", "")).is_empty():
			errors.append("Special boss room has no lore basis: %s" % room.get("id", ""))
	for rank in collection("enemy_ranks"):
		var minimum_affixes := int(rank.get("minimum_affixes", 0))
		var maximum_affixes := int(rank.get("maximum_affixes", 0))
		if minimum_affixes < 0 or maximum_affixes > 2 or minimum_affixes > maximum_affixes:
			errors.append("Invalid affix allowance for rank: %s" % rank.get("id", ""))
	for modifier in collection("enemy_modifiers"):
		if String(modifier.get("position", "")) not in ["prefix", "suffix"]:
			errors.append("Invalid modifier position: %s" % modifier.get("id", ""))
		if String(modifier.get("mechanic_id", "")) not in MODIFIER_MECHANICS:
			errors.append("Unknown modifier mechanic: %s" % modifier.get("id", ""))
	for item in collection("items"):
		if String(item.get("tier", "")) not in ITEM_TIERS:
			errors.append("Invalid item tier: %s" % item.get("id", ""))
		if String(item.get("item_type", "")) == "relic" and String(item.get("tier", "")) not in ["epic", "legendary"]:
			errors.append("Relic below epic tier: %s" % item.get("id", ""))
	return errors


func _validate_unique_ids(collection_name: String, errors: Array[String]) -> void:
	var seen: Dictionary = {}
	for definition in collection(collection_name):
		var definition_id := String(definition.get("id", ""))
		if definition_id.is_empty():
			errors.append("Missing id in %s" % collection_name)
		elif seen.has(definition_id):
			errors.append("Duplicate id %s in %s" % [definition_id, collection_name])
		seen[definition_id] = true


func _validate_playable_character(character: Dictionary, errors: Array[String]) -> void:
	var character_id := String(character.get("id", ""))
	if int(character.get("max_level", 0)) != CHARACTER_MAX_LEVEL:
		errors.append("Beta character must progress to level %d: %s" % [CHARACTER_MAX_LEVEL, character_id])
	for key in ["name", "people", "family", "style"]:
		if String(character.get(key, "")).is_empty():
			errors.append("Beta character %s is missing %s" % [character_id, key])
	var passive := character.get("passive", {}) as Dictionary
	for key in ["id", "name", "mechanic_id", "description", "resource_id"]:
		if String(passive.get(key, "")).is_empty():
			errors.append("Beta character %s has incomplete passive %s" % [character_id, key])
	if (passive.get("trigger_events", []) as Array).is_empty() or (passive.get("spend_modes", []) as Array).size() < 2:
		errors.append("Beta character has passive without broad triggers or decisions: %s" % character_id)
	var milestones := character.get("milestones", {}) as Dictionary
	var choice_ids: Dictionary = {}
	for level in range(10, CHARACTER_MAX_LEVEL + 1, 10):
		var level_text := str(level)
		var choices := milestones.get(level_text, []) as Array
		if choices.size() != 6:
			errors.append("Beta character %s needs six choices at level %s" % [character_id, level_text])
		var branch_counts := {"essence": 0, "adaptation": 0, "convergence": 0}
		for raw_choice: Variant in choices:
			if not raw_choice is Dictionary:
				errors.append("Invalid character choice for %s at %s" % [character_id, level_text])
				continue
			var choice := raw_choice as Dictionary
			var choice_id := String(choice.get("id", ""))
			var branch := String(choice.get("branch", ""))
			if choice_id.is_empty() or choice_ids.has(choice_id):
				errors.append("Missing or duplicate character choice for %s: %s" % [character_id, choice_id])
			choice_ids[choice_id] = true
			if branch not in CHARACTER_BRANCHES:
				errors.append("Invalid character branch for %s: %s" % [character_id, choice_id])
			else:
				branch_counts[branch] = int(branch_counts[branch]) + 1
			if level in [20, CHARACTER_MAX_LEVEL] and String(choice.get("kind", "")) != "mechanic":
				errors.append("Level %d choice must add a mechanic: %s" % [level, choice_id])
			_validate_choice_effects(choice_id, choice.get("effects", {}), errors)
		for branch in CHARACTER_BRANCHES:
			if int(branch_counts[branch]) != 2:
				errors.append("Character %s needs two %s choices at level %s" % [character_id, branch, level_text])


## Todo marco precisa de efeito executável: parâmetros conhecidos da passiva, modificadores
## numéricos e mecânicas implementadas pela simulação.
func _validate_choice_effects(choice_id: String, raw_effects: Variant, errors: Array[String]) -> void:
	if not raw_effects is Dictionary or (raw_effects as Dictionary).is_empty():
		errors.append("Character choice has no executable effect: %s" % choice_id)
		return
	var effects := raw_effects as Dictionary
	for raw_key: Variant in effects.get("passive", {}) as Dictionary:
		var key := String(raw_key).trim_suffix("_add").trim_suffix("_mult")
		if not PassiveRuntime.DEFAULTS.has(key):
			errors.append("Unknown passive parameter in %s: %s" % [choice_id, raw_key])
	for raw_key: Variant in effects.get("modifiers", {}) as Dictionary:
		var key := String(raw_key)
		if not (key.ends_with("_add") or key.ends_with("_mult")) or not ((effects["modifiers"] as Dictionary)[raw_key] is float or (effects["modifiers"] as Dictionary)[raw_key] is int):
			errors.append("Invalid character modifier in %s: %s" % [choice_id, key])
	for raw_mechanic: Variant in effects.get("mechanics", []) as Array:
		var mechanic_id := String((raw_mechanic as Dictionary).get("id", "")) if raw_mechanic is Dictionary else ""
		if mechanic_id not in CHARACTER_MECHANICS:
			errors.append("Unknown character mechanic in %s: %s" % [choice_id, mechanic_id])
