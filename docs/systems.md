# Systems

Systems are the functions that make things happen. Each one loops over the
entities that have the components it cares about and updates them. They run in a
fixed order every logic step (see [architecture.md](architecture.md)).

## player_movement_input_system (`player.odin`)

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

## player_attack_input_system (`player.odin`)

Starts an attack when the player presses the attack key. It only writes
`AttackState`; it does not touch animation data directly.

- Pressing attack adds an `AttackState` entry with `timer = 0`.
- If the entity is already attacking, the press is ignored.

## animation_system (`systems.odin`)

Handles animation for **every** entity with an `AnimationState` (players and
any future NPCs). Each tick it runs two internal steps per entity:

1. **`select_animation`** — picks `kind` and `direction` from gameplay state:
   - Has `AttackState` → `.Attack`
   - Else moving (`Velocity` non-zero) → `.Walk` + facing from dominant axis
   - Else → `.Idle`
   - When kind or direction changes, `frame_index` and `timer` reset to 0.
2. **`advance_animation`** — adds `dt` to the timer, advances `frame_index`
   through the clip, and copies the current frame into the entity's `Sprite`.

```odin
select_animation(w, entity, &state)
advance_animation(w, a, entity, &state, dt)
```

## attack_system (`systems.odin`)

Tracks attack duration and removes `AttackState` when the clip has played
through. Duration is derived from the registered attack clip's frame count and
per-frame duration. Animation selection picks Idle/Walk on the same tick after
removal.

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
2. **Draw.** For each sprite it computes the destination rectangle at the
   transform's native position and the source frame's native size, then calls
   `raylib.DrawTexturePro` with the sprite's source frame and tint. The global
   `CONFIG.render_scale` is applied once via the camera's zoom, not per sprite.

## How the systems fit together

A single logic step flows like this:

```
keys held ─▶ player_movement_input_system ─▶ Velocity
attack press ─▶ player_attack_input_system ─▶ AttackState
                                                    │
AttackState + dt ─▶ attack_system ─▶ AttackState (removed when done)
                                                    │
Velocity + AttackState ─▶ animation_system ─▶ AnimationState + Sprite
                                                    │
Velocity + dt ─▶ physics_system ─▶ Transform (new position)

later, in draw:
Sprite + Transform ─▶ render_system ─▶ pixels on screen
```
