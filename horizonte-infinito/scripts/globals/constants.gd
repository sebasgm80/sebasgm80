extends Node

class_name GlobalConstants

# === Dimensions ===
const SCREEN_WIDTH: int = 1920
const SCREEN_HEIGHT: int = 1080
const LANE_1_Y: float = 540.0
const LANE_2_Y: float = 380.0
const CAR_X_POSITION: float = 576.0

# === Car ===
const CAR_WIDTH: float = 120.0
const CAR_HEIGHT: float = 60.0
const CAR_BASE_SPEED: float = 200.0
const CAR_MIN_SPEED: float = 50.0
const CAR_MAX_SPEED: float = 500.0
const CAR_ACCELERATION: float = 150.0
const LANE_CHANGE_DURATION: float = 0.3
const LANE_CHANGE_COOLDOWN: float = 0.1

# === Road ===
const ROAD_SEGMENT_WIDTH: int = 400
const ROAD_SEGMENT_HEIGHT: int = 1080
const MAX_ACTIVE_SEGMENTS: int = 15

# === Parallax Ratios ===
const PARALLAX_SKY: float = 0.1
const PARALLAX_MOUNTAINS: float = 0.3
const PARALLAX_TREES: float = 0.7
const PARALLAX_GUARDRAIL: float = 1.0

# === Guardrail ===
const GUARDRAIL_POST_SPACING: int = 200

# === Car Visuals ===
const CAR_CABIN_OFFSET_X: float = 30.0
const CAR_CABIN_WIDTH: float = 40.0
const CAR_CABIN_HEIGHT: float = 20.0
const CAR_CABIN_OFFSET_Y: float = 20.0
const CAR_WHEEL_RADIUS: float = 10.0
const CAR_WHEEL_OFFSET_X: float = 20.0
const CAR_WHEEL_OFFSET_Y: float = 0.0
const COLOR_CAR_WHEEL: Color = Color(0.1, 0.1, 0.1)
const CAR_LANE_TILT: float = 0.05

# === Road Visuals ===
const LANE_LINE_OFFSET: float = 2.0
const LANE_LINE_HEIGHT: float = 4.0
const ROAD_EDGE_WIDTH: float = 10.0
const GUARDRAIL_OFFSET: float = 80.0
const GUARDRAIL_BAR_HEIGHT: float = 6.0
const GUARDRAIL_POST_WIDTH: float = 8.0
const GUARDRAIL_POST_HEIGHT: float = 200.0
const GUARDRAIL_POST_OFFSET_Y: float = 100.0

# === Tree Visuals ===
const COLOR_TREE_TRUNK: Color = Color(0.4, 0.25, 0.1)
const TREE_TRUNK_WIDTH: float = 10.0
const TREE_TRUNK_HEIGHT: float = 30.0
const TREE_CANOPY_WIDTH: float = 50.0
const TREE_CANOPY_HEIGHT: float = 30.0

# === Colors ===
const COLOR_SKY: Color = Color(0.4, 0.6, 0.9)
const COLOR_MOUNTAIN: Color = Color(0.3, 0.4, 0.3)
const COLOR_TREE: Color = Color(0.2, 0.5, 0.2)
const COLOR_ROAD: Color = Color(0.25, 0.25, 0.25)
const COLOR_LANE_LINE: Color = Color(0.9, 0.9, 0.9)
const COLOR_ROAD_EDGE: Color = Color(0.15, 0.15, 0.15)
const COLOR_CAR: Color = Color(0.8, 0.2, 0.2)
const COLOR_GUARDRAIL: Color = Color(0.5, 0.5, 0.5)