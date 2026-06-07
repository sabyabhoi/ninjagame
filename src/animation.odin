package main

import "core:math"
import "vendor:raylib"

AnimationClip :: struct {
	texture:              raylib.Texture2D,
	frames:               []raylib.Rectangle,
	duration:             f32,
	directions:           int,
	frames_per_direction: int,
}

AnimationKind :: enum {
	Idle,
	Walk,
}

AnimationState :: struct {
	kind:        AnimationKind,
	frame_index: int,
	column:      int,
	timer:       f32,
}

WALK_COL_DOWN :: 0
WALK_COL_LEFT :: 1
WALK_COL_RIGHT :: 2
WALK_COL_UP :: 3

IDLE_FRAME_COUNT :: 4
WALK_DIRECTIONS :: 4
WALK_FRAMES_PER_DIRECTION :: 4

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

animation_system :: proc(w: ^World, a: ^Assets, dt: f32) {
	for entity, &state in w.animations {
		sprite, sprite_ok := get_sprite(w, entity)
		if !sprite_ok do continue

		clip := &a.clips[state.kind]
		if len(clip.frames) == 0 do continue

		state.timer += dt
		for state.timer >= clip.duration {
			state.timer -= clip.duration
			state.frame_index =
				(state.frame_index + 1) % clip.frames_per_direction
		}

		frame_idx := state.frame_index
		if clip.directions > 1 {
			frame_idx = state.column * clip.frames_per_direction + state.frame_index
		}

		sprite.texture = clip.texture
		sprite.source = clip.frames[frame_idx]
	}
}

player_animation_system :: proc(w: ^World) {
	for entity in w.player_controlled {
		state, state_ok := get_animation(w, entity)
		if !state_ok do continue

		vel, vel_ok := get_velocity(w, entity)
		if !vel_ok do continue

		prev_kind := state.kind
		prev_column := state.column

		moving := vel.value.x != 0 || vel.value.y != 0
		if moving {
			state.kind = .Walk

			abs_x := math.abs(vel.value.x)
			abs_y := math.abs(vel.value.y)

			if abs_x >= abs_y {
				if vel.value.x < 0 {
					state.column = WALK_COL_LEFT
				} else {
					state.column = WALK_COL_RIGHT
				}
			} else {
				if vel.value.y < 0 {
					state.column = WALK_COL_UP
				} else {
					state.column = WALK_COL_DOWN
				}
			}
		} else {
			state.kind = .Idle
		}

		if state.kind != prev_kind || state.column != prev_column {
			state.frame_index = 0
			state.timer = 0
		}
	}
}
