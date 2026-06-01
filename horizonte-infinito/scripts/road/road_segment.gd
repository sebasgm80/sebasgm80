extends Node2D
## Road segment for Horizonte Infinito.
## A single segment of the infinite scrolling road.

signal screen_exited

func _draw() -> void:
	var width: float = GlobalConstants.ROAD_SEGMENT_WIDTH
	var height: float = GlobalConstants.SCREEN_HEIGHT
	var lane_center_y: float = (GlobalConstants.LANE_1_Y + GlobalConstants.LANE_2_Y) / 2.0
	
	# Asphalt background
	draw_rect(
		Rect2(0, 0, width, height),
		GlobalConstants.COLOR_ROAD
	)
	
	# Center lane line (dashed effect - solid for now)
	draw_rect(
		Rect2(0, lane_center_y - GlobalConstants.LANE_LINE_OFFSET, width, GlobalConstants.LANE_LINE_HEIGHT),
		GlobalConstants.COLOR_LANE_LINE
	)
	
	# Left edge
	draw_rect(
		Rect2(0, 0, GlobalConstants.ROAD_EDGE_WIDTH, height),
		GlobalConstants.COLOR_ROAD_EDGE
	)
	
	# Right edge
	draw_rect(
		Rect2(width - GlobalConstants.ROAD_EDGE_WIDTH, 0, GlobalConstants.ROAD_EDGE_WIDTH, height),
		GlobalConstants.COLOR_ROAD_EDGE
	)
	
	# Top guardrail
	draw_rect(
		Rect2(0, GlobalConstants.LANE_2_Y - GlobalConstants.GUARDRAIL_OFFSET, width, GlobalConstants.GUARDRAIL_BAR_HEIGHT),
		GlobalConstants.COLOR_GUARDRAIL
	)
	
	# Bottom guardrail
	draw_rect(
		Rect2(0, GlobalConstants.LANE_1_Y + GlobalConstants.GUARDRAIL_OFFSET, width, GlobalConstants.GUARDRAIL_BAR_HEIGHT),
		GlobalConstants.COLOR_GUARDRAIL
	)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	screen_exited.emit()