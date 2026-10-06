extends SceneTree

## Regressão (2026-10-06): um poste do mapa novo da vila ficava sobre o ponto de retorno da Torre;
## ao sair da Torre a personagem nascia dentro da colisão e não andava mais. Todo ponto de
## chegada da vila precisa estar livre e permitir andar, e chegadas inválidas (mapa mudou, save
## antigo) são deslocadas para o ponto livre mais próximo.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(77)
	sim.add_player(1, &"eloa")
	for spec: Array in [["WORLD_SPAWN", WorldLayout.WORLD_SPAWN], ["HOUSE_RETURN", WorldLayout.HOUSE_RETURN], ["TOWER_RETURN", WorldLayout.TOWER_RETURN]]:
		if not sim.can_stand(&"village", spec[1] as Vector2):
			return _fail("%s is inside a village obstacle" % spec[0])
	for piece: Dictionary in WorldLayout.VILLAGE_PIECES:
		if String(piece["sprite"]) == "props/lamp" and (piece["base"] as Vector2).distance_to(WorldLayout.TOWER_RETURN) < 100.0:
			return _fail("A lamp stands in front of the tower door")

	# O caminho real: entrar na Torre, voltar e conseguir andar.
	var state := sim.player(1)
	sim.enter_tower(1)
	sim.leave_tower(1)
	var arrival := state["position"] as Vector2
	sim.set_move_target(1, arrival + Vector2(0.0, 150.0))
	for _frame in range(30):
		sim.step(1.0 / 30.0)
	if (state["position"] as Vector2).distance_to(arrival) < 20.0:
		return _fail("Character must walk after leaving the tower, stuck at %s" % arrival)

	# Chegada em ponto bloqueado (ex.: layout novo com save antigo) vai para o ponto livre mais próximo.
	var blocked := Vector2.ZERO
	for obstacle in WorldLayout.obstacles(&"village", 0):
		if obstacle.size.x > 60.0:
			blocked = obstacle.get_center()
			break
	sim._place(1, &"village", blocked)
	if not sim.can_stand(&"village", state["position"]) or (state["position"] as Vector2).distance_to(blocked) > 200.0:
		return _fail("Blocked arrival must move to the nearest free spot, got %s" % state["position"])
	print("VILLAGE_ARRIVAL_OK: spawn, house and tower returns are free; leaving the tower walks; blocked arrivals are nudged")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
