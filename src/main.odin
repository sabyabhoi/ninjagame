package main

import "vendor:raylib"

WIDTH :: 800
HEIGHT :: 600
TITLE :: "Ninja Game"

fixed_update :: proc(w: ^World, dt: f32) {
	physics_system(w, dt)
}

draw :: proc(w: ^World) {
	raylib.ClearBackground(raylib.WHITE)

	size: f32 = 20
	for entity, &transform in w.transforms {
		raylib.DrawRectangleV(transform.position, {size, size}, raylib.BLACK)
	}
}

main :: proc() {
	FIXED_TIMESTAMP :: 1.0 / 60.0
	accumulator: f32 = 0

	raylib.InitWindow(WIDTH, HEIGHT, TITLE)
	defer raylib.CloseWindow()

	w: World
	world_init(&w)
	defer world_destroy(&w)

	player := entity_create(&w)
	add_transform(&w, player, Transform{position = {100, 100}})
	add_velocity(&w, player, Velocity{value = {50, 0}})

	raylib.SetTargetFPS(60)

	for !raylib.WindowShouldClose() {
		dt := raylib.GetFrameTime()

		accumulator += dt

		for ; accumulator >= FIXED_TIMESTAMP; accumulator -= FIXED_TIMESTAMP {
			fixed_update(&w, FIXED_TIMESTAMP)
		}


		raylib.BeginDrawing()
		draw(&w)
		raylib.EndDrawing()
	}
}

