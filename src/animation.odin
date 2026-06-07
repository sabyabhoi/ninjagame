package main

import "vendor:raylib"

AnimationClip :: struct {
	texture:  raylib.Texture2D,
	frames:   []raylib.Rectangle,
	duration: f32,
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

WALK_FRAMES_PER_COLUMN :: 4
IDLE_FRAME_COUNT :: 4

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

clip_from_directional_grid :: proc(tex: raylib.Texture2D, duration: f32) -> AnimationClip {
	cols :: 4
	rows :: 4
	frame_w := f32(tex.width) / f32(cols)
	frame_h := f32(tex.height) / f32(rows)

	frames := make([]raylib.Rectangle, cols * rows)
	for col in 0 ..< cols {
		for row in 0 ..< rows {
			idx := col * rows + row
			frames[idx] = {
				x      = f32(col) * frame_w,
				y      = f32(row) * frame_h,
				width  = frame_w,
				height = frame_h,
			}
		}
	}

	return {texture = tex, frames = frames, duration = duration}
}

animation_clip_for_kind :: proc(a: ^Assets, kind: AnimationKind) -> ^AnimationClip {
	switch kind {
	case .Idle:
		return assets_get_clip(a, "idle")
	case .Walk:
		return assets_get_clip(a, "walk")
	}
	return nil
}

animation_system :: proc(w: ^World, a: ^Assets, dt: f32) {
	for entity, &state in w.animations {
		sprite, sprite_ok := &w.sprites[entity]
		if !sprite_ok do continue

		clip := animation_clip_for_kind(a, state.kind)
		if clip == nil || len(clip.frames) == 0 do continue

		state.timer += dt
		for state.timer >= clip.duration {
			state.timer -= clip.duration
			max_frames := len(clip.frames)
			if state.kind == .Walk {
				max_frames = WALK_FRAMES_PER_COLUMN
			}
			state.frame_index = (state.frame_index + 1) % max_frames
		}

		frame_idx := state.frame_index
		if state.kind == .Walk {
			frame_idx = state.column * WALK_FRAMES_PER_COLUMN + state.frame_index
		}

		sprite.texture = clip.texture
		sprite.source = clip.frames[frame_idx]
	}
}

player_animation_system :: proc(w: ^World, player: Entity) {
	state, ok := &w.animations[player]
	if !ok do return

	vel, vel_ok := w.velocities[player]
	if !vel_ok do return

	prev_kind := state.kind
	prev_column := state.column

	moving := vel.value.x != 0 || vel.value.y != 0
	if moving {
		state.kind = .Walk

		abs_x := vel.value.x
		if abs_x < 0 do abs_x = -abs_x
		abs_y := vel.value.y
		if abs_y < 0 do abs_y = -abs_y

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
