package engine

import "vendor:raylib"

// Game actions mapped from keyboard keys.
Action :: enum {
	MoveLeft,
	MoveRight,
	MoveUp,
	MoveDown,
	Attack,
}

// Snapshot of player input for the current frame.
InputState :: struct {
	pressed:  bit_set[Action], // Actions whose keys were pressed this frame.
	held:     bit_set[Action], // Actions whose keys are currently down.
	released: bit_set[Action], // Actions whose keys were released this frame.
}

key_bindings := [Action]raylib.KeyboardKey {
	.MoveUp    = .W,
	.MoveLeft  = .A,
	.MoveDown  = .S,
	.MoveRight = .D,
	.Attack    = .SPACE,
}

// Polls the keyboard and refreshes the pressed, held, and released action sets.
input_update :: proc(input: ^InputState) {
	input.pressed = {}
	input.held = {}
	input.released = {}

	for key, action in key_bindings {
		if raylib.IsKeyPressed(key) do input.pressed += {action}
		if raylib.IsKeyDown(key) do input.held += {action}
		if raylib.IsKeyReleased(key) do input.released += {action}
	}
}

