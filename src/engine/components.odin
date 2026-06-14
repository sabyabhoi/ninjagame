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

// Which selection rule chooses this entity's clip each tick.
AnimationPolicy :: enum {
	Manual, // zero value: dispatch leaves state alone (e.g. weapon mirrors its owner)
	Locomotion, // velocity + attack_state -> Idle/Walk/Attack + facing
}

// Per-entity playback state for the currently active animation clip.
AnimationState :: struct {
	policy:      AnimationPolicy, // how kind/direction get chosen (Manual by default)
	kind:        AnimationKind, // Which clip (idle, walk, etc.) is playing.
	direction:   Direction, // Facing direction for clip lookup.
	frame_index: int, // Current frame within the active clip.
	timer:       f32, // Elapsed time toward advancing to the next frame.
}

AttackState :: struct {
	timer: f32,
}

EquippedWeapon :: struct {
	weapon_entity: Entity,
}

is_moving :: proc(velocity: ^Velocity) -> bool {
	return velocity.value.x != 0 || velocity.value.y != 0
}

