# Learnings — Sistema de Conducción 2D

## 2026-06-01 — Session Start
- Project: Godot 4.6, Mobile renderer, 1920×1080
- Empty project (only default files)
- All constants defined in GlobalConstants autoload
- Input Map: move_up/down, speed_up/down (WASD + arrows)

## 2026-06-01 — Scaffolding Complete
- Created `scripts/globals/constants.gd` with class_name GlobalConstants
- Added 31 typed constants (dimensions, car, road, parallax, colors)
- Added 4 Input Map actions in project.godot [input] section
- Registered GlobalConstants autoload in [autoload] section
- No LSP for GDScript available — verified syntax manually
## 2026-06-01 — Car Scene Created
- Created `scenes/car/car.tscn` with CharacterBody2D root
- Created `scripts/car/car_controller.gd` with geometric car drawing using `_draw()`
- Car rendered as red body + darker cabin + black wheels
- CollisionShape2D with RectangleShape2D (120×60)
- Position initialized to Vector2(576, 540) via GlobalConstants
- No LSP available for GDScript — verified syntax manually
- Scene uses proper Godot 4.x .tscn format with ext_resource reference
## 2026-06-01 — Road Segment Created
- Created `scenes/road/road_segment.tscn` Node2D scene
- Created `scripts/road/road_segment.gd` with `_draw()` for road geometry
- Road renders: gray asphalt (COLOR_ROAD), white center line (COLOR_LANE_LINE), dark edges (COLOR_ROAD_EDGE), gray guardrails (COLOR_GUARDRAIL)
- VisibleOnScreenNotifier2D attached with aabb = Rect2(-200, -540, 400, 1080) to match segment size
- Size: 400×1080 pixels (ROAD_SEGMENT_WIDTH × SCREEN_HEIGHT)
- Guardrails positioned at LANE_2_Y - 80 (top) and LANE_1_Y + 80 (bottom)
- Signal `screen_exited` emitted when segment leaves screen
- .tscn uses Godot 4.x format=3 with uid for resources

## 2026-06-01 — Task 4: Parallax Background Created
- Created `scenes/world/parallax_background.tscn` with ParallaxBackground root
- Attached `scripts/world/parallax_scroller.gd` (base structure, no scroll logic yet)
- 4 ParallaxLayer children with motion_scale values: 0.1, 0.3, 0.7, 1.0
- Created 3 drawer scripts for visual content:
  - `mountain_drawer.gd` — draws 6 mountain triangles
  - `tree_drawer.gd` — draws 10 tree shapes (trunk + canopy)
  - `guardrail_drawer.gd` — draws horizontal bars + vertical posts
- SkyLayer uses ColorRect 1920×1080 with COLOR_SKY
- All layers have mirroring enabled for tiling
- Camera2D attached with current=true
- No LSP available for GDScript — verified syntax manually by reading back files

## 2026-06-01 — Task 5: Car Controller Implemented
- Added `_physics_process(delta)` for continuous speed control via `Input.is_action_pressed()`
- Added `_unhandled_input(event)` for discrete lane changes via `event.is_action_pressed()`
- Added `_change_lane(target_lane)` using `create_tween()` with EASE_OUT + TRANS_QUAD
- Added `_on_lane_change_complete()` callback to reset `_is_changing_lane` and set cooldown
- Lane switching guarded by `_is_changing_lane` flag and `_lane_change_cooldown` (0.1s)
- Speed clamped to [CAR_MIN_SPEED=50, CAR_MAX_SPEED=500] via `minf()`/`maxf()`
- All values sourced from GlobalConstants (CAR_ACCELERATION, CAR_MIN/MAX_SPEED, LANE_CHANGE_DURATION, etc.)
- Input validation: only `move_up` when `_current_lane == 1`, only `move_down` when `_current_lane == 2`

## 2026-06-01 — Task 7: Parallax Scroll System Complete
- Removed TODO comment from `parallax_scroller.gd` (logic already implemented)
- `ParallaxBackground.scroll_offset` handles automatic per-layer movement via `motion_scale`
- Each ParallaxLayer (0.1, 0.3, 0.7, 1.0) moves proportionally without manual per-layer code
- Mirroring already configured in `.tscn` for infinite tiling
- No LSP for GDScript — verified syntax by reading back file

## 2026-06-01 — Task 8: Road Spawner Complete
- Created `scripts/road/road_spawner.gd` with object pool pattern
- Pool pre-instantiates MAX_ACTIVE_SEGMENTS=15 segments in `_ready()`
- `_spawn_segment()` recycles from pool or instantiates new if pool empty
- `_return_segment()` disables segment and returns to pool (no queue_free)
- `_physics_process()` moves segments left based on `scroll_speed`, recycles when `x < -ROAD_SEGMENT_WIDTH`
- `set_scroll_speed(speed)` allows external control of scroll speed
- Created `scenes/road/road_spawner.tscn` with Node2D root + script attached
- Uses `preload()` for ROAD_SEGMENT_SCENE (compile-time, not runtime load)
- All dimensions from GlobalConstants (SCREEN_WIDTH=1920, ROAD_SEGMENT_WIDTH=400, etc.)
- No LSP for GDScript — verified syntax by reading back files

## 2026-06-01 — Task 10: HUD Speedometer Created
- Created `scripts/ui/hud.gd` with CanvasLayer root
- `@onready` pattern for node references (typed: Label, ColorRect)
- `update_speed(speed: float)` formats as "%d km/h" via string formatting
- Created `scenes/ui/hud.tscn` with proper Godot 4.x format=3
- SpeedBackground ColorRect: offset 1620,20 to 1900,80, color(0,0,0,0.5)
- SpeedLabel Label: offset 1630,25 to 1890,75, h-align RIGHT(2), v-align CENTER(1)
- Font size 36, white color — readable at 1920×1080
- No LSP available for GDScript — verified syntax by reading files back
