package engine

import "core:math"
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
create_clip_from_horizontal_strip :: proc(
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
create_clip_from_sheet_column :: proc(
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

// Chooses animation kind and facing from gameplay state (velocity, attack).
select_animation :: proc(w: ^World, entity: Entity, state: ^AnimationState) {
	prev_kind := state.kind
	prev_direction := state.direction

	if _, attacking := store_get(&w.attack_state, entity); attacking {
		state.kind = .Attack
	} else if vel, vel_ok := store_get(&w.velocities, entity);
	   vel_ok && is_moving(vel) {
		state.kind = .Walk
	} else {
		state.kind = .Idle
	}

	if vel, vel_ok := store_get(&w.velocities, entity); vel_ok {
		update_entity_direction(vel, entity, state)
	}

	if state.kind != prev_kind || state.direction != prev_direction {
		state.frame_index = 0
		state.timer = 0
	}
}

update_entity_direction :: proc(velocity: ^Velocity, entity: Entity, state: ^AnimationState) {
	if is_moving(velocity) {
		abs_x := math.abs(velocity.value.x)
		abs_y := math.abs(velocity.value.y)

		if abs_x >= abs_y {
			if velocity.value.x < 0 {
				state.direction = .Left
			} else {
				state.direction = .Right
			}
		} else {
			if velocity.value.y < 0 {
				state.direction = .Up
			} else {
				state.direction = .Down
			}
		}
	}
}

// Advances the animation timer and applies the current frame to the sprite.
advance_animation :: proc(w: ^World, a: ^Assets, entity: Entity, state: ^AnimationState, dt: f32) {
	sprite, sprite_ok := store_get(&w.sprites, entity)

	clip := assets_get_clip(a, state.kind, state.direction)
	if len(clip.frames) == 0 do return

	state.timer += dt
	for state.timer >= clip.duration {
		state.timer -= clip.duration
		state.frame_index = (state.frame_index + 1) % len(clip.frames)
	}

	animation_apply_sprite_frame(sprite, state, clip)
}

// Sets an entity's sprite to the first frame of its current animation clip.
animation_apply_initial_frame :: proc(w: ^World, a: ^Assets, entity: Entity) {
	state, state_ok := store_get(&w.animations, entity)
	sprite, sprite_ok := store_get(&w.sprites, entity)
	if !state_ok || !sprite_ok do return

	clip := assets_get_clip(a, state.kind, state.direction)
	animation_apply_sprite_frame(sprite, state, clip)
}

