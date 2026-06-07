package engine

import "vendor:raylib"

// Sprite-sheet animation data: frame rects, timing, and directional layout.
AnimationClip :: struct {
	texture:              raylib.Texture2D, // Shared texture for all frames in this clip.
	frames:               []raylib.Rectangle, // Source rects laid out by direction then frame.
	duration:             f32, // Seconds each frame is displayed before advancing.
	directions:           int, // Number of facing columns in the source grid.
	frames_per_direction: int, // Animation frames per facing direction.
}

// Named animation clips available to entities.
AnimationKind :: enum {
	Idle,
	Walk,
}

WALK_COL_DOWN :: 0
WALK_COL_LEFT :: 2
WALK_COL_RIGHT :: 3
WALK_COL_UP :: 1

WALK_DIRECTIONS :: 4
WALK_FRAMES_PER_DIRECTION :: 4

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

	return {
		texture = tex,
		frames = frames,
		duration = duration,
		directions = 1,
		frames_per_direction = frame_count,
	}
}

// Builds a multi-direction animation clip from a grid where columns are directions and rows are frames.
clip_from_directional_grid :: proc(
	tex: raylib.Texture2D,
	directions: int,
	frames_per_direction: int,
	duration: f32,
) -> AnimationClip {
	frame_w := f32(tex.width) / f32(directions)
	frame_h := f32(tex.height) / f32(frames_per_direction)

	frames := make([]raylib.Rectangle, directions * frames_per_direction)
	for col in 0 ..< directions {
		for row in 0 ..< frames_per_direction {
			idx := col * frames_per_direction + row
			frames[idx] = {
				x      = f32(col) * frame_w,
				y      = f32(row) * frame_h,
				width  = frame_w,
				height = frame_h,
			}
		}
	}

	return {
		texture = tex,
		frames = frames,
		duration = duration,
		directions = directions,
		frames_per_direction = frames_per_direction,
	}
}

// Builds an idle clip by taking the first frame of each direction from a walk grid.
clip_idle_from_walk_grid :: proc(
	tex: raylib.Texture2D,
	directions: int,
	walk_frames_per_direction: int,
	duration: f32,
) -> AnimationClip {
	frame_w := f32(tex.width) / f32(directions)
	frame_h := f32(tex.height) / f32(walk_frames_per_direction)

	frames := make([]raylib.Rectangle, directions)
	for col in 0 ..< directions {
		frames[col] = {
			x      = f32(col) * frame_w,
			y      = 0,
			width  = frame_w,
			height = frame_h,
		}
	}

	return {
		texture = tex,
		frames = frames,
		duration = duration,
		directions = directions,
		frames_per_direction = 1,
	}
}

// Computes the flat frame array index for the current direction column and frame.
animation_frame_index :: proc(state: ^AnimationState, clip: ^AnimationClip) -> int {
	frame_idx := state.frame_index
	if clip.directions > 1 {
		frame_idx = state.column * clip.frames_per_direction + state.frame_index
	}
	return frame_idx
}

// Updates a sprite's texture and source rect to match the current animation frame.
animation_apply_sprite_frame :: proc(
	sprite: ^Sprite,
	state: ^AnimationState,
	clip: ^AnimationClip,
) {
	if len(clip.frames) == 0 do return

	frame_idx := animation_frame_index(state, clip)
	sprite.texture = clip.texture
	sprite.source = clip.frames[frame_idx]
}

// Sets an entity's sprite to the first frame of its current animation clip.
animation_apply_initial_frame :: proc(w: ^World, a: ^Assets, entity: Entity) {
	state, state_ok := get_animation(w, entity)
	sprite, sprite_ok := get_sprite(w, entity)
	if !state_ok || !sprite_ok do return

	clip := &a.clips[state.kind]
	animation_apply_sprite_frame(sprite, state, clip)
}

