package engine

import "vendor:raylib"

// Spatial placement and size multiplier for an entity on screen.
Transform :: struct {
	position: raylib.Vector2, // Top-left corner in screen space.
	scale:    raylib.Vector2, // Multiplier applied to the sprite source rect.
}

// Per-frame movement vector for physics integration.
Velocity :: struct {
	value: raylib.Vector2, // Pixels per second along each axis.
}

// Drawable appearance pulled from a texture atlas region.
Sprite :: struct {
	texture: raylib.Texture2D, // GPU texture backing this sprite.
	source:  raylib.Rectangle, // Sub-rectangle within the texture; full texture when zero-sized.
	tint:    raylib.Color, // Color multiplier applied at draw time.
}

// Marker component: entity receives player input each tick.
PlayerControlled :: struct {}

// Per-entity playback state for the currently active animation clip.
AnimationState :: struct {
	kind:        AnimationKind, // Which clip (idle, walk, etc.) is playing.
	frame_index: int, // Current frame within the active direction column.
	column:      int, // Facing direction index into the clip's grid.
	timer:       f32, // Elapsed time toward advancing to the next frame.
}

// Attaches (or replaces) the transform component on an entity.
add_transform :: proc(w: ^World, e: Entity, t: Transform) {w.transforms[e] = t}
// Attaches (or replaces) the velocity component on an entity.
add_velocity :: proc(w: ^World, e: Entity, v: Velocity) {w.velocities[e] = v}
// Attaches (or replaces) the sprite component on an entity.
add_sprite :: proc(w: ^World, e: Entity, s: Sprite) {w.sprites[e] = s}
// Attaches (or replaces) the animation state component on an entity.
add_animation :: proc(w: ^World, e: Entity, a: AnimationState) {w.animations[e] = a}
// Tags an entity as player-controlled so input drives its movement.
add_player_controlled :: proc(w: ^World, e: Entity) {w.player_controlled[e] = {}}

// Returns a pointer to the entity's transform, or false if it has none.
get_transform :: proc(w: ^World, e: Entity) -> (^Transform, bool) {
	if t, ok := &w.transforms[e]; ok {
		return t, true
	}
	return nil, false
}

// Returns a pointer to the entity's velocity, or false if it has none.
get_velocity :: proc(w: ^World, e: Entity) -> (^Velocity, bool) {
	if v, ok := &w.velocities[e]; ok {
		return v, true
	}
	return nil, false
}

// Returns a pointer to the entity's sprite, or false if it has none.
get_sprite :: proc(w: ^World, e: Entity) -> (^Sprite, bool) {
	if s, ok := &w.sprites[e]; ok {
		return s, true
	}
	return nil, false
}

// Returns a pointer to the entity's animation state, or false if it has none.
get_animation :: proc(w: ^World, e: Entity) -> (^AnimationState, bool) {
	if a, ok := &w.animations[e]; ok {
		return a, true
	}
	return nil, false
}

