package main

import "vendor:raylib"

Action :: enum {
	MoveLeft,
	MoveRight,
	MoveUp,
	MoveDown,
	Jump,
	Attack,
}

InputState :: struct {
	pressed:  bit_set[Action],
	held:     bit_set[Action],
	released: bit_set[Action],
}

key_bindings := [Action]raylib.KeyboardKey {
	.MoveUp    = .W,
	.MoveLeft  = .A,
	.MoveDown  = .S,
	.MoveRight = .D,
	.Jump      = .SPACE,
	.Attack    = .J,
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

