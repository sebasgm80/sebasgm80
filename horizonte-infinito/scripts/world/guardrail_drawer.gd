extends Node2D
## Draws guardrail bars and vertical posts for the parallax background.

func _draw() -> void:
	# Horizontal bars at top and bottom of road area
	draw_rect(Rect2(0, GlobalConstants.LANE_2_Y - GlobalConstants.GUARDRAIL_OFFSET, GlobalConstants.SCREEN_WIDTH, GlobalConstants.GUARDRAIL_BAR_HEIGHT), GlobalConstants.COLOR_GUARDRAIL)
	draw_rect(Rect2(0, GlobalConstants.LANE_1_Y + GlobalConstants.GUARDRAIL_OFFSET, GlobalConstants.SCREEN_WIDTH, GlobalConstants.GUARDRAIL_BAR_HEIGHT), GlobalConstants.COLOR_GUARDRAIL)

	# Vertical posts every GUARDRAIL_POST_SPACING px
	for x in range(0, GlobalConstants.SCREEN_WIDTH, GlobalConstants.GUARDRAIL_POST_SPACING):
		draw_rect(Rect2(x, GlobalConstants.LANE_2_Y - GlobalConstants.GUARDRAIL_POST_OFFSET_Y, GlobalConstants.GUARDRAIL_POST_WIDTH, GlobalConstants.GUARDRAIL_POST_HEIGHT), GlobalConstants.COLOR_GUARDRAIL.darkened(0.3))