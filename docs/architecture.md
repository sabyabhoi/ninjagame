# Architecture: ECS and the Game Loop

## Packages

The source is split into three Odin packages:

| Package | Path | Responsibility |
|---------|------|----------------|
| `main` | `src/` | Game loop, player spawn, player-specific systems |
| `config` | `src/config/` | Tunable settings (`CONFIG`) and asset paths (`ASSET_PATHS`) |
| `engine` | `src/engine/` | ECS world, components, generic systems, animation, assets, input, tilemap |

`main` imports `engine` and `config`. `engine` has no dependency on `config` — game-specific systems that read `CONFIG` (player input and animation) live in `src/player.odin`.

## The ECS model

The game keeps **all** of its state in one struct called `World`
(`src/engine/world.odin`). Think of it as a database.

```odin
World :: struct {
    next_id:   Entity,
    free_list: [dynamic]Entity,

    // Components (one generic store per component type)
    transforms:        ComponentStore(Transform),
    velocities:        ComponentStore(Velocity),
    sprites:           ComponentStore(Sprite),
    animations:        ComponentStore(AnimationState),
    player_controlled: ComponentStore(PlayerControlled),
}
```

### Entities

An `Entity` is just a number (`distinct u32`). Creating an entity hands you the
next free number:

- `entity_create` returns a reused ID from `free_list` if one is available,
  otherwise it hands out a fresh `next_id`.
- `entity_destroy` removes all of the entity's components and puts its ID back
  on the `free_list` so it can be reused later.

Reusing IDs keeps numbers small and avoids running out.

### Components

Each component type gets its **own store** — a generic `ComponentStore(T)` wrapping
a map from `Entity` to that data. To find an entity's position, you look it up
in the `transforms` store by its ID.

This "one store per component" approach means:

- An entity *has* a component only if its ID is a key in that store's map.
- Adding behavior data is as simple as `store_add(&w.transforms, entity, data)`.
- Removing it is `store_remove(&w.transforms, entity)`.

Generic helpers in `store.odin` — `store_get`, `store_add`, `store_remove` —
work for every component type. `store_get` returns a pointer plus an `ok`
boolean, so systems can safely skip entities that lack a component.

### Systems

Systems are free functions that loop over one component map and act on the
entities they find. For example, the physics system loops over every velocity
and moves the matching transform. Systems are the *only* place where logic
lives. Components stay as pure data. See [systems.md](systems.md).

## The game loop

The whole program is driven by the loop in `main` (`src/main.odin`). Player-specific systems (`player_input_system`, `player_movement_system`, `player_attack_system`) run from `src/player.odin`; generic engine systems live in `src/engine/systems.odin`. In order:

1. **Setup**
   - Open the window (size/title come from `CONFIG`).
   - Initialize `Assets`, load sprite sheets, and build per-direction animation
     clips for Idle, Walk, and Attack.
   - Initialize the `World`.
   - Spawn the player at `{100, 100}`.

2. **Per frame** (runs until the window is closed):
   - `input_update` reads the keyboard into the `InputState`.
   - Add the frame's elapsed time to an `accumulator`.
   - Run `fixed_update` zero or more times, once per fixed timestep.
   - `draw` the current state of the world.

```odin
for !raylib.WindowShouldClose() {
    input_update(&input)
    dt := raylib.GetFrameTime()
    accumulator += dt
    for ; accumulator >= CONFIG.fixed_timestep; accumulator -= CONFIG.fixed_timestep {
        fixed_update(&w, &a, &input, CONFIG.fixed_timestep)
    }
    raylib.BeginDrawing()
    draw(&w)
    raylib.EndDrawing()
}
```

### Why a fixed timestep?

Drawing happens as fast as the screen allows, but **game logic runs at a fixed
rate** (60 times per second, set by `CONFIG.fixed_timestep = 1/60`). The
`accumulator` collects real elapsed time and "spends" it in fixed chunks.

This keeps movement and physics consistent regardless of frame rate. A slow
machine simply runs `fixed_update` more times per frame to catch up; a fast
machine still only steps logic 60 times a second.

### What runs each step

`fixed_update` runs the systems in a deliberate order:

```odin
fixed_update :: proc(w: ^engine.World, a: ^engine.Assets, input: ^engine.InputState, dt: f32) {
    player_input_system(w, input)          // 1. turn key presses into velocity (main)
    player_attack_system(w, input)         // 2. start attack animation on key press (main)
    player_movement_system(w)              // 3. pick Idle/Walk + facing direction (main)
    engine.attack_system(w, a, dt)         // 4. end attack when clip finishes
    engine.animation_system(w, a, dt)      // 5. advance animation frames over time
    engine.physics_system(w, dt)           // 6. move entities by their velocity
}
```

`draw` clears the screen and calls `render_system`, which sorts sprites and
draws them.

## Memory management

Odin has no garbage collector, so the code frees what it allocates:

- `world_init` / `world_destroy` create and free the component maps.
- `assets_init` / `assets_destroy` load and unload textures and clip frames.
- Both are paired with `defer` in `main`, so cleanup happens automatically when
  `main` returns.
