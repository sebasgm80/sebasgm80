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