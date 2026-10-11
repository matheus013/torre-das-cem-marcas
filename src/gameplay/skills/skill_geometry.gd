class_name SkillGeometry
extends RefCounted


static func in_cone(point: Vector2, origin: Vector2, direction: Vector2, radius: float, angle: float) -> bool:
	var offset := point - origin
	# Cone de volta inteira (Ceifa Giratória) é um círculo: o ponto exatamente atrás ficava de fora
	# por arredondamento de angle_to em algumas plataformas (falhava no CI em Linux).
	if angle >= TAU - 0.01:
		return offset.length() <= radius
	return offset.length() <= radius and (offset.length() < 0.001 or absf(direction.angle_to(offset)) <= angle * 0.5)


static func orbit_points(center: Vector2, radius: float, phase: float, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in range(clampi(count, 1, 8)):
		result.append(center + Vector2.RIGHT.rotated(phase + TAU * index / float(clampi(count, 1, 8))) * radius)
	return result
