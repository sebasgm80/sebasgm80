extends Node2D
## Draws 8-12 tree shapes (trunk + canopy) for the parallax background.

func _draw() -> void:
	var trees: Array[Dictionary] = [
		{"x": 80.0, "y": GlobalConstants.LANE_2_Y - 60.0, "h": 120.0},
		{"x": 250.0, "y": GlobalConstants.LANE_2_Y - 50.0, "h": 100.0},
		{"x": 450.0, "y": GlobalConstants.LANE_2_Y - 70.0, "h": 140.0},
		{"x": 680.0, "y": GlobalConstants.LANE_2_Y - 55.0, "h": 110.0},
		{"x": 900.0, "y": GlobalConstants.LANE_2_Y - 65.0, "h": 130.0},
		{"x": 1100.0, "y": GlobalConstants.LANE_2_Y - 45.0, "h": 90.0},
		{"x": 1300.0, "y": GlobalConstants.LANE_2_Y - 75.0, "h": 150.0},
		{"x": 1500.0, "y": GlobalConstants.LANE_2_Y - 50.0, "h": 100.0},
		{"x": 1700.0, "y": GlobalConstants.LANE_2_Y - 60.0, "h": 120.0},
		{"x": 1900.0, "y": GlobalConstants.LANE_2_Y - 55.0, "h": 110.0},
	]

	for t in trees:
		# Trunk (brown rectangle)
		draw_rect(Rect2(t["x"] - GlobalConstants.TREE_TRUNK_WIDTH / 2.0, t["y"] - t["h"] + GlobalConstants.TREE_TRUNK_HEIGHT, GlobalConstants.TREE_TRUNK_WIDTH, t["h"] - GlobalConstants.TREE_TRUNK_HEIGHT), GlobalConstants.COLOR_TREE_TRUNK)
		# Canopy (green triangle)
		var canopy_points: PackedVector2Array = PackedVector2Array([
			Vector2(t["x"] - GlobalConstants.TREE_CANOPY_WIDTH / 2.0, t["y"] - t["h"] + GlobalConstants.TREE_TRUNK_HEIGHT),
			Vector2(t["x"], t["y"] - t["h"]),
			Vector2(t["x"] + GlobalConstants.TREE_CANOPY_WIDTH / 2.0, t["y"] - t["h"] + GlobalConstants.TREE_TRUNK_HEIGHT),
		])
		draw_colored_polygon(canopy_points, GlobalConstants.COLOR_TREE)