# Animation

Animation turns a static **sprite sheet** (one image holding many small frames)
into a moving character. The code lives in `src/animation.odin`.

## Key pieces

- **AnimationClip** — a reusable description of one animation (its texture and
  the list of frame rectangles). Built once at startup and stored in `Assets`.
- **AnimationKind** — an enum of the animations that exist: `.Idle` and `.Walk`.
- **AnimationState** — the per-entity "playhead" (current frame, direction,
  timer). Lives on the entity as a component.

```odin
AnimationClip :: struct {
    texture:              raylib.Texture2D,
    frames:               []raylib.Rectangle,  // one rect per frame
    duration:             f32,                  // seconds per frame
    directions:           int,                  // 1, or 4 for directional
    frames_per_direction: int,
}
```

## The sprite sheet layout

The walk sheet is a **grid**: each **column** is a facing direction and each
**row** is a step in the walk cycle.

```
        col0     col1     col2     col3
        DOWN     LEFT     RIGHT    UP
row0    [..]     [..]     [..]     [..]
row1    [..]     [..]     [..]     [..]
row2    [..]     [..]     [..]     [..]
row3    [..]     [..]     [..]     [..]
```

The direction columns are named by constants:

```odin
WALK_COL_DOWN  :: 0
WALK_COL_LEFT  :: 1
WALK_COL_RIGHT :: 2
WALK_COL_UP    :: 3

WALK_DIRECTIONS           :: 4
WALK_FRAMES_PER_DIRECTION :: 4
```

## Building clips from the sheet

Three builder procs slice a texture into frame rectangles:

- `clip_from_horizontal_strip` — a simple single-row strip (no directions).
- `clip_from_directional_grid` — the full grid above; used for **Walk**. Frames
  are stored column-major: `idx = col * frames_per_direction + row`.
- `clip_idle_from_walk_grid` — reuses the walk sheet but only takes the **top
  row** of each column as a single standing frame per direction; used for
  **Idle**.

Both clips are created in `main` from the same walk texture and registered into
`Assets` under their `AnimationKind`.

## Picking the frame to show

`animation_frame_index` converts the state's `column` + `frame_index` into a
flat index into the clip's `frames` array:

```odin
frame_idx := state.frame_index
if clip.directions > 1 {
    frame_idx = state.column * clip.frames_per_direction + state.frame_index
}
```

`animation_apply_sprite_frame` then copies that frame's rectangle into the
entity's `Sprite.source`, which is what the renderer draws.

## Putting it together at runtime

Each fixed step:

1. `player_animation_system` sets `kind` (Idle/Walk) and `column` (facing) from
   the player's velocity. See [systems.md](systems.md).
2. `animation_system` advances `frame_index` using the timer, then writes the
   resulting frame into the sprite.

So velocity drives the choice of animation, and elapsed time drives the
flipping between frames.

## Tests

`src/animation_test.odin` covers the frame math directly (no window needed):

- `test_clip_from_horizontal_strip` — strip slicing and frame offsets.
- `test_clip_from_directional_grid` — grid slicing and per-cell x/y.
- `test_animation_frame_index` — the column + frame index calculation.

Run them with `odin test src`.
