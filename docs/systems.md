# Systems

Systems are the functions that make things happen. Each one loops over the
entities that have the components it cares about and updates them. They run in a
fixed order every logic step (see [architecture.md](architecture.md)).

## player_input_system (`world.odin`)

Turns key presses into movement. It looks at every entity tagged
`PlayerControlled` and sets its `Velocity` based on the keys currently held.

- Velocity is reset to `{0, 0}` each step, then keys add to it.
- `WASD` map to up/left/down/right; speed comes from `CONFIG.player_speed`.

```odin
vel.value = {0, 0}
if .MoveLeft  in input.held do vel.value.x -= CONFIG.player_speed
if .MoveRight in input.held do vel.value.x += CONFIG.player_speed
if .MoveUp    in input.held do vel.value.y -= CONFIG.player_speed
if .MoveDown  in input.held do vel.value.y += CONFIG.player_speed
```

## player_animation_system (`animation.odin`)

Decides *which* animation a player entity should be playing, based on its
velocity:

- Moving -> `kind = .Walk`; not moving -> `kind = .Idle`.
- The facing direction (`column`) is chosen from the larger velocity axis:
  mostly horizontal -> left/right, mostly vertical -> up/down.
- When the animation or direction changes, `frame_index` and `timer` reset to 0
  so the new animation starts cleanly.

This only *selects* the animation. It does not advance frames.

## animation_system (`animation.odin`)

Advances animation frames over time for **every** entity with an
`AnimationState` (players and any future NPCs).

- Adds `dt` to the state's `timer`.
- Each time the timer passes the clip's `duration`, it advances to the next
  frame, wrapping around with modulo.
- Finally it copies the current frame's rectangle into the entity's `Sprite`
  so the renderer shows the right image.

```odin
state.timer += dt
for state.timer >= clip.duration {
    state.timer -= clip.duration
    state.frame_index = (state.frame_index + 1) % clip.frames_per_direction
}
```

## physics_system (`world.odin`)

Moves entities. For every `Velocity`, it finds the matching `Transform` and adds
`velocity * dt` to the position. Because `dt` is the fixed timestep, movement is
frame-rate independent.

```odin
for entity, &vel in w.velocities.data {
    t, ok := store_get(&w.transforms, entity)
    if !ok do continue
    t.position += vel.value * dt
}
```

## render_system (`world.odin`)

Draws every entity that has both a `Sprite` and a `Transform`. It runs during
`draw`, not during the fixed update.

Two steps:

1. **Sort by Y.** It collects sprites into a list and stable-sorts them by their
   `position.y`. Entities lower on screen draw last (on top), giving a correct
   top-down overlap so characters "stand in front of" things above them.
2. **Draw.** For each sprite it computes the destination rectangle (position
   scaled by the transform's `scale`) and calls `raylib.DrawTexturePro` with the
   sprite's source frame and tint.

## How the systems fit together

A single logic step flows like this:

```
keys held ─▶ player_input_system ─▶ Velocity
                                        │
Velocity ─▶ player_animation_system ─▶ AnimationState (kind + direction)
                                        │
AnimationState + dt ─▶ animation_system ─▶ Sprite (current frame)
                                        │
Velocity + dt ─▶ physics_system ─▶ Transform (new position)

later, in draw:
Sprite + Transform ─▶ render_system ─▶ pixels on screen
```
