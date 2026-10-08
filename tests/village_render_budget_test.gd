extends SceneTree

## Regressão (2026-10-07): a vila rodava a ~7 FPS. As ~1.600 bordas de grama das ruas eram desenhadas
## como polígonos soltos, triangulados a cada quadro (52 ms de CPU e ~1.750 chamadas de desenho).
## Agora são uma única malha montada uma vez; e só as luzes perto da tela acendem (no máximo 8).

const VILLAGE := "res://src/prototype/village/village_exploration.tscn"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveSlot.path = "user://render_budget_test_unused.json"
	var village := (load(VILLAGE) as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	var edges := village.get("_road_edges") as Array
	var mesh := village.get("_road_edge_mesh") as ArrayMesh
	if edges.size() < 100 or mesh == null or mesh.get_surface_count() != 1:
		return _fail("Road edges must be baked into a single mesh")
	var expected := 0
	for blob: PackedVector2Array in edges:
		expected += (blob.size() - 2) * 3
	if (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector2Array).size() != expected:
		return _fail("The baked mesh must hold every edge triangle")
	var source := FileAccess.get_file_as_string("res://src/prototype/village/village_exploration.gd")
	if source.contains("for blob in _road_edges:\n\t\t\t\t\tvar uvs"):
		return _fail("Road edges must not be drawn polygon by polygon")

	# Noite: postes acesos, mas só os que alcançam a tela e no máximo LIGHT_BUDGET.
	var life: RefCounted = (village.get("_sim") as RefCounted).get("village_life")
	while String(life.call("period")) != "noite":
		life.call("advance_period")
	for _frame in range(5):
		await physics_frame
	var lights := (village.get("_village_lights") as Node2D).get_children()
	var lit := lights.filter(func(light: PointLight2D) -> bool: return light.enabled)
	if lights.size() < 20 or lit.is_empty() or lit.size() > int(village.get("LIGHT_BUDGET")):
		return _fail("At night only up to %d lamps near the screen may be lit, got %d of %d" % [int(village.get("LIGHT_BUDGET")), lit.size(), lights.size()])
	var view := village.call("_visible_world_rect") as Rect2
	for light: PointLight2D in lit:
		if not view.grow(light.texture.get_width() * 0.5 * light.texture_scale).has_point(light.position):
			return _fail("A lit lamp is out of reach of the screen")
	village.queue_free()
	await process_frame
	print("VILLAGE_RENDER_BUDGET_OK: %d road edges in one mesh, %d of %d lamps lit at night" % [edges.size(), lit.size(), lights.size()])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
