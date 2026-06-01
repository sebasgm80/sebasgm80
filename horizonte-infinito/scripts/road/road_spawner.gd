extends Node2D
## Road spawner for Horizonte Infinito.
## Manages a pool of road segments for infinite scrolling.

const ROAD_SEGMENT_SCENE: PackedScene = preload("res://scenes/road/road_segment.tscn")

var _pool: Array[Node2D] = []
var _active: Array[Node2D] = []
var _next_spawn_x: float = 0.0
var scroll_speed: float = 0.0

func _ready() -> void:
	# Pre-instantiate pool
	for i in GlobalConstants.MAX_ACTIVE_SEGMENTS:
		var segment: Node2D = ROAD_SEGMENT_SCENE.instantiate()
		segment.set_process(false)
		segment.visible = false
		_pool.append(segment)
		add_child(segment)
	# Spawn initial segments to fill the screen
	var segments_needed: int = int(ceil(GlobalConstants.SCREEN_WIDTH / float(GlobalConstants.ROAD_SEGMENT_WIDTH))) + 2
	for i in segments_needed:
		_spawn_segment()

func set_scroll_speed(speed: float) -> void:
	scroll_speed = speed

func _physics_process(delta: float) -> void:
	if scroll_speed <= 0.0:
		return
	# Move all active segments left
	for segment in _active:
		segment.position.x -= scroll_speed * delta
	# Check for segments that exited the screen
	for segment in _active.duplicate():
		if segment.position.x < -GlobalConstants.ROAD_SEGMENT_WIDTH:
			_return_segment(segment)
	# Spawn new segments if needed
	if _active.size() > 0:
		var last_segment: Node2D = _active[_active.size() - 1]
		if last_segment.position.x < GlobalConstants.SCREEN_WIDTH:
			_spawn_segment()

func _spawn_segment() -> Node2D:
	var segment: Node2D
	if _pool.size() > 0:
		segment = _pool.pop_back()
	else:
		segment = ROAD_SEGMENT_SCENE.instantiate()
		add_child(segment)
	segment.position.x = _next_spawn_x
	segment.position.y = 0.0
	segment.set_process(true)
	segment.visible = true
	_active.append(segment)
	_next_spawn_x += GlobalConstants.ROAD_SEGMENT_WIDTH
	return segment

func _return_segment(segment: Node2D) -> void:
	_active.erase(segment)
	segment.set_process(false)
	segment.visible = false
	_pool.append(segment)
