# Architecture Docs

These docs explain how Ninja Game is put together, in plain terms.
The game is a small top-down game written in [Odin](https://odin-lang.org/)
using the [Raylib](https://www.raylib.com/) library for windowing, drawing,
and input.

## The big idea

The game uses an **ECS** (Entity-Component-System) design. Instead of having
classes like `Player` or `Enemy` with their own behavior, the game splits
everything into three plain ideas:

- **Entities** are just IDs (numbers). They are "things" in the world.
- **Components** are pure data attached to an entity (position, velocity,
  sprite, etc.). They hold no logic.
- **Systems** are functions that loop over entities with certain components
  and do the work (move them, draw them, animate them).

So an entity "is a player" simply because it happens to have the right set of
components attached to it. Nothing more.

## Where to look

| File | What it covers |
| --- | --- |
| [architecture.md](architecture.md) | The ECS model and the game loop (the heart of the program). |
| [components.md](components.md) | Every piece of data an entity can have. |
| [systems.md](systems.md) | The functions that read components and make things happen. |
| [animation.md](animation.md) | How sprite sheets become moving characters. |
| [assets-and-input.md](assets-and-input.md) | Loading textures and reading the keyboard. |

## Source layout

All code lives in `src/` as a single Odin package (`package main`):

| File | Role |
| --- | --- |
| `main.odin` | Startup, the game loop, and the per-frame `fixed_update` / `draw` steps. |
| `world.odin` | The `World` (entity + component storage) and most systems. |
| `config.odin` | All tunable numbers (speeds, window size, timestep) in one place. |
| `animation.odin` | Animation clips, animation state, and animation systems. |
| `assets.odin` | Loads and frees textures and animation clips. |
| `input.odin` | Maps keyboard keys to game actions. |
| `spawn.odin` | Helpers that build entities (e.g. the player) from components. |
| `animation_test.odin` | Unit tests for the animation math. |
