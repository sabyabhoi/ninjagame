package main

import "vendor:raylib"

WIDTH :: 800
HEIGHT :: 600
TITLE :: "Ninja Game"

fixed_update :: proc(w: ^World, input: ^InputState, player: Entity, dt: f32) {
	player_input_system(w, input, player)
	physics_system(w, dt)
}

draw :: proc(w: ^World) {
	raylib.ClearBackground(raylib.WHITE)

	render_system(w)

	// size: f32 = 20
	// for entity, &transform in w.transforms {
	// 	raylib.DrawRectangleV(transform.position, {size, size}, raylib.BLACK)
	// }
}

main :: proc() {
	FIXED_TIMESTAMP :: 1.0 / 60.0
	accumulator: f32 = 0

	raylib.InitWindow(WIDTH, HEIGHT, TITLE)
	defer raylib.CloseWindow()

	a: Assets
	assets_init(&a)
	defer assets_destroy(&a)


	w: World
	world_init(&w)
	defer world_destroy(&w)

	input: InputState

	player := entity_create(&w)
	add_transform(&w, player, Transform{position = {100, 100}})
	add_velocity(&w, player, Velocity{})

	texture := assets_load_texture(&a, "assets/Actor/Character/Boy/SeparateAnim/Idle.png")
	add_sprite(&w, player, Sprite{texture = texture, tint = raylib.WHITE})

	raylib.SetTargetFPS(60)

	for !raylib.WindowShouldClose() {
		input_update(&input)

		dt := raylib.GetFrameTime()

		accumulator += dt

		for ; accumulator >= FIXED_TIMESTAMP; accumulator -= FIXED_TIMESTAMP {
			fixed_update(&w, &input, player, FIXED_TIMESTAMP)
		}


		raylib.BeginDrawing()
		draw(&w)
		raylib.EndDrawing()
	}
}

