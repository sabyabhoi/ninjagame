# Assets and Input

Two small support systems: one loads images, the other reads the keyboard.

## Assets (`src/assets.odin`)

`Assets` is the central store for everything loaded from disk. It holds loaded
textures and the built animation clips.

```odin
Assets :: struct {
    textures: map[string]raylib.Texture2D,     // path -> texture
    clips:    [AnimationKind][Direction]AnimationClip,  // one clip per kind + facing
}
```

Key procs:

- `assets_load_texture` — loads a texture from a file path. It **caches** by
  path, so asking for the same file twice returns the already-loaded texture
  instead of loading it again. Returns `(texture, ok)`; `ok` is false if the
  file failed to load.
- `assets_register_clip` — stores a built `AnimationClip` under a kind and
  direction, freeing any clip it replaces.
- `assets_get_clip` — returns the clip for a kind and direction pair.
- `assets_init` / `assets_destroy` — set up the texture map and, on shutdown,
  unload every texture and free every clip's frame data.

Asset file paths are centralized in `ASSET_PATHS` in `src/config.odin`, e.g. the
walk sheet at `assets/Actor/Character/Boy/SeparateAnim/Walk.png`. Run the game
from the project root so these relative paths resolve.

## Input (`src/input.odin`)

Input is decoupled from physical keys through an `Action` enum, so game logic
talks about *intent* ("MoveLeft") rather than hardware ("the A key").

```odin
Action :: enum { MoveLeft, MoveRight, MoveUp, MoveDown, Jump, Attack }
```

`key_bindings` maps each action to a keyboard key (WASD to move, Space to jump,
J to attack). Changing the controls is a one-line edit here.

Each frame, `input_update` fills three `bit_set`s describing the current state
of every action:

```odin
InputState :: struct {
    pressed:  bit_set[Action],  // became down this frame
    held:     bit_set[Action],  // currently down
    released: bit_set[Action],  // became up this frame
}
```

Systems then ask simple questions like `if .MoveLeft in input.held`. A
`bit_set` is an efficient set of enum values, so checking and combining actions
is cheap.

> Note: `Jump` and `Attack` are defined and bound but not yet used by any
> system — they are wiring for future behavior.

## Configuration (`src/config.odin`)

All tunable values live in one `CONFIG` constant so behavior can be adjusted in
a single place: window size and title, `player_speed`, `player_scale`, the idle
and walk frame durations, the `fixed_timestep`, and `target_fps`.
