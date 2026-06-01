extends Node2D
## Draws 5-7 mountain triangles for the parallax background.

func _draw() -> void:
	var mountains: Array[Dictionary] = [
		{"x": 100.0, "height": 350.0, "width": 300.0},
		{"x": 400.0, "height": 280.0, "width": 250.0},
		{"x": 700.0, "height": 400.0, "width": 350.0},
		{"x": 1050.0, "height": 320.0, "width": 280.0},
		{"x": 1400.0, "height": 360.0, "width": 320.0},
		{"x": 1700.0, "height": 300.0, "width": 260.0},
	]

	for m in mountains:
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(m["x"] - m["width"] / 2.0, GlobalConstants.SCREEN_HEIGHT),
			Vector2(m["x"], GlobalConstants.SCREEN_HEIGHT - m["height"]),
			Vector2(m["x"] + m["width"] / 2.0, GlobalConstants.SCREEN_HEIGHT),
		])
		draw_colored_polygon(points, GlobalConstants.COLOR_MOUNTAIN)