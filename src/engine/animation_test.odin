package engine

import "core:testing"
import "vendor:raylib"

// Verifies a horizontal strip is split into evenly-sized frames.
@(test)
test_clip_from_horizontal_strip :: proc(t: ^testing.T) {
	tex := raylib.Texture2D {
		width  = 32,
		height = 8,
	}
	clip := clip_from_horizontal_strip(tex, 4, 0.15)
	defer delete(clip.frames)

	testing.expect(t, len(clip.frames) == 4, "expected 4 frames")
	testing.expect(t, clip.frames[0].width == 8, "expected frame width 8")
	testing.expect(t, clip.frames[1].x == 8, "expected second frame x offset 8")
}

// Verifies a sheet column produces the expected frame count and per-cell offsets.
@(test)
test_clip_from_sheet_column :: proc(t: ^testing.T) {
	tex := raylib.Texture2D {
		width  = 16,
		height = 16,
	}
	frame_count := 4
	clip := clip_from_sheet_column(tex, 2, 4, frame_count, frame_count, 0.10)
	defer delete(clip.frames)

	testing.expect(t, len(clip.frames) == frame_count, "expected 4 frames")
	testing.expect(t, clip.frames[0].x == 8, "expected x for column 2")
	testing.expect(t, clip.frames[0].y == 0, "expected y for row 0")
	testing.expect(t, clip.frames[3].x == 8, "expected x for column 2 last frame")
	testing.expect(t, clip.frames[3].y == 12, "expected y for row 3")
}

// Verifies idle clips use one row-sized frame, not the full column height.
@(test)
test_clip_from_sheet_column_idle :: proc(t: ^testing.T) {
	tex := raylib.Texture2D {
		width  = 16,
		height = 16,
	}
	clip := clip_from_sheet_column(tex, 1, 4, 4, 1, 0.15)
	defer delete(clip.frames)

	testing.expect(t, len(clip.frames) == 1, "expected 1 idle frame")
	testing.expect(t, clip.frames[0].height == 4, "expected row height 4, not full column")
	testing.expect(t, clip.frames[0].y == 0, "expected top row")
}

// Verifies logical directions map to the player sprite sheet column order.
@(test)
test_direction_sheet_columns :: proc(t: ^testing.T) {
	testing.expect(t, DIRECTION_SHEET_COLUMNS[.Down] == 0, "expected down in column 0")
	testing.expect(t, DIRECTION_SHEET_COLUMNS[.Up] == 1, "expected up in column 1")
	testing.expect(t, DIRECTION_SHEET_COLUMNS[.Left] == 2, "expected left in column 2")
	testing.expect(t, DIRECTION_SHEET_COLUMNS[.Right] == 3, "expected right in column 3")
}
