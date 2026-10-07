extends RefCounted


static func frames(source: Image, column_count: int = 4, row_count: int = 4) -> Array[Image]:
	source.convert(Image.FORMAT_RGBA8)
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var color := source.get_pixel(x, y)
			source.set_pixel(x, y, Color(color, 1.0) if color.a >= 0.7 else Color.TRANSPARENT)
	if column_count == 5:
		return _locomotion_frames(source, column_count, row_count)
	var rows := _cuts(source, false, row_count)
	var result: Array[Image] = []
	for row in range(row_count):
		var strip := source.get_region(Rect2i(0, rows[row], source.get_width(), rows[row + 1] - rows[row]))
		var columns := _cuts(strip, true, column_count)
		for column in range(column_count):
			result.append(strip.get_region(Rect2i(columns[column], 0, columns[column + 1] - columns[column], strip.get_height())))
	return result


# Humanoid sheets can stagger baselines between columns; cut each lane separately.
static func _locomotion_frames(source: Image, column_count: int, row_count: int) -> Array[Image]:
	var columns := _cuts(source, true, column_count)
	var result: Array[Image] = []
	result.resize(column_count * row_count)
	for column in range(column_count):
		var lane := source.get_region(Rect2i(columns[column], 0, columns[column + 1] - columns[column], source.get_height()))
		var rows := _cuts(lane, false, row_count)
		for row in range(row_count):
			result[row * column_count + column] = lane.get_region(Rect2i(0, rows[row], lane.get_width(), rows[row + 1] - rows[row]))
	return result


# Generated sheets keep row order, but gutters need not be exactly equidistant.
static func _cuts(source: Image, vertical: bool, count: int = 4) -> Array[int]:
	var length := source.get_width() if vertical else source.get_height()
	var span := source.get_height() if vertical else source.get_width()
	var occupied: Array[bool] = []
	for line in range(length):
		var used := false
		for offset in range(span):
			if source.get_pixel(line if vertical else offset, offset if vertical else line).a > 0.0:
				used = true
				break
		occupied.append(used)
	var cuts: Array[int] = [0]
	for index in range(1, count):
		var target := roundi(float(index) * length / count)
		var radius := roundi(float(length) / (count * 4))
		var best := target
		var distance := length
		var start := -1
		for line in range(maxi(0, target - radius), mini(length, target + radius + 1)):
			if not occupied[line] and start < 0:
				start = line
			if start >= 0 and (occupied[line] or line == mini(length - 1, target + radius)):
				var end := line if occupied[line] else line + 1
				var middle := (start + end) / 2
				if end - start >= 3 and absi(middle - target) < distance:
					best = middle
					distance = absi(middle - target)
				start = -1
		cuts.append(best)
	cuts.append(length)
	return cuts
