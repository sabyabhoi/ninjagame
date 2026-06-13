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

AttackState :: struct {
	timer: f32,
}

// Weapon sprite drawn on top of the body during attack; hidden while idle or walking.
WeaponOverlay :: struct {
	sprite:  Sprite,
	visible: bool,
}

