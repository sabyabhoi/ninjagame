package main

import "vendor:raylib"

WIDTH :: 800
HEIGHT :: 600
TITLE :: "Ninja Game"

IDLE_PATH :: "assets/Actor/Character/Boy/SeparateAnim/Idle.png"
WALK_PATH :: "assets/Actor/Character/Boy/SeparateAnim/Walk.png"

fixed_update :: proc(w: ^World, a: ^Assets, input: ^InputState, player: Entity, dt: f32) {
	player_input_system(w, input, player)
	player_animation_system(w, player)
	animation_system(w, a, dt)
	physics_system(w, dt)
}

draw :: proc(w: ^World) {
	raylib.ClearBackground(raylib.WHITE)

	render_system(w)
}

main :: proc() {
	FIXED_TIMESTAMP :: 1.0 / 60.0
	accumulator: f32 = 0

	raylib.InitWindow(WIDTH, HEIGHT, TITLE)
	defer raylib.CloseWindow()

	a: Assets
	assets_init(&a)
	defer assets_destroy(&a)

	idle_tex := assets_load_texture(&a, IDLE_PATH)
	walk_tex := assets_load_texture(&a, WALK_PATH)
	assets_register_clip(&a, "idle", clip_from_horizontal_strip(idle_tex, IDLE_FRAME_COUNT, 0.15))
	assets_register_clip(&a, "walk", clip_from_directional_grid(walk_tex, 0.10))

	w: World
	world_init(&w)
	defer world_destroy(&w)

	input: InputState

	player := entity_create(&w)
	add_transform(&w, player, Transform{position = {100, 100}, scale = {4, 4}})
	add_velocity(&w, player, Velocity{})
	add_sprite(&w, player, Sprite{texture = idle_tex, tint = raylib.WHITE})
	add_animation(&w, player, AnimationState{kind = .Idle})

	animation_system(&w, &a, 0)

	raylib.SetTargetFPS(60)

	for !raylib.WindowShouldClose() {
		input_update(&input)

		dt := raylib.GetFrameTime()

		accumulator += dt

		for ; accumulator >= FIXED_TIMESTAMP; accumulator -= FIXED_TIMESTAMP {
			fixed_update(&w, &a, &input, player, FIXED_TIMESTAMP)
		}

		raylib.BeginDrawing()
		draw(&w)
		raylib.EndDrawing()
	}
}
