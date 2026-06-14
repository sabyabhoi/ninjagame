# Animation

Animation turns a static **sprite sheet** (one image holding many small frames)
into a moving character. The code lives in `src/engine/animation.odin`.

## Key pieces

- **AnimationClip** — a reusable description of one animation (its texture, frame
  rectangles, and per-frame duration). Built once at startup and stored in
  `Assets`.
- **AnimationKind** — an enum of the animations that exist: `.Idle`, `.Walk`,
  and `.Attack`.
- **Direction** — logical facing: `.Down`, `.Left`, `.Right`, `.Up`.
- **AnimationState** — the per-entity "playhead" (current kind, direction, frame,
  timer). Lives on the entity as a component.

```odin
AnimationClip :: struct {
    texture:  raylib.Texture2D,
    frames:   []raylib.Rectangle,  // one rect per frame, played in order
    duration: f32,                  // seconds per frame
}
```

## The sprite sheet layout

The walk sheet is a **grid**: each **column** is a facing direction and each
**row** is a step in the walk cycle.

```
        col0     col1     col2     col3
        DOWN     UP       LEFT     RIGHT
row0    [..]     [..]     [..]     [..]
row1    [..]     [..]     [..]     [..]
row2    [..]     [..]     [..]     [..]
row3    [..]     [..]     [..]     [..]
```

Logical directions map to sheet columns via `DIRECTION_SHEET_COLUMNS` (the sheet
column order is not the same as the enum order).

## Building clips from the sheet

Two builder procs slice a texture into frame rectangles:

- `clip_from_horizontal_strip` — a simple single-row strip (no directions).
- `clip_from_sheet_column` — one column of a directional grid; used for **Idle**
  (one frame), **Walk**, and **Attack**.

At startup, `register_player_clips` in `main` builds one clip per
`(AnimationKind, Direction)` pair — 12 clips total — and registers them into
`Assets`.

## Picking the frame to show

Runtime playback is a flat loop over the clip's `frames` array:

```odin
clip := assets_get_clip(a, state.kind, state.direction)
sprite.source = clip.frames[state.frame_index]
```

`animation_apply_sprite_frame` copies that rectangle into the entity's
`Sprite.source`, which is what the renderer draws.

## Putting it together at runtime

Each fixed step:

1. `animation_system` calls `select_animation` to set `kind` (Idle/Walk/Attack)
   and `direction` from `Velocity` and `AttackState`. See [systems.md](systems.md).
2. `animation_system` calls `advance_animation` to tick `frame_index` using the
   timer, then write the resulting frame into the sprite.

Gameplay state drives the choice of animation; elapsed time drives flipping
between frames.

## Tests

`src/engine/animation_test.odin` covers clip builders directly (no window
needed):

- `test_clip_from_horizontal_strip` — strip slicing and frame offsets.
- `test_clip_from_sheet_column` — column slicing and per-cell x/y.
- `test_direction_sheet_columns` — direction-to-column mapping.

Run them with `odin test src/engine`.
