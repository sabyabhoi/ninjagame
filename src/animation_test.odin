package main

import "core:testing"
import "vendor:raylib"

@(test)
test_clip_from_horizontal_strip :: proc(t: ^testing.T) {
	tex := raylib.Texture2D{width = 32, height = 8}
	clip := clip_from_horizontal_strip(tex, 4, 0.15)
	defer delete(clip.frames)

	testing.expect(t, len(clip.frames) == 4, "expected 4 frames")
	testing.expect(t, clip.directions == 1, "expected non-directional clip")
	testing.expect(t, clip.frames_per_direction == 4, "expected 4 frames per direction")
	testing.expect(t, clip.frames[0].width == 8, "expected frame width 8")
	testing.expect(t, clip.frames[1].x == 8, "expected second frame x offset 8")
}

@(test)
test_clip_from_directional_grid :: proc(t: ^testing.T) {
	tex := raylib.Texture2D{width = 16, height = 16}
	directions := 4
	frames_per_direction := 4
	clip := clip_from_directional_grid(tex, directions, frames_per_direction, 0.10)
	defer delete(clip.frames)

	testing.expect(t, len(clip.frames) == 16, "expected 16 frames")
	testing.expect(t, clip.directions == directions, "expected 4 directions")
	testing.expect(
		t,
		clip.frames_per_direction == frames_per_direction,
		"expected 4 frames per direction",
	)

	idx := 2 * frames_per_direction + 3
	testing.expect(t, clip.frames[idx].x == 8, "expected x for column 2")
	testing.expect(t, clip.frames[idx].y == 12, "expected y for row 3")
}

@(test)
test_animation_frame_index :: proc(t: ^testing.T) {
	clip := AnimationClip{directions = 4, frames_per_direction = 4}
	state := AnimationState{frame_index = 2, column = 1}

	idx := animation_frame_index(&state, &clip)
	testing.expect(t, idx == 6, "expected frame index 6 for column 1 frame 2")
}
