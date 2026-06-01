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

## 2026-06-01 — Task 11: Main Scene Assembled
- Created `scripts/main.gd` — Node2D controller that wires all 4 systems
- `@onready` references: car, road_spawner, parallax, hud (typed)
- `_physics_process(delta)` drives all systems via car's `current_speed`
- Created `scenes/main.tscn` — Godot 4.x format=3 with 5 ext_resources
- Main scene references all 4 systems as PackedScene instances:
  1. ParallaxBackground (z_index=0, background)
  2. RoadSpawner (z_index=1, road on parallax)
  3. Car (z_index=2, car on top of road)
  4. HUD (CanvasLayer, auto-renders on top)
- Updated `project.godot`: `run/main_scene="res://scenes/main.tscn"`
- Z-ordering: parallax(0) → road(1) → car(2) → HUD (CanvasLayer auto-top)
- No LSP for GDScript — verified syntax manually

## 2026-06-01 — Task: Lane Transition Polish
- Verified all requirements: EASE_OUT+TRANS_QUAD, cooldown 0.1s, input guards, lane limits
- Added `queue_redraw()` in `_physics_process` for _draw() to update after position changes
- Added subtle rotation effect (±0.05 rad) during lane change for visual polish:
  - Tilt in movement direction during first half of tween
  - Return to 0 rotation during second half with EASE_IN
- Tween structure: position y tween + parallel rotation tween (forward + return)

## 2026-06-01 — Final QA Verification (Tasks 1-10)

### Files Verified
- 10 .gd scripts: constants.gd, car_controller.gd, road_segment.gd, road_spawner.gd, parallax_scroller.gd, hud.gd, main.gd, mountain_drawer.gd, tree_drawer.gd, guardrail_drawer.gd
- 6 .tscn scenes: main.tscn, car.tscn, road_segment.tscn, road_spawner.tscn, parallax_background.tscn, hud.tscn
- 1 project.godot

### Task 1 — Project Scaffolding: ✅ PASS
- [x] `scripts/globals/constants.gd` exists with all 31 typed constants (now 32 after fix)
- [x] `GlobalConstants` registered as autoload in project.godot [autoload] section
- [x] Input Map has 4 actions: move_up, move_down, speed_up, speed_down (WASD + arrows)

### Task 2 — Car Sprite: ✅ PASS
- [x] `scenes/car/car.tscn` exists with CharacterBody2D root
- [x] Car draws itself via `_draw()` (body + cabin + wheels)
- [x] CollisionShape2D present with RectangleShape2D (120×60)

### Task 3 — Road Segment: ✅ PASS
- [x] `scenes/road/road_segment.tscn` exists with Node2D root
- [x] Road draws via `_draw()` (asphalt, center line, edges, guardrails)
- [x] VisibleOnScreenNotifier2D attached with aabb = Rect2(-200, -540, 400, 1080)

### Task 4 — Parallax Background: ✅ PASS
- [x] `scenes/world/parallax_background.tscn` exists with ParallaxBackground root
- [x] 4 ParallaxLayer children with motion_scale: 0.1 (Sky), 0.3 (Mountains), 0.7 (Trees), 1.0 (Guardrail)
- [x] Camera2D with current=true
- [x] Mirroring configured on all layers

### Task 5 — Car Controller: ✅ PASS
- [x] Speed control via `Input.is_action_pressed` in `_physics_process`
- [x] Lane switching via `_unhandled_input` with tween (EASE_OUT + TRANS_QUAD)
- [x] Speed clamped [CAR_MIN_SPEED=50, CAR_MAX_SPEED=500]
- [x] Lane limits enforced (move_up only lane 1→2, move_down only lane 2→1)

### Task 6 — Road Spawner: ✅ PASS
- [x] Object pool pattern (pre-instantiate MAX_ACTIVE_SEGMENTS=15 segments)
- [x] `set_scroll_speed()` method exposed
- [x] No queue_free() — segments recycled via pool
- [x] Segments move left based on scroll_speed

### Task 7 — Parallax Scroll: ✅ PASS
- [x] `scroll_offset.x` updated per frame based on speed
- [x] Mirroring configured for infinite tiling

### Task 8 — HUD: ✅ PASS
- [x] CanvasLayer root with Label showing speed
- [x] `update_speed(speed: float)` formats as "%d km/h"

### Task 9 — Main Scene: ✅ PASS
- [x] main.tscn wires all 4 systems (ParallaxBackground, RoadSpawner, Car, HUD)
- [x] main.gd reads car.current_speed and drives spawner/parallax/hud
- [x] project.godot has run/main_scene set to "res://scenes/main.tscn"

### Task 10 — Lane Transition Polish: ✅ PASS
- [x] EASE_OUT + TRANS_QUAD on position tween
- [x] Cooldown 0.1s after lane change (_lane_change_cooldown)
- [x] Input blocked during tween (_is_changing_lane flag)
- [x] Subtle rotation effect (±0.05 rad) during lane change
- [x] queue_redraw() in _physics_process

### Additional Checks: ✅ PASS
- [x] No TODO/FIXME/HACK comments found in any .gd file
- [x] No queue_free() in road_spawner.gd (object pool pattern confirmed)
- [x] No RigidBody2D or complex physics used
- [x] No external textures or assets (all via _draw() and ColorRect)
- [x] No hardcoded magic numbers outside constants.gd (FIXED: guardrail_drawer.gd)

### Bug Found and Fixed
- **guardrail_drawer.gd**: Had hardcoded 1920 values for SCREEN_WIDTH and 200 for post spacing
- **Fix applied**: Added `GUARDRAIL_POST_SPACING: int = 200` to constants.gd
- **Fix applied**: Updated guardrail_drawer.gd to use `GlobalConstants.SCREEN_WIDTH` and `GlobalConstants.GUARDRAIL_POST_SPACING`

### Constants Count
- Before fix: 31 constants
- After fix: 32 constants (added GUARDRAIL_POST_SPACING)

### Verification Method
- Read every .gd file in project
- Read every .tscn file in project
- Read project.godot
- Grep for TODO, FIXME, HACK, queue_free, RigidBody
- Grep for hardcoded numeric values outside constants.gd

### Conclusion
All 10 tasks' acceptance criteria are verified PASS. One minor bug fixed (hardcoded values in guardrail_drawer.gd). Project is ready for testing.
