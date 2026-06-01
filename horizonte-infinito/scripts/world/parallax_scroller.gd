extends ParallaxBackground
## Parallax scroll controller for Horizonte Infinito.
## Moves all parallax layers based on car speed.
## TODO: Implement scroll logic in Task 7.

var scroll_speed: float = 0.0

func set_scroll_speed(speed: float) -> void:
	scroll_speed = speed

func _physics_process(delta: float) -> void:
	scroll_offset.x += scroll_speed * delta