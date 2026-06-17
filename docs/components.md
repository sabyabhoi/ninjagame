# Components

Components are pure data attached to an entity. An entity gains a capability by
having the matching component, and loses it by having it removed. None of these
structs contain logic.

## Transform (`world.odin`)

Where an entity is, in native (unscaled) pixels. There is no per-entity size
multiplier: the whole world is scaled uniformly at render time by the camera's
zoom (`CONFIG.render_scale`), so positions and sizes are authored in native art
pixels.

```odin
Transform :: struct {
    position: raylib.Vector2,  // x, y in the world (native pixels)
}
```

## Velocity (`world.odin`)

How fast and in what direction an entity moves, in pixels per second. The
physics system adds `velocity * dt` to the position each step.

```odin
Velocity :: struct {
    value: raylib.Vector2,
}
```

## Sprite (`world.odin`)

What to draw. `source` is the rectangle inside the texture (a single frame of a
sprite sheet). If `source.width` is 0, the whole texture is drawn.

```odin
Sprite :: struct {
    texture: raylib.Texture2D,
    source:  raylib.Rectangle,  // which part of the texture to show
    tint:    raylib.Color,      // color multiply (usually WHITE = unchanged)
}
```

## AnimationState (`animation.odin`)

The "playhead" for an animation: which clip is playing, which direction, which
frame, and a timer that drives frame advances. See
[animation.md](animation.md) for the details.

```odin
AnimationState :: struct {
    kind:        AnimationKind,  // .Idle, .Walk, or .Attack
    direction:   Direction,      // facing (down/left/right/up)
    frame_index: int,            // current frame within the clip
    timer:       f32,             // time accumulated toward the next frame
}
```

## PlayerControlled (`world.odin`)

A **tag** component. It holds no data; its mere presence marks an entity as
driven by the keyboard. The input and player-animation systems only touch
entities that have it.

```odin
PlayerControlled :: struct {}  // empty on purpose
```

## How the player is assembled (`spawn.odin`)

The player is not a special type. It is just an entity given the right set of
components:

```odin
spawn_player :: proc(w: ^World, a: ^Assets, position: raylib.Vector2) -> Entity {
    player := entity_create(w)
    store_add(&w.transforms, player, Transform{position = position})
    store_add(&w.velocities, player, Velocity{})
    store_add(&w.sprites, player, Sprite{texture = a.clips[.Idle][.Down].texture, tint = WHITE})
    store_add(&w.animations, player, AnimationState{kind = .Idle, direction = .Down})
    store_add(&w.player_controlled, player, PlayerControlled{})
    animation_apply_initial_frame(w, a, player)
    return player
}
```

To create a non-player character (say an enemy that moves but isn't keyboard
controlled), you would give it `Transform`, `Velocity`, `Sprite`, and
`AnimationState`, but **not** `PlayerControlled`.
