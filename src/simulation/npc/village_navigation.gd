extends RefCounted

const CELL := 32.0
var _grid := AStarGrid2D.new()
var _size := Vector2.ZERO

func setup(size: Vector2, obstacles: Array) -> void:
	_size = size
	_grid.clear()
	_grid.region = Rect2i(Vector2i.ZERO, Vector2i(ceili(size.x / CELL), ceili(size.y / CELL)))
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.offset = Vector2(CELL, CELL) * 0.5
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for rect: Rect2 in obstacles:
		var expanded := rect.grow(12.0)
		for x in range(maxi(0, floori(expanded.position.x / CELL)), mini(_grid.region.end.x, ceili(expanded.end.x / CELL))):
			for y in range(maxi(0, floori(expanded.position.y / CELL)), mini(_grid.region.end.y, ceili(expanded.end.y / CELL))):
				_grid.set_point_solid(Vector2i(x, y))

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := _cell(from)
	var finish := _cell(to)
	if _grid.is_point_solid(start) or _grid.is_point_solid(finish):
		return PackedVector2Array()
	var path := _grid.get_point_path(start, finish)
	if not path.is_empty():
		path.remove_at(0)
		path.append(to)
	return path

func _cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(point.x / CELL), 0, _grid.region.end.x - 1), clampi(floori(point.y / CELL), 0, _grid.region.end.y - 1))
