package engine

import "vendor:raylib"

// Spatial placement for an entity in the world, in native (unscaled) pixels.
// Global render scaling is applied uniformly by the camera, not per entity.
Transform :: struct {
	position: raylib.Vector2, // Top-left corner in world space.
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

// Logical facing direction for entities that orient their sprites.
Facing :: struct {
	direction: Direction,
}

// Per-entity playback state for the currently active animation clip.
AnimationState :: struct {
	clip:        ^AnimationClip,
	frame_index: int,
	timer:       f32,
}

EquippedWeapon :: struct {
	weapon_entity: Entity,
}

is_moving :: proc(velocity: ^Velocity) -> bool {
	return velocity.value.x != 0 || velocity.value.y != 0
}
