package engine

import "vendor:raylib"

// Sprite-sheet animation data: frame rects and per-frame timing.
AnimationClip :: struct {
	texture:  raylib.Texture2D, // Shared texture for all frames in this clip.
	frames:   []raylib.Rectangle, // Source rects played in order.
	duration: f32, // Seconds each frame is displayed before advancing.
}

// Named animation clips available to entities.
AnimationKind :: enum {
	Idle,
	Walk,
	Attack,
}

// Logical facing direction for animated entities.
Direction :: enum {
	Down,
	Left,
	Right,
	Up,
}

// Player sprite sheet column index for each logical facing direction.
DIRECTION_SHEET_COLUMNS := [Direction]int {
	.Down  = 0,
	.Up    = 1,
	.Left  = 2,
	.Right = 3,
}

// Builds a single-row, non-directional animation clip from a horizontal sprite strip.
clip_from_horizontal_strip :: proc(
	tex: raylib.Texture2D,
	frame_count: int,
	duration: f32,
) -> AnimationClip {
	frame_w := f32(tex.width) / f32(frame_count)
	frame_h := f32(tex.height)

	frames := make([]raylib.Rectangle, frame_count)
	for i in 0 ..< frame_count {
		frames[i] = {
			x      = f32(i) * frame_w,
			y      = 0,
			width  = frame_w,
			height = frame_h,
		}
	}

	return {texture = tex, frames = frames, duration = duration}
}

// Builds one animation clip from a single column of a directional sprite sheet grid.
clip_from_sheet_column :: proc(
	tex: raylib.Texture2D,
	column: int,
	total_columns: int,
	rows_in_sheet: int,
	frame_count: int,
	duration: f32,
) -> AnimationClip {
	frame_w := f32(tex.width) / f32(total_columns)
	frame_h := f32(tex.height) / f32(rows_in_sheet)

	frames := make([]raylib.Rectangle, frame_count)
	for row in 0 ..< frame_count {
		frames[row] = {
			x      = f32(column) * frame_w,
			y      = f32(row) * frame_h,
			width  = frame_w,
			height = frame_h,
		}
	}

	return {texture = tex, frames = frames, duration = duration}
}

// Updates a sprite's texture and source rect to match the current animation frame.
animation_apply_sprite_frame :: proc(
	sprite: ^Sprite,
	state: ^AnimationState,
	clip: ^AnimationClip,
) {
	if len(clip.frames) == 0 do return

	sprite.texture = clip.texture
	sprite.source = clip.frames[state.frame_index]
}

// Sets an entity's sprite to the first frame of its current animation clip.
animation_apply_initial_frame :: proc(w: ^World, a: ^Assets, entity: Entity) {
	state, state_ok := store_get(&w.animations, entity)
	sprite, sprite_ok := store_get(&w.sprites, entity)
	if !state_ok || !sprite_ok do return

	clip := assets_get_clip(a, state.kind, state.direction)
	animation_apply_sprite_frame(sprite, state, clip)
}

