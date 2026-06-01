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

# === Physics Process ===
func _physics_process(delta: float) -> void:
	# Speed control
	if Input.is_action_pressed("speed_up"):
		current_speed = minf(current_speed + GlobalConstants.CAR_ACCELERATION * delta, GlobalConstants.CAR_MAX_SPEED)
	if Input.is_action_pressed("speed_down"):
		current_speed = maxf(current_speed - GlobalConstants.CAR_ACCELERATION * delta, GlobalConstants.CAR_MIN_SPEED)

	# Lane change cooldown
	if _lane_change_cooldown > 0.0:
		_lane_change_cooldown -= delta

# === Input Handling ===
func _unhandled_input(event: InputEvent) -> void:
	if _is_changing_lane or _lane_change_cooldown > 0.0:
		return

	if event.is_action_pressed("move_up") and _current_lane == 1:
		_change_lane(2)
	elif event.is_action_pressed("move_down") and _current_lane == 2:
		_change_lane(1)

# === Lane Change Methods ===
func _change_lane(target_lane: int) -> void:
	_is_changing_lane = true
	_current_lane = target_lane
	var target_y: float = GlobalConstants.LANE_2_Y if target_lane == 2 else GlobalConstants.LANE_1_Y
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y", target_y, GlobalConstants.LANE_CHANGE_DURATION)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_on_lane_change_complete)

func _on_lane_change_complete() -> void:
	_is_changing_lane = false
	_lane_change_cooldown = GlobalConstants.LANE_CHANGE_COOLDOWN