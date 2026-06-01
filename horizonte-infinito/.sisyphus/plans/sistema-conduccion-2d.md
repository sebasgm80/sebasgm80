# Sistema de Conducción 2D — Horizonte Infinito

## TL;DR

> **Quick Summary**: Implementar el sistema de conducción 2D lateral (side-view) con scroll horizontal, 2 carriles, parallax de 4 capas con formas geométricas, y velocímetro HUD en Godot 4.6. Sin texturas, sin física compleja, sin tráfico. Desarrollo iterativo: cada tarea se pule antes de avanzar.
>
> **Deliverables**:
> - Escena `car.tscn` — coche geométrico con cambio de carril suave (tween 0.3s)
> - Escena `road_segment.tscn` — segmento de carretera con líneas y bordes
> - Sistema de spawning procedural de carretera con pool de reciclaje
> - Sistema de parallax con 4 capas (cielo, montañas, árboles, guardarraíl)
> - HUD con velocímetro (CanvasLayer + Label)
> - Escena `main.tscn` que integra todo
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 2 waves
> **Critical Path**: Task 1 → Task 4 → Task 7 → Task 10 → Task 11 → F1-F4

---

## Context

### Original Request
Crear juego Road Trip 2D estilo anime con conducción lateral como "Keep Driving", con partes de visual novel futuras. Empezar con el sistema de conducción usando solo formas geométricas (sin texturas). Desarrollo iterativo: cada punto no se completa hasta que quede como queramos.

### Interview Summary
**Key Discussions**:
- **Vista**: Lateral (side-view) — el coche se ve de lado, la carretera hace scroll horizontal
- **Carriles**: 2 carriles (uno por dirección), el coche cambia con W/S o ↑/↓
- **Controles**: Solo teclado (WASD + flechas) mediante Input Map de Godot
- **Física**: Mínima — velocidad directa, sin inercia ni derrape (refinar después)
- **Cámara**: Coche fijo al ~30% izquierdo de la pantalla, solo se mueve en Y para cambio de carril
- **Transición de carril**: Suave con tween (~0.3s)
- **Visuales**: Parallax completo con formas geométricas — cielo, montañas, árboles, carretera, bordes
- **HUD**: Velocímetro simple (Label)
- **Tests**: QA manual por agente en Godot Editor (sin framework de testing)

**Research Findings**:
- Godot 4.6 con renderizador Mobile, resolución 1920×1080
- Proyecto vacío: solo archivos base de Godot
- Buenas prácticas Godot: GDScript tipado, signals para desacoplar, `@onready` para referencias, `preload` para escenas, Input Map para controles

### Metis Review
**Identified Gaps** (addressed):
- **Dirección del scroll**: Confirmado side-view (lateral), coche hacia la derecha, mundo se mueve a la izquierda
- **Lane change timing**: Confirmado tween suave de 0.3s
- **Edge cases**: Documentados y cubiertos en acceptance criteria de cada tarea
- **Colores y dimensiones**: Valores default concretos definidos (ver constants más abajo)
- **Memory management**: Sistema de pool con reciclaje de segmentos (máx 15 activos)
- **Scope locks**: Lista explícita de exclusiones en guardrails

---

## Work Objectives

### Core Objective
Implementar un sistema de conducción 2D lateral funcional con scroll horizontal infinito, parallax de 4 capas, cambio de carril animado, y HUD de velocidad — todo usando exclusivamente formas geométricas coloreadas.

### Concrete Deliverables
- `scenes/car/car.tscn` + `scripts/car/car_controller.gd`
- `scenes/road/road_segment.tscn` + `scripts/road/road_spawner.gd`
- `scenes/world/parallax_background.tscn`
- `scenes/ui/hud.tscn` + `scripts/ui/hud.gd`
- `scenes/main.tscn`
- `scripts/globals/constants.gd` (autoload)
- Input Map configurado en `project.godot`

### Definition of Done
- [ ] El coche se renderiza como forma geométrica en el lado izquierdo de la pantalla
- [ ] El coche cambia de carril suavemente al presionar W/S o ↑/↓ (tween 0.3s)
- [ ] La carretera hace scroll horizontal infinito (segmentos se reciclan)
- [ ] 4 capas de parallax se mueven a velocidades distintas (0.1x, 0.3x, 0.7x, 1.0x)
- [ ] El velocímetro muestra la velocidad actual
- [ ] La velocidad se controla con A/D o ←/→
- [ ] Godot Editor no muestra errores al ejecutar la escena `main.tscn`
- [ ] Cambio rápido de carril no causa bugs visuales ni de input

### Must Have
- Controles mediante Input Map (NO hardcoded keys)
- GDScript tipado (`: float`, `: Vector2`, etc.)
- Señales para comunicación entre escenas
- Sistema de pool para segmentos de carretera (máx 15 activos)
- Colores hardcodeados, no generativos

### Must NOT Have (Guardrails)
- **NO texturas** — solo `ColorRect`, `Color` en draw commands, o `Polygon2D`
- **NO física compleja** — sin `RigidBody2D`, sin inercia, sin derrape
- **NO tráfico/obstáculos** — solo carretera vacía
- **NO curvas** — carretera recta infinita
- **NO partículas** — sin polvo, chispas, efectos
- **NO sonido/música**
- **NO gamepad/touch** — solo teclado en esta iteración
- **NO menú/pausa**
- **NO generación procedural de assets** — una sola forma por tipo de elemento
- **NO save/load system**
- **NO visual novel** (futuro)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: NO
- **Automated tests**: None
- **Framework**: N/A
- **Verification**: Agent-executed QA — el agente ejecuta `main.tscn` en Godot Editor y verifica visualmente cada criterio

### QA Policy
Cada tarea incluye QA Scenarios ejecutables por agente. El agente:
1. Abre Godot Editor con el proyecto
2. Ejecuta la escena `main.tscn`
3. Verifica cada criterio observando la pantalla, logs de Godot, y propiedades de nodos
4. Captura evidencia como screenshots o output de consola
5. Guarda evidencia en `.sisyphus/evidence/task-{N}-{scenario-slug}.png`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — foundation):
├── Task 1: Project scaffolding + Input Map + constants [quick]
├── Task 2: Car sprite geométrico + escena base [quick]
├── Task 3: Road segment geométrico + escena base [quick]
└── Task 4: Parallax background con 4 capas [quick]

Wave 2 (After Wave 1 — MAX PARALLEL):
├── Task 5: Car controller (lane switching + speed) [quick]
├── Task 6: Road spawning system (pool + recycling) [quick]
├── Task 7: Parallax scroll system [quick]
└── Task 8: Speedometer HUD [quick]

Wave 3 (After Wave 2 — integration + polish):
├── Task 9: Main scene assembly [quick]
├── Task 10: Lane transition polish + edge cases [quick]
└── Task 11: QA verification completa [quick]

Wave FINAL (After ALL tasks):
├── Task F1: Plan compliance audit [oracle]
├── Task F2: Code quality review [unspecified-high]
├── Task F3: Real manual QA [unspecified-high]
└── Task F4: Scope fidelity check [deep]

Critical Path: Task 1 → Task 4 → Task 7 → Task 9 → Task 10 → F1-F4
Max Concurrent: 4 (Wave 2)
```

### Dependency Matrix
- **1**: — — 2-4, 5-8
- **2**: 1 — 5, 1
- **3**: 1 — 6, 1
- **4**: 1 — 7, 1
- **5**: 2 — 9, 2
- **6**: 3 — 9, 2
- **7**: 4 — 9, 2
- **8**: 1 — 9, 2
- **9**: 5, 6, 7, 8 — 10, 11, 3
- **10**: 9 — 11, 3
- **11**: 10 — F1-F4, 3
- **F1-F4**: 11 — —, FINAL

### Agent Dispatch Summary
- **Wave 1**: 4 tasks → `quick`
- **Wave 2**: 4 tasks → `quick`
- **Wave 3**: 3 tasks → `quick`
- **Wave FINAL**: 4 tasks → `oracle`, `unspecified-high`×2, `deep`

---

## TODOs

> Implementation + QA = ONE Task. Never separate.
> EVERY task MUST have: Recommended Agent Profile + Parallelization info + QA Scenarios.
> **A task WITHOUT QA Scenarios is INCOMPLETE. No exceptions.**

### Wave 1 — Foundation (Start Immediately, ALL PARALLEL)

- [x] 1. Project Scaffolding: Input Map + Constants Autoload

  **What to do**:
  - Configurar Input Map en Project Settings con 4 acciones:
    - `move_up`: W, Up Arrow
    - `move_down`: S, Down Arrow
    - `speed_up`: D, Right Arrow
    - `speed_down`: A, Left Arrow
  - Crear `scripts/globals/constants.gd` como autoload (`GlobalConstants`)
  - Definir todas las constantes del proyecto:
    ```gdscript
    # Dimensions
    const SCREEN_WIDTH: int = 1920
    const SCREEN_HEIGHT: int = 1080
    const LANE_1_Y: float = 540.0
    const LANE_2_Y: float = 380.0
    const CAR_X_POSITION: float = 576.0
    
    # Car
    const CAR_WIDTH: float = 120.0
    const CAR_HEIGHT: float = 60.0
    const CAR_BASE_SPEED: float = 200.0
    const CAR_MIN_SPEED: float = 50.0
    const CAR_MAX_SPEED: float = 500.0
    const CAR_ACCELERATION: float = 150.0
    const LANE_CHANGE_DURATION: float = 0.3
    const LANE_CHANGE_COOLDOWN: float = 0.1
    
    # Road
    const ROAD_SEGMENT_WIDTH: int = 400
    const ROAD_SEGMENT_HEIGHT: int = 1080
    const MAX_ACTIVE_SEGMENTS: int = 15
    
    # Parallax Ratios
    const PARALLAX_SKY: float = 0.1
    const PARALLAX_MOUNTAINS: float = 0.3
    const PARALLAX_TREES: float = 0.7
    const PARALLAX_GUARDRAIL: float = 1.0
    
    # Colors
    const COLOR_SKY: Color = Color(0.4, 0.6, 0.9)
    const COLOR_MOUNTAIN: Color = Color(0.3, 0.4, 0.3)
    const COLOR_TREE: Color = Color(0.2, 0.5, 0.2)
    const COLOR_ROAD: Color = Color(0.25, 0.25, 0.25)
    const COLOR_LANE_LINE: Color = Color(0.9, 0.9, 0.9)
    const COLOR_ROAD_EDGE: Color = Color(0.15, 0.15, 0.15)
    const COLOR_CAR: Color = Color(0.8, 0.2, 0.2)
    const COLOR_GUARDRAIL: Color = Color(0.5, 0.5, 0.5)
    ```
  - Registrar `GlobalConstants` como autoload en Project Settings

  **Must NOT do**:
  - No crear escenas ni sprites todavía
  - No hardcodear valores en otros scripts

  **Recommended Agent Profile**:
  > `quick` — configuración pura, sin lógica compleja
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]
  - **Skills Evaluated but Omitted**: N/A

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4)
  - **Blocks**: Tasks 2, 3, 4, 8
  - **Blocked By**: None

  **References**:
  - `project.godot` — Configuración de autoload e Input Map
  - Godot Input Map docs — `InputEventKey` para WASD y flechas

  **Acceptance Criteria**:
  - [ ] `scripts/globals/constants.gd` existe con todas las constantes tipadas
  - [ ] `GlobalConstants` en Project Settings > Autoload (Enable marcado)
  - [ ] Input Map tiene 4 acciones: `move_up`, `move_down`, `speed_up`, `speed_down`

  **QA Scenarios**:

  ```
  Scenario: Autoload y constantes accesibles
    Tool: Godot Editor
    Preconditions: Proyecto abierto
    Steps:
      1. Abrir Project Settings > Autoload
      2. Verificar "GlobalConstants" en la lista con path "res://scripts/globals/constants.gd"
      3. Verificar checkbox "Enable" marcado
      4. Ejecutar escena vacía y verificar Output: sin errores de carga del autoload
    Expected Result: GlobalConstants cargado sin errores
    Evidence: .sisyphus/evidence/task-1-autoload.png

  Scenario: Input Map configurado
    Tool: Godot Editor > Project Settings > Input Map
    Preconditions: Ninguna
    Steps:
      1. Abrir Input Map tab
      2. Verificar "move_up" tiene W y Up Arrow
      3. Verificar "move_down" tiene S y Down Arrow
      4. Verificar "speed_up" tiene D y Right Arrow
      5. Verificar "speed_down" tiene A y Left Arrow
    Expected Result: 4 acciones con 2 teclas cada una
    Evidence: .sisyphus/evidence/task-1-inputmap.png
  ```

  **Commit**: YES
  - Message: `feat(project): add Input Map and GlobalConstants autoload`
  - Files: `scripts/globals/constants.gd`, `project.godot`

- [x] 2. Car Sprite Geométrico + Escena Base

  **What to do**:
  - Crear directorio `scenes/car/` y `scripts/car/`
  - Crear escena `scenes/car/car.tscn` con raíz `CharacterBody2D` llamado "Car"
  - Añadir `CollisionShape2D` con `RectangleShape2D` (tamaño `CAR_WIDTH` × `CAR_HEIGHT`)
  - Dibujar el coche como forma geométrica usando `_draw()`:
    - Cuerpo principal: `draw_rect(Rect2(Vector2.ZERO, Vector2(CAR_WIDTH, CAR_HEIGHT)), COLOR_CAR)`
    - Techo (cabina): `draw_rect(Rect2(Vector2(30, -20), Vector2(40, 20)), COLOR_CAR.darkened(0.2))`
    - Ruedas: 2 círculos pequeños negros en la parte inferior
  - Posición inicial: `Vector2(CAR_X_POSITION, LANE_1_Y)`
  - Añadir script `car_controller.gd` (vacío, solo estructura base con exports)

  **Must NOT do**:
  - No añadir lógica de movimiento (va en Task 5)
  - No texturas ni sprites externos
  - No RigidBody2D

  **Recommended Agent Profile**:
  > `quick` — escena simple con CharacterBody2D y draw commands
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4)
  - **Blocks**: Task 5
  - **Blocked By**: Task 1

  **References**:
  - `GlobalConstants.CAR_WIDTH`, `CAR_HEIGHT`, `CAR_X_POSITION`, `LANE_1_Y`, `COLOR_CAR`
  - Godot `CharacterBody2D` + `_draw()` docs

  **Acceptance Criteria**:
  - [ ] `scenes/car/car.tscn` se abre sin errores en el editor
  - [ ] Coche geométrico visible (rectángulo rojo + techo + ruedas)
  - [ ] CollisionShape2D dimensionado correctamente

  **QA Scenarios**:

  ```
  Scenario: Coche se renderiza correctamente
    Tool: Godot Editor (abrir car.tscn)
    Preconditions: GlobalConstants configurado
    Steps:
      1. Abrir scenes/car/car.tscn en el editor
      2. Verificar forma de coche geométrico visible en posición (~576, 540)
      3. Verificar CollisionShape2D presente (rectángulo azul)
      4. Verificar tamaño del collider coincide con CAR_WIDTH × CAR_HEIGHT
      5. Output panel sin errores
    Expected Result: Coche geométrico visible con collider correcto
    Evidence: .sisyphus/evidence/task-2-car-scene.png

  Scenario: Sin errores al ejecutar escena aislada
    Tool: Godot Editor (F6)
    Preconditions: car.tscn abierta
    Steps:
      1. Presionar F6 para ejecutar escena actual
      2. Verificar juego inicia sin crashes
      3. Output panel: sin errores rojos
      4. Coche visible en pantalla (estático)
    Expected Result: Escena ejecuta sin errores
    Evidence: .sisyphus/evidence/task-2-car-running.png
  ```

  **Commit**: YES
  - Message: `feat(car): add geometric car scene with collision`
  - Files: `scenes/car/car.tscn`, `scripts/car/car_controller.gd`

- [x] 3. Road Segment Geométrico + Escena Base

  **What to do**:
  - Crear directorio `scenes/road/` y `scripts/road/`
  - Crear escena `scenes/road/road_segment.tscn` con raíz `Node2D`
  - Dimensiones: 400×1080
  - Dibujar segmento de carretera con `_draw()`:
    - Asfalto: `draw_rect(Rect2(0, 0, ROAD_SEGMENT_WIDTH, SCREEN_HEIGHT), COLOR_ROAD)`
    - Línea central: `draw_rect(Rect2(0, (LANE_1_Y+LANE_2_Y)/2, ROAD_SEGMENT_WIDTH, 4), COLOR_LANE_LINE)`
    - Bordes: `draw_rect(Rect2(0, 0, 10, SCREEN_HEIGHT), COLOR_ROAD_EDGE)` y borde derecho
    - Guardarraíl: `draw_rect(Rect2(0, LANE_2_Y-80, ROAD_SEGMENT_WIDTH, 6), COLOR_GUARDRAIL)`
  - Añadir `VisibleOnScreenNotifier2D` con rect grande
  - Añadir `scripts/road/road_segment.gd` (vacío, estructura base)

  **Must NOT do**:
  - No añadir lógica de spawning
  - No curvas ni variaciones

  **Recommended Agent Profile**:
  > `quick` — escena geométrica con Node2D
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4)
  - **Blocks**: Task 6
  - **Blocked By**: Task 1

  **References**:
  - `GlobalConstants.ROAD_SEGMENT_WIDTH`, `SCREEN_HEIGHT`, `LANE_1_Y`, `LANE_2_Y`
  - `GlobalConstants.COLOR_ROAD`, `COLOR_LANE_LINE`, `COLOR_ROAD_EDGE`, `COLOR_GUARDRAIL`
  - Godot `VisibleOnScreenNotifier2D` docs

  **Acceptance Criteria**:
  - [ ] `scenes/road/road_segment.tscn` se abre sin errores
  - [ ] Asfalto gris, línea central blanca, bordes oscuros, guardarraíl visibles
  - [ ] Tamaño 400×1080

  **QA Scenarios**:

  ```
  Scenario: Road segment se renderiza correctamente
    Tool: Godot Editor (abrir road_segment.tscn)
    Preconditions: GlobalConstants configurado
    Steps:
      1. Abrir scenes/road/road_segment.tscn
      2. Verificar rectángulo 400×1080 visible
      3. Verificar línea blanca horizontal en Y ~460
      4. Verificar bordes oscuros y guardarraíl gris
      5. Verificar VisibleOnScreenNotifier2D en inspector
    Expected Result: Segmento de carretera completo
    Evidence: .sisyphus/evidence/task-3-road-segment.png
  ```

  **Commit**: YES
  - Message: `feat(road): add geometric road segment scene`
  - Files: `scenes/road/road_segment.tscn`, `scripts/road/road_segment.gd`

- [x] 4. Parallax Background con 4 Capas

  **What to do**:
  - Crear directorio `scenes/world/`
  - Crear escena `scenes/world/parallax_background.tscn` con raíz `ParallaxBackground`
  - Scroll scale: `Vector2(1, 0)`
  - 4 `ParallaxLayer` hijos:
    - **Capa 1 — Cielo**: `motion_scale = (0.1, 1)` → `ColorRect` 1920×1080 azul
    - **Capa 2 — Montañas**: `motion_scale = (0.3, 1)` → 5-7 triángulos verdes oscuros con `draw_polygon()`
    - **Capa 3 — Árboles**: `motion_scale = (0.7, 1)` → 8-12 formas de árbol (rect + triángulo) con `_draw()`
    - **Capa 4 — Guardarraíl**: `motion_scale = (1.0, 1)` → postes + barras horizontales con `_draw()`
  - Añadir `Camera2D` como hijo del ParallaxBackground con `current = true`

  **Must NOT do**:
  - No scroll manual (ParallaxBackground lo maneja nativo)
  - No texturas ni assets

  **Recommended Agent Profile**:
  > `quick` — composición de nodos nativos con shapes
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3)
  - **Blocks**: Task 7
  - **Blocked By**: Task 1

  **References**:
  - Godot `ParallaxBackground` + `ParallaxLayer` docs
  - `GlobalConstants.PARALLAX_SKY/MOUNTAINS/TREES/GUARDRAIL`
  - `GlobalConstants.COLOR_SKY/MOUNTAIN/TREE/GUARDRAIL`

  **Acceptance Criteria**:
  - [ ] `scenes/world/parallax_background.tscn` existe
  - [ ] 4 ParallaxLayer con motion_scales: 0.1, 0.3, 0.7, 1.0
  - [ ] Contenido visible en cada capa
  - [ ] Camera2D configurada como current

  **QA Scenarios**:

  ```
  Scenario: Parallax layers con motion_scales correctos
    Tool: Godot Editor
    Preconditions: parallax_background.tscn abierta
    Steps:
      1. Verificar 4 hijos ParallaxLayer en Scene Tree
      2. Capa Sky: motion_scale.x = 0.1
      3. Capa Mountains: motion_scale.x = 0.3
      4. Capa Trees: motion_scale.x = 0.7
      5. Capa Guardrail: motion_scale.x = 1.0
      6. Zoom out para ver todas las capas superpuestas
    Expected Result: 4 capas con ratios correctos y contenido visible
    Evidence: .sisyphus/evidence/task-4-parallax-layers.png
  ```

  **Commit**: YES
  - Message: `feat(world): add parallax background with 4 layers`
  - Files: `scenes/world/parallax_background.tscn`

### Wave 2 — Core Systems (After Wave 1, ALL PARALLEL)

- [x] 5. Car Controller: Lane Switching + Speed Control

  **What to do**:
  - Implementar `scripts/car/car_controller.gd` en la escena `car.tscn`
  - Sistema de velocidad:
    - `var current_speed: float = CAR_BASE_SPEED`
    - En `_physics_process`: leer `speed_up`/`speed_down` del Input Map
    - `speed_up` presionado → `current_speed += CAR_ACCELERATION * delta`
    - `speed_down` presionado → `current_speed -= CAR_ACCELERATION * delta`
    - Clamp entre `CAR_MIN_SPEED` y `CAR_MAX_SPEED`
    
  - Sistema de cambio de carril:
    - `var current_lane: int = 1` (1 = inferior LANE_1_Y, 2 = superior LANE_2_Y)
    - `var is_changing_lane: bool = false`
    - `var lane_change_timer: float = 0.0`
    - En `_unhandled_input` o `_physics_process`: leer `move_up`/`move_down`
    - `move_up` → si `current_lane == 1` y `!is_changing_lane`, transicionar a lane 2
    - `move_down` → si `current_lane == 2` y `!is_changing_lane`, transicionar a lane 1
    - Usar `Tween` para animar `position.y` de `LANE_1_Y` a `LANE_2_Y` (o viceversa)
    - Duración: `LANE_CHANGE_DURATION` (0.3s)
    - Bloquear input durante la transición (usar `is_changing_lane` flag)
    - Cooldown post-transición: `LANE_CHANGE_COOLDOWN` (0.1s)
    
  - Edge cases:
    - Si ya estás en lane 2 y presionas `move_up` → ignorar (ya estás en el límite)
    - Si ya estás en lane 1 y presionas `move_down` → ignorar
    - Si presionas `move_up` y `move_down` simultáneamente → el último input gana

  **Must NOT do**:
  - No física de inercia/derrape
  - No animaciones del coche (solo cambio de posición Y)
  - No límites basados en pantalla (usar constantes de lane)

  **Recommended Agent Profile**:
  > `quick` — lógica de input y tweens, bien acotada
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]
    - `godot-best-practices`: Para señales, tipado, estructura de script, Tween API

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 6, 7, 8)
  - **Blocks**: Task 9
  - **Blocked By**: Task 2

  **References**:
  - `GlobalConstants.CAR_BASE_SPEED`, `CAR_MIN_SPEED`, `CAR_MAX_SPEED`, `CAR_ACCELERATION`
  - `GlobalConstants.LANE_1_Y`, `LANE_2_Y`, `LANE_CHANGE_DURATION`, `LANE_CHANGE_COOLDOWN`
  - Godot `Tween` docs — `create_tween().tween_property(self, "position:y", target_y, duration)`
  - Godot Input Map — `Input.is_action_pressed("speed_up")`, `Input.is_action_just_pressed("move_up")`

  **Acceptance Criteria**:
  - [ ] WASD/flechas controlan velocidad arriba/abajo suavemente
  - [ ] Velocidad clamp entre `CAR_MIN_SPEED` (50) y `CAR_MAX_SPEED` (500)
  - [ ] W/↑ cambia a lane superior con tween 0.3s
  - [ ] S/↓ cambia a lane inferior con tween 0.3s
  - [ ] No se puede cambiar de carril durante transición activa
  - [ ] Input en límite de carril se ignora correctamente

  **QA Scenarios**:

  ```
  Scenario: Cambio de carril suave con tween
    Tool: Godot Editor (F6 ejecutar car.tscn)
    Preconditions: Escena car.tscn ejecutándose
    Steps:
      1. Observar posición inicial del coche (debe estar en LANE_1_Y, ~540)
      2. Presionar W (o ↑) una vez
      3. Verificar que el coche se desliza suavemente hacia arriba durante ~0.3s
      4. Verificar posición final: Y ≈ LANE_2_Y (~380)
      5. Presionar S (o ↓) una vez
      6. Verificar que el coche vuelve a LANE_1_Y (~540) suavemente
    Expected Result: Transición suave entre carriles, sin saltos
    Evidence: .sisyphus/evidence/task-5-lane-switch.png

  Scenario: Ignorar input en límite de carril
    Tool: Godot Editor (F6 ejecutar car.tscn)
    Preconditions: Coche en LANE_1_Y (~540)
    Steps:
      1. Presionar S (↓) — coche debería quedarse quieto (ya en lane mínimo)
      2. Cambiar a lane 2 (W/↑), esperar transición
      3. Presionar W (↑) — coche debería quedarse quieto (ya en lane máximo)
      4. Verificar Output: sin errores
    Expected Result: Input en límites se ignora, sin crashes
    Evidence: .sisyphus/evidence/task-5-lane-limits.png

  Scenario: Velocidad controlable con A/D
    Tool: Godot Editor (F6 ejecutar car.tscn)
    Preconditions: Coche en pantalla
    Steps:
      1. Mantener D (→) presionado 2 segundos — la velocidad debe aumentar
      2. Soltar D y mantener A (←) presionado 2 segundos — la velocidad debe disminuir
      3. Verificar que la velocidad nunca baja de CAR_MIN_SPEED (50)
      4. Verificar que la velocidad nunca sube de CAR_MAX_SPEED (500)
    Expected Result: Velocidad dentro de rango [50, 500]
    Evidence: .sisyphus/evidence/task-5-speed-control.png
  ```

  **Commit**: YES
  - Message: `feat(car): implement lane switching and speed control`
  - Files: `scripts/car/car_controller.gd`

- [x] 6. Road Spawning System: Pool + Recycling

  **What to do**:
  - Implementar `scripts/road/road_spawner.gd` (script independiente, no en escena)
  - Crear escena `scenes/road/road_spawner.tscn` con raíz `Node2D`
  - Sistema de pool:
    - `var _pool: Array[Node2D] = []` — segmentos disponibles
    - `var _active: Array[Node2D] = []` — segmentos en pantalla
    - `const POOL_SIZE: int = MAX_ACTIVE_SEGMENTS` (15)
    - En `_ready()`: pre-instanciar `POOL_SIZE` segmentos, añadirlos al pool
    - `func _get_segment() -> Node2D`: sacar del pool o instanciar nuevo si está vacío
    - `func _return_segment(segment: Node2D)`: desactivar y devolver al pool
  - Sistema de spawning:
    - `var _next_spawn_x: float = 0.0`
    - `var _scroll_speed: float = 0.0` — recibir velocidad del coche vía señal
    - En `_physics_process`: mover todos los segmentos activos hacia la izquierda
    - Si el último segmento ha entrado lo suficiente en pantalla → spawnear uno nuevo a la derecha
    - Si un segmento sale completamente de pantalla (señal `screen_exited`) → devolver al pool y mover al final
    - Spawnear segmentos en X creciente: `_next_spawn_x`, `_next_spawn_x + ROAD_SEGMENT_WIDTH`, etc.
  - Conexión con coche:
    - El road spawner expone `func set_scroll_speed(speed: float)`
    - Se conectará desde Main en Task 9

  **Must NOT do**:
  - No usar `queue_free()` (usar pool siempre)
  - No spawnear más de `MAX_ACTIVE_SEGMENTS`
  - No curvas ni offsets verticales

  **Recommended Agent Profile**:
  > `quick` — sistema de pool y spawning, lógica procedural simple
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]
    - `godot-best-practices`: Para señales, pool pattern, _physics_process

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 7, 8)
  - **Blocks**: Task 9
  - **Blocked By**: Task 3

  **References**:
  - `GlobalConstants.ROAD_SEGMENT_WIDTH`, `MAX_ACTIVE_SEGMENTS`, `SCREEN_WIDTH`
  - Godot GDScript patterns — Object Pooling (ver skill cargada)
  - `scenes/road/road_segment.tscn` — Escena de segmento a instanciar
  - `VisibleOnScreenNotifier2D.screen_exited` señal

  **Acceptance Criteria**:
  - [ ] `scenes/road/road_spawner.tscn` existe
  - [ ] Pool de 15 segmentos pre-instanciado en `_ready()`
  - [ ] Segmentos se mueven hacia la izquierda según scroll_speed
  - [ ] Segmentos que salen de pantalla se reciclan al final
  - [ ] No más de 15 segmentos activos simultáneamente
  - [ ] Sin memory leaks (verificar con Godot Debugger > Monitors)

  **QA Scenarios**:

  ```
  Scenario: Spawning continuo de segmentos
    Tool: Godot Editor (F6, con escena de prueba que llame a set_scroll_speed)
    Preconditions: road_spawner.tscn ejecutándose, scroll_speed = 200
    Steps:
      1. Ejecutar escena con road_spawner
      2. Verificar que hay segmentos de carretera visibles
      3. Dejar correr 5 segundos
      4. Verificar que los segmentos se mueven fluidamente a la izquierda
      5. Contar nodos activos: deben ser ≤ 15
    Expected Result: Segmentos se mueven y reciclan sin superar 15 activos
    Evidence: .sisyphus/evidence/task-6-spawning.png

  Scenario: Pool recicla sin crear nuevos tras inicialización
    Tool: Godot Editor con Debugger > Monitors
    Preconditions: Sistema corriendo 10+ segundos
    Steps:
      1. Abrir Debugger > Monitors tab
      2. Observar "Node Count" — debe mantenerse estable
      3. Dejar correr 30 segundos adicionales
      4. Verificar que Node Count no crece (no hay memory leak)
    Expected Result: Node Count estable, sin crecimiento
    Evidence: .sisyphus/evidence/task-6-memory.png
  ```

  **Commit**: YES
  - Message: `feat(road): implement road spawning system with object pool`
  - Files: `scripts/road/road_spawner.gd`, `scenes/road/road_spawner.tscn`

- [x] 7. Parallax Scroll System

  **What to do**:
  - Implementar `scripts/world/parallax_scroller.gd` en la escena `parallax_background.tscn`
  - Conectar el scroll del ParallaxBackground a la velocidad del coche:
    - `var scroll_speed: float = 0.0`
    - `func set_scroll_speed(speed: float) -> void` para recibir velocidad del coche
    - En `_physics_process`: `scroll_offset.x += scroll_speed * delta`
    - Esto mueve automáticamente todas las capas de parallax según sus `motion_scale`
  - Verificación de tileo:
    - Cada capa debe tener suficiente contenido para que al hacer scroll no se vea el borde
    - Para cielo: un solo `ColorRect` de 1920×1080 es suficiente (no necesita tileo)
    - Para montañas/árboles: generar contenido extra a la derecha (fuera de pantalla inicial)
    - Usar `ParallaxLayer.mirroring` para repetición automática: `mirroring.x = 1920` para capas que necesiten tileo

  **Must NOT do**:
  - No implementar scroll manual por capa (ParallaxBackground lo maneja)
  - No modificar la estructura de capas

  **Recommended Agent Profile**:
  > `quick` — conectar velocidad a ParallaxBackground.scroll_offset
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6, 8)
  - **Blocks**: Task 9
  - **Blocked By**: Task 4

  **References**:
  - Godot `ParallaxBackground.scroll_offset` y `scroll_scale`
  - Godot `ParallaxLayer.mirroring` para repetición
  - `GlobalConstants.PARALLAX_SKY/MOUNTAINS/TREES/GUARDRAIL`

  **Acceptance Criteria**:
  - [ ] `scripts/world/parallax_scroller.gd` asignado a `parallax_background.tscn`
  - [ ] `set_scroll_speed(200)` → capas se mueven a velocidades proporcionales
  - [ ] Capa cielo apenas se mueve (0.1x)
  - [ ] Capa guardarraíl se mueve a velocidad completa (1.0x)
  - [ ] Sin bordes visibles al hacer scroll (mirroring funciona)

  **QA Scenarios**:

  ```
  Scenario: Parallax responde a velocidad
    Tool: Godot Editor (F6 con escena de prueba)
    Preconditions: parallax_background.tscn ejecutándose
    Steps:
      1. Llamar set_scroll_speed(200) desde script de prueba
      2. Observar 5 segundos de scroll
      3. Verificar que la capa cielo casi no se mueve
      4. Verificar que los árboles se mueven más rápido que las montañas
      5. Verificar que el guardarraíl se mueve a máxima velocidad
    Expected Result: Efecto parallax visible con ratios correctos
    Evidence: .sisyphus/evidence/task-7-parallax-scroll.png

  Scenario: Sin bordes visibles (mirroring)
    Tool: Godot Editor (F6)
    Preconditions: Sistema corriendo 30+ segundos
    Steps:
      1. Observar el borde derecho de cada capa mientras hace scroll
      2. Verificar que no aparecen huecos ni bordes negros
      3. Verificar que el tileo es continuo y sin saltos
    Expected Result: Parallax infinito sin bordes visibles
    Evidence: .sisyphus/evidence/task-7-mirroring.png
  ```

  **Commit**: YES
  - Message: `feat(world): implement parallax scroll system`
  - Files: `scripts/world/parallax_scroller.gd`, `scenes/world/parallax_background.tscn`

- [x] 8. Speedometer HUD

  **What to do**:
  - Crear directorio `scenes/ui/` y `scripts/ui/`
  - Crear escena `scenes/ui/hud.tscn` con raíz `CanvasLayer`
  - Añadir `Label` para el velocímetro:
    - Posición: esquina superior derecha o inferior derecha (ej: `Vector2(1700, 50)`)
    - Texto inicial: `"0 km/h"`
    - Fuente: default del sistema (no asset externo)
    - Tamaño de fuente: 32-48px
    - Color: blanco o contraste con el fondo
  - Implementar `scripts/ui/hud.gd`:
    - `func update_speed(speed: float) -> void`: actualiza el Label
    - `Label.text = "%d km/h" % int(speed)`
    - `@onready var speed_label: Label = $SpeedLabel`
  - Añadir fondo semitransparente detrás del velocímetro (opcional, `ColorRect` con alpha)

  **Must NOT do**:
  - No animaciones ni efectos visuales
  - No otros indicadores (combustible, distancia, etc.)
  - No fuentes externas

  **Recommended Agent Profile**:
  > `quick` — CanvasLayer + Label, ultra simple
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6, 7)
  - **Blocks**: Task 9
  - **Blocked By**: Task 1

  **References**:
  - Godot `CanvasLayer` docs — Capa de UI independiente de la cámara
  - Godot `Label` docs — Propiedades de texto, fuente, color
  - `GlobalConstants.CAR_BASE_SPEED`

  **Acceptance Criteria**:
  - [ ] `scenes/ui/hud.tscn` existe
  - [ ] Label visible en pantalla como CanvasLayer (no se mueve con la cámara)
  - [ ] `update_speed(150)` → label muestra "150 km/h"
  - [ ] `update_speed(0)` → label muestra "0 km/h"

  **QA Scenarios**:

  ```
  Scenario: Velocímetro muestra velocidad correcta
    Tool: Godot Editor (F6 ejecutar hud.tscn)
    Preconditions: Escena HUD ejecutándose
    Steps:
      1. Llamar update_speed(150) desde script de prueba
      2. Verificar Label.text = "150 km/h"
      3. Llamar update_speed(0)
      4. Verificar Label.text = "0 km/h"
      5. Llamar update_speed(325)
      6. Verificar Label.text = "325 km/h"
    Expected Result: Label refleja exactamente el valor de velocidad
    Evidence: .sisyphus/evidence/task-8-speedometer.png

  Scenario: HUD no se mueve con la cámara
    Tool: Godot Editor (F6 en escena con cámara en movimiento)
    Preconditions: HUD + cámara en escena de prueba
    Steps:
      1. Mover la cámara 500px a la derecha
      2. Verificar que el velocímetro sigue en la misma posición en pantalla
      3. Mover la cámara 500px hacia arriba
      4. Verificar que el velocímetro NO se movió
    Expected Result: HUD fijo en pantalla independientemente de la cámara
    Evidence: .sisyphus/evidence/task-8-hud-fixed.png
  ```

  **Commit**: YES
  - Message: `feat(ui): add speedometer HUD`
  - Files: `scenes/ui/hud.tscn`, `scripts/ui/hud.gd`

### Wave 3 — Integration & Polish (After Wave 2, SEQUENTIAL)

- [ ] 9. Main Scene Assembly

  **What to do**:
  - Crear `scenes/main.tscn` con raíz `Node2D` llamado "Main"
  - Instanciar y organizar todos los sistemas:
    1. `ParallaxBackground` (de `parallax_background.tscn`) como hijo — capa más profunda (Z-index 0)
    2. `RoadSpawner` (de `road_spawner.tscn`) como hijo — capa media (Z-index 1)
    3. `Car` (de `car.tscn`) como hijo — capa frontal (Z-index 2)
    4. `HUD` (de `hud.tscn`) como hijo — capa UI (CanvasLayer, Z-index 10)
  - Crear `scripts/main.gd` y asignar a Main:
    - `@onready var car: CharacterBody2D = $Car`
    - `@onready var road_spawner: Node2D = $RoadSpawner`
    - `@onready var parallax: ParallaxBackground = $ParallaxBackground`
    - `@onready var hud: CanvasLayer = $HUD`
  - Conectar señales en `_ready()`:
    - Cada frame en `_physics_process`:
      - Leer `car.current_speed` (debe ser accesible desde Car)
      - Llamar `road_spawner.set_scroll_speed(car.current_speed)`
      - Llamar `parallax.set_scroll_speed(car.current_speed)`
      - Llamar `hud.update_speed(car.current_speed)`
  - Ajustar Z-indices para el orden correcto de renderizado
  - Añadir `Camera2D` al ParallaxBackground (o referencia compartida)

  **Must NOT do**:
  - No lógica de juego nueva aquí (solo wiring)
  - No nuevas escenas ni assets

  **Recommended Agent Profile**:
  > `quick` — composición de escenas existentes, wiring simple
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]
    - `godot-best-practices`: Para @onready, señales, estructura de escena, Z-index

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 — Sequential (depends on Tasks 5, 6, 7, 8)
  - **Blocks**: Tasks 10, 11
  - **Blocked By**: Tasks 5, 6, 7, 8

  **References**:
  - `scenes/car/car.tscn` — Escena del coche
  - `scenes/road/road_spawner.tscn` — Escena del spawner
  - `scenes/world/parallax_background.tscn` — Escena del parallax
  - `scenes/ui/hud.tscn` — Escena del HUD
  - Godot node Z-index — `CanvasItem.z_index` para orden de renderizado

  **Acceptance Criteria**:
  - [ ] `scenes/main.tscn` existe y se abre sin errores
  - [ ] 4 sistemas hijo visibles en el Scene Tree
  - [ ] `scripts/main.gd` conecta velocidad del coche a road_spawner, parallax y HUD
  - [ ] Al ejecutar main.tscn, todos los sistemas funcionan juntos sin errores
  - [ ] Orden de renderizado correcto: cielo → montañas → árboles → carretera → coche → guardarraíl → HUD

  **QA Scenarios**:

  ```
  Scenario: Todos los sistemas integrados funcionan juntos
    Tool: Godot Editor (F5 ejecutar proyecto)
    Preconditions: main.tscn como escena principal en Project Settings
    Steps:
      1. Presionar F5 para ejecutar el proyecto completo
      2. Verificar que el parallax se ve detrás de la carretera
      3. Verificar que el coche está visible sobre la carretera
      4. Verificar que el velocímetro se ve en la esquina
      5. Presionar D para acelerar — verificar que carretera y parallax aceleran
      6. Presionar W para cambiar de carril — verificar transición suave
      7. Verificar Output: sin errores ni warnings
    Expected Result: Juego completo funcionando con todos los sistemas
    Evidence: .sisyphus/evidence/task-9-full-game.png

  Scenario: Z-ordering correcto
    Tool: Godot Editor (abrir main.tscn)
    Preconditions: Escena abierta
    Steps:
      1. Seleccionar nodo ParallaxBackground — verificar z_index = 0
      2. Seleccionar nodo RoadSpawner — verificar z_index = 1
      3. Seleccionar nodo Car — verificar z_index = 2
      4. Seleccionar nodo HUD (CanvasLayer) — verificar layer > 0
    Expected Result: Capas en orden: fondo → carretera → coche → UI
    Evidence: .sisyphus/evidence/task-9-zorder.png
  ```

  **Commit**: YES
  - Message: `feat(main): assemble main scene with all systems`
  - Files: `scenes/main.tscn`, `scripts/main.gd`

- [ ] 10. Lane Transition Polish + Edge Cases

  **What to do**:
  - Revisar y pulir el cambio de carril:
    - Verificar que el tween usa easing apropiado (ej: `Tween.EASE_OUT` + `Tween.TRANS_QUAD`)
    - Verificar que el cooldown post-transición previene spam de input
    - Si el jugador presiona dirección opuesta durante transición → ignorar (no cancelar)
  - Edge cases adicionales:
    - ¿Qué pasa si se pierde el foco de la ventana? → Por ahora nada (sin sistema de pausa), documentar
    - ¿El coche se sale de los límites si la velocidad es muy alta y el lane change coincide? → No debería (solo se mueve en Y)
  - Ajustes visuales del coche:
    - Si el coche cambia de carril, tal vez rotar ligeramente (1-3 grados) durante la transición para dar sensación de movimiento
  - Ajustar `LANE_CHANGE_DURATION` y `LANE_CHANGE_COOLDOWN` en `constants.gd` si es necesario tras probar
  - Probar combinaciones rápidas de teclas (spam) — el sistema debe ser robusto

  **Must NOT do**:
  - No añadir nuevas mecánicas (solo pulir existentes)
  - No cambiar la física base
  - No añadir efectos visuales complejos

  **Recommended Agent Profile**:
  > `quick` — pulido de tweens y edge cases, sin lógica nueva
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 — Sequential (depends on Task 9)
  - **Blocks**: Task 11
  - **Blocked By**: Task 9

  **References**:
  - `scripts/car/car_controller.gd` — Lógica de cambio de carril
  - `GlobalConstants.LANE_CHANGE_DURATION`, `LANE_CHANGE_COOLDOWN`
  - Godot `Tween` easing docs — `Tween.EASE_OUT`, `Tween.TRANS_QUAD`

  **Acceptance Criteria**:
  - [ ] Cambio de carril se siente suave (easing correcto)
  - [ ] Spam de teclas W/S no causa bugs (no múltiples tweens simultáneos)
  - [ ] El coche no puede estar en dos carriles a la vez
  - [ ] Tras cambio de carril, cooldown de 0.1s antes de permitir otro cambio

  **QA Scenarios**:

  ```
  Scenario: Spam de teclas no rompe el sistema
    Tool: Godot Editor (F5 ejecutar main.tscn)
    Preconditions: Juego ejecutándose
    Steps:
      1. Presionar W y S alternadamente lo más rápido posible durante 3 segundos
      2. Verificar que el coche no "vibra" ni salta erráticamente
      3. Verificar que tras soltar, el coche está en un carril definido (no entre medias)
      4. Verificar Output: sin errores
    Expected Result: Sistema robusto ante spam de input
    Evidence: .sisyphus/evidence/task-10-spam-test.png

  Scenario: Cambio de carril no cancelable
    Tool: Godot Editor (F5)
    Preconditions: Juego ejecutándose, coche en lane 1
    Steps:
      1. Presionar W para iniciar cambio a lane 2
      2. Inmediatamente (durante el tween) presionar S
      3. Verificar que el coche completa el cambio a lane 2 (ignora el input contrario)
      4. Esperar cooldown, luego presionar S
      5. Coc debería volver a lane 1
    Expected Result: Transiciones no se cancelan, input contrario se ignora durante tween
    Evidence: .sisyphus/evidence/task-10-no-cancel.png
  ```

  **Commit**: YES
  - Message: `polish(car): refine lane transition easing and edge cases`
  - Files: `scripts/car/car_controller.gd`, `scripts/globals/constants.gd` (si se ajustaron valores)

- [ ] 11. Final QA Verification

  **What to do**:
  - Ejecutar el juego completo y verificar TODOS los criterios de aceptación de tareas anteriores:
    1. Input Map funciona (WASD + flechas)
    2. Coche visible y con colisión
    3. Carretera hace scroll infinito
    4. Parallax funciona con ratios correctos
    5. Cambio de carril suave con tween
    6. Velocidad controlable y clamp correcto
    7. Velocímetro muestra valor correcto
    8. Z-ordering correcto
    9. Sin memory leaks
    10. Spam de input no causa bugs
  - Documentar cualquier issue encontrado
  - Si hay issues menores, corregirlos en este mismo paso
  - Capturar screenshot final del juego funcionando

  **Must NOT do**:
  - No empezar features nuevas
  - No cambiar el diseño a menos que haya un bug crítico

  **Recommended Agent Profile**:
  > `quick` — verificación y fixes menores
  - **Category**: `quick`
  - **Skills**: [`godot-best-practices`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 — Sequential (depends on Task 10)
  - **Blocks**: F1-F4 (Final Verification)
  - **Blocked By**: Task 10

  **References**:
  - Todos los acceptance criteria de Tasks 1-10
  - `scenes/main.tscn`

  **Acceptance Criteria**:
  - [ ] Todos los criterios de Tasks 1-10 verificados
  - [ ] Screenshot final del juego capturado
  - [ ] 0 errores en Output panel de Godot
  - [ ] Juego ejecutable presionando F5 sin intervención manual

  **QA Scenarios**:

  ```
  Scenario: Verificación completa end-to-end
    Tool: Godot Editor (F5 ejecutar proyecto)
    Preconditions: Nada abierto, proyecto limpio
    Steps:
      1. Presionar F5
      2. Esperar 5 segundos de gameplay automático
      3. Presionar D por 3s → verificar aceleración y parallax más rápido
      4. Presionar W → verificar cambio de carril suave
      5. Presionar S → verificar vuelta al carril original
      6. Presionar A por 3s → verificar desaceleración
      7. Capturar screenshot del estado final
      8. Revisar Output panel: 0 errores, 0 warnings
    Expected Result: Juego 100% funcional, sin errores
    Evidence: .sisyphus/evidence/task-11-final-verification.png
  ```

  **Commit**: YES
  - Message: `qa: final verification and minor fixes`
  - Files: Los que requirieran fixes

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (check files exist via Glob). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run Godot Editor and check Output panel for errors/warnings. Review all GDScript files for: missing type hints, magic numbers, unused variables, `get_node()` in `_ready()` instead of `@onready`, string signals instead of typed, `load()` where `preload()` should be used. Check AI slop: excessive comments, over-abstraction, generic names.
  Output: `Scripts [N clean/N issues] | Type Hints [N/N] | Warnings [N] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Open project in Godot Editor. Execute `main.tscn` (F5). Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test additional edge cases: rapid input spam, window resize, min/max speed. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", check actual files (Glob for created files). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance of each task. Detect cross-task contamination: Task N touching Task M's files. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| Wave | Tasks | Commit Message | Files |
|------|-------|---------------|-------|
| 1 | 1 | `feat(project): add Input Map and GlobalConstants autoload` | `scripts/globals/constants.gd`, `project.godot` |
| 1 | 2 | `feat(car): add geometric car scene with collision` | `scenes/car/car.tscn`, `scripts/car/car_controller.gd` |
| 1 | 3 | `feat(road): add geometric road segment scene` | `scenes/road/road_segment.tscn`, `scripts/road/road_segment.gd` |
| 1 | 4 | `feat(world): add parallax background with 4 layers` | `scenes/world/parallax_background.tscn` |
| 2 | 5 | `feat(car): implement lane switching and speed control` | `scripts/car/car_controller.gd` |
| 2 | 6 | `feat(road): implement road spawning system with object pool` | `scripts/road/road_spawner.gd`, `scenes/road/road_spawner.tscn` |
| 2 | 7 | `feat(world): implement parallax scroll system` | `scripts/world/parallax_scroller.gd`, `scenes/world/parallax_background.tscn` |
| 2 | 8 | `feat(ui): add speedometer HUD` | `scenes/ui/hud.tscn`, `scripts/ui/hud.gd` |
| 3 | 9 | `feat(main): assemble main scene with all systems` | `scenes/main.tscn`, `scripts/main.gd` |
| 3 | 10 | `polish(car): refine lane transition easing and edge cases` | `scripts/car/car_controller.gd`, `scripts/globals/constants.gd` |
| 3 | 11 | `qa: final verification and minor fixes` | Los que requieran fixes |

---

## Success Criteria

### Verification Commands
```bash
# Verificar que todos los archivos existen
ls scenes/car/car.tscn scenes/road/road_segment.tscn scenes/road/road_spawner.tscn
ls scenes/world/parallax_background.tscn scenes/ui/hud.tscn scenes/main.tscn
ls scripts/globals/constants.gd scripts/car/car_controller.gd
ls scripts/road/road_spawner.gd scripts/world/parallax_scroller.gd
ls scripts/ui/hud.gd scripts/main.gd

# Abrir Godot y ejecutar (manual por ahora)
# Expected: F5 ejecuta main.tscn sin errores, juego funcional
```

### Final Checklist
- [ ] All "Must Have" present: Input Map, GDScript tipado, señales, pool, colores hardcodeados
- [ ] All "Must NOT Have" absent: texturas, física compleja, tráfico, curvas, partículas, sonido, gamepad, menú
- [ ] 11 tasks completadas con QA scenarios verificados
- [ ] Evidencia capturada en `.sisyphus/evidence/`
- [ ] Coche cambia de carril con tween 0.3s
- [ ] Parallax 4 capas con ratios 0.1, 0.3, 0.7, 1.0
- [ ] Velocímetro muestra km/h correctos
- [ ] Carretera infinita con pool de 15 segmentos
- [ ] Sin errores en Godot Output panel
- [ ] Iteración lista para siguiente fase (visual novel, texturas, etc.)

