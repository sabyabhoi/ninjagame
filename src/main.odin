package main

import "core:strings"
import "vendor:raylib"

// Runs one fixed-timestep simulation tick: input, animation, and physics systems.
fixed_update :: proc(w: ^World, a: ^Assets, input: ^InputState, dt: f32) {
	player_input_system(w, input)
	player_animation_system(w)
	animation_system(w, a, dt)
	physics_system(w, dt)
}

// Clears the screen and renders the current frame.
draw :: proc(w: ^World) {
	raylib.ClearBackground(raylib.WHITE)

	render_system(w)
}

// Entry point: sets up the window, assets, world, and runs the main game loop.
main :: proc() {
	accumulator: f32 = 0

	raylib.InitWindow(
		CONFIG.window_width,
		CONFIG.window_height,
		strings.clone_to_cstring(CONFIG.window_title),
	)
	defer raylib.CloseWindow()

	a: Assets
	assets_init(&a)
	defer assets_destroy(&a)

	// tileset: Tileset
	// if !load_tileset(&a, &tileset, ASSET_PATHS.tileset) {
	// 	panic("Failed to load tileset")
	// }

	tilemap: Tilemap
	if !load_world(&a, &tilemap, ASSET_PATHS.tilemap) {
		panic("Failed to load world")
	}

	walk_tex, walk_ok := assets_load_texture(&a, ASSET_PATHS.walk)
	if !walk_ok do panic("Failed to load walk texture")

	assets_register_clip(
		&a,
		.Idle,
		clip_idle_from_walk_grid(
			walk_tex,
			WALK_DIRECTIONS,
			WALK_FRAMES_PER_DIRECTION,
			CONFIG.idle_frame_duration,
		),
	)
	assets_register_clip(
		&a,
		.Walk,
		clip_from_directional_grid(
			walk_tex,
			WALK_DIRECTIONS,
			WALK_FRAMES_PER_DIRECTION,
			CONFIG.walk_frame_duration,
		),
	)

	w: World
	world_init(&w)
	defer world_destroy(&w)

	input: InputState

	spawn_player(&w, &a, {100, 100})

	raylib.SetTargetFPS(CONFIG.target_fps)

	for !raylib.WindowShouldClose() {
		input_update(&input)

		dt := raylib.GetFrameTime()

		accumulator += dt

		for ; accumulator >= CONFIG.fixed_timestep; accumulator -= CONFIG.fixed_timestep {
			fixed_update(&w, &a, &input, CONFIG.fixed_timestep)
		}

		raylib.BeginDrawing()
		draw(&w)
		raylib.EndDrawing()
	}
}

