package main

import "core:fmt"
import "vendor:raylib"

WIDTH :: 800
HEIGHT :: 600
TITLE :: "Ninja Game"

fixed_update :: proc(dt: f32) {
	fmt.println(dt)
}

draw :: proc() {}

main :: proc() {
	FIXED_TIMESTAMP :: 1.0 / 60.0

	accumulator: f32 = 0

	raylib.InitWindow(WIDTH, HEIGHT, TITLE)
	defer raylib.CloseWindow()

	raylib.SetTargetFPS(60)

	for !raylib.WindowShouldClose() {
		dt := raylib.GetFrameTime()

		accumulator += dt

		for ; accumulator >= FIXED_TIMESTAMP; accumulator -= FIXED_TIMESTAMP {
			fixed_update(FIXED_TIMESTAMP)
		}


		raylib.BeginDrawing()
		draw()
		raylib.EndDrawing()
	}
}

