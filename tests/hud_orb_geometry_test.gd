extends SceneTree

## Regressão (2026-10-08): com Vida ou Fôlego quase no fim, o núcleo do líquido do orbe descia abaixo
## do fundo e a interseção com o círculo gerava lascas que não triangulam ("Invalid polygon data,
## triangulation failed" em combat_hud._draw_orb). Todo polígono devolvido precisa triangular.

const HudScript := preload("res://src/prototype/village/combat_hud.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var checked := 0
	for step in range(0, 1001):
		var ratio := float(step) / 1000.0
		for frame in range(0, 40):
			var layers: Array = HudScript.orb_liquid(Vector2(640.5, 674.0), 40.0, ratio, float(frame) * 0.137 + 1.3)
			for layer in [layers[0], layers[1]]:
				for polygon: PackedVector2Array in layer:
					checked += 1
					if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty():
						return _fail("Orb liquid polygon does not triangulate at ratio %.3f" % ratio)
	var full: Array = HudScript.orb_liquid(Vector2(100.0, 100.0), 40.0, 1.0, 0.0)
	var half: Array = HudScript.orb_liquid(Vector2(100.0, 100.0), 40.0, 0.5, 0.0)
	if (full[0] as Array).is_empty() or (half[1] as Array).is_empty():
		return _fail("Orb liquid must still be drawn when half or full")
	print("HUD_ORB_GEOMETRY_OK: %d liquid polygons triangulate from empty to full" % checked)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
