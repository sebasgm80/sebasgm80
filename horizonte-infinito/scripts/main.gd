extends Node2D
## Main scene controller for Horizonte Infinito.
## Wires all game systems together.

@onready var car = $Car
@onready var road_spawner = $RoadSpawner
@onready var parallax = $ParallaxBackground
@onready var hud = $HUD

func _physics_process(delta: float) -> void:
	var speed: float = car.current_speed
	road_spawner.set_scroll_speed(speed)
	parallax.set_scroll_speed(speed)
	hud.update_speed(speed)