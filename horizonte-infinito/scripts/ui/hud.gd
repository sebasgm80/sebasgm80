extends CanvasLayer
## HUD for Horizonte Infinito.
## Displays speedometer and other UI elements.

@onready var speed_label: Label = $SpeedLabel
@onready var speed_bg: ColorRect = $SpeedBackground

func _ready() -> void:
	update_speed(0.0)

func update_speed(speed: float) -> void:
	if speed_label:
		speed_label.text = "%d km/h" % int(speed)