class_name BetaCharacterFactory
extends RefCounted


func create_build(definition: Dictionary) -> CharacterBuild:
	var character_id := StringName(String(definition.get("id", "")))
	var build := CharacterBuild.new(character_id, int(definition.get("max_level", 20)))
	var passive_data := definition.get("passive", {}) as Dictionary
	var passive := SignaturePassiveDefinition.new(
		StringName(String(passive_data.get("id", ""))),
		character_id,
		StringName(String(passive_data.get("mechanic_id", "")))
	)
	passive.display_name = String(passive_data.get("name", passive.id))
	passive.description = String(passive_data.get("description", ""))
	passive.resource_id = StringName(String(passive_data.get("resource_id", "")))
	passive.maximum_resource = int(passive_data.get("maximum_resource", 0))
	passive.trigger_events = _string_names(passive_data.get("trigger_events", []))
	passive.spend_modes = _string_names(passive_data.get("spend_modes", []))
	build.assign_signature_passive(passive)
	var milestones := definition.get("milestones", {}) as Dictionary
	for level_text: String in milestones:
		var milestone_level := int(level_text)
		for raw_choice: Variant in milestones[level_text]:
			if not raw_choice is Dictionary:
				continue
			var choice_data := raw_choice as Dictionary
			var kind := EvolutionChoice.Kind.MECHANIC if String(choice_data.get("kind", "buff")) == "mechanic" else EvolutionChoice.Kind.BUFF
			var choice := EvolutionChoice.new(StringName(String(choice_data.get("id", ""))), kind)
			choice.display_name = String(choice_data.get("name", choice.id))
			choice.description = String(choice_data.get("description", ""))
			choice.branch = StringName(String(choice_data.get("branch", "")))
			choice.mechanic_id = StringName(String(choice_data.get("mechanic_id", "")))
			choice.stat_modifiers = (choice_data.get("stats", {}) as Dictionary).duplicate(true)
			build.add_milestone_choice(milestone_level, choice)
	return build


func _string_names(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for item: Variant in value:
			result.append(StringName(String(item)))
	return result
