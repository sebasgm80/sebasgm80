extends CharacterBody2D
## Car controller for Horizonte Infinito.
## Handles lane switching and speed control.

# === Exports ===
@export var current_speed: float = GlobalConstants.CAR_BASE_SPEED

# === Private Variables ===
var _current_lane: int = 1  # 1 = bottom lane (LANE_1_Y), 2 = top lane (LANE_2_Y)
var _is_changing_lane: bool = false
var _lane_change_cooldown: float = 0.0

# === Onready ===

func _ready() -> void:
	position = Vector2(GlobalConstants.CAR_X_POSITION, GlobalConstants.LANE_1_Y)

func _draw() -> void:
	# Car body
	draw_rect(
		Rect2(-GlobalConstants.CAR_WIDTH / 2.0, -GlobalConstants.CAR_HEIGHT / 2.0,
		      GlobalConstants.CAR_WIDTH, GlobalConstants.CAR_HEIGHT),
		GlobalConstants.COLOR_CAR
	)
	# Cabin (darker, smaller rectangle on top)
	draw_rect(
		Rect2(-GlobalConstants.CAR_WIDTH / 2.0 + 30, -GlobalConstants.CAR_HEIGHT / 2.0 - 20,
		      40, 20),
		GlobalConstants.COLOR_CAR.darkened(0.2)
	)
	# Wheels (black circles)
	draw_circle(
		Vector2(-GlobalConstants.CAR_WIDTH / 2.0 + 20, GlobalConstants.CAR_HEIGHT / 2.0),
		10, Color(0.1, 0.1, 0.1)
	)
	draw_circle(
		Vector2(GlobalConstants.CAR_WIDTH / 2.0 - 20, GlobalConstants.CAR_HEIGHT / 2.0),
		10, Color(0.1, 0.1, 0.1)
	)