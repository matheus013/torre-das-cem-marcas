extends SceneTree

const CatalogScript := preload("res://src/gameplay/content/beta_content_catalog.gd")
const FactoryScript := preload("res://src/gameplay/progression/beta_character_factory.gd")


func _init() -> void:
	var catalog: RefCounted = CatalogScript.new()
	if not bool(catalog.call("load_from")):
		_fail("Beta character catalog failed validation")
		return
	var factory: RefCounted = FactoryScript.new()
	var definitions: Array = catalog.call("collection", "playable_characters")
	if definitions.size() != 4:
		_fail("Beta must contain exactly four playable characters")
		return
	for definition: Dictionary in definitions:
		var build := factory.call("create_build", definition) as CharacterBuild
		if build == null or not build.is_ready_for_play() or build.max_level != 100:
			_fail("Character build was not initialized up to level 100")
			return
		for milestone in range(10, 101, 10):
			if (build.milestone_choices.get(milestone, []) as Array).size() != 6:
				_fail("Character tree does not expose six choices at level %d" % milestone)
				return
		# Percorre os dez marcos alternando a posição escolhida para cobrir as três linhas.
		var pick := 0
		while build.level < build.max_level or build.has_pending_milestone():
			if build.has_pending_milestone():
				var options := build.milestone_choices[build.level] as Array
				if not build.choose_milestone((options[pick % options.size()] as EvolutionChoice).id):
					_fail("Milestone %d choice could not be selected" % build.level)
					return
				pick += 1
			elif not build.level_up():
				_fail("Level %d could not advance" % build.level)
				return
		if build.level != 100 or build.selected_milestones.size() != 10 or build.level_up():
			_fail("Full progression must stop at level 100 with ten choices")
			return
		if build.unspent_stat_points != 450:
			_fail("Full progression must grant 450 distributable points (got %d)" % build.unspent_stat_points)
			return
	print("BETA_CHARACTERS_OK: four passives and ten-milestone trees up to level 100 validated")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
