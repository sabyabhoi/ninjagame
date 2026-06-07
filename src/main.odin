package main

import "config"
import "core:strings"
import "engine"
import "vendor:raylib"

// Runs one fixed-timestep simulation tick: input, animation, and physics systems.
fixed_update :: proc(w: ^engine.World, a: ^engine.Assets, input: ^engine.InputState, dt: f32) {
	player_input_system(w, input)
	player_animation_system(w)
	engine.animation_system(w, a, dt)
	engine.physics_system(w, dt)
}

// Clears the screen and renders the current frame.
draw :: proc(w: ^engine.World) {
	raylib.ClearBackground(raylib.WHITE)

	engine.render_system(w)
}

// Entry point: sets up the window, assets, world, and runs the main game loop.
main :: proc() {
	accumulator: f32 = 0

	raylib.InitWindow(
		config.CONFIG.window_width,
		config.CONFIG.window_height,
		strings.clone_to_cstring(config.CONFIG.window_title),
	)
	defer raylib.CloseWindow()

	a: engine.Assets
	engine.assets_init(&a)
	defer engine.assets_destroy(&a)

	// tileset: engine.Tileset
	// if !engine.load_tileset(&a, &tileset, config.ASSET_PATHS.tileset) {
	// 	panic("Failed to load tileset")
	// }

	tilemap: engine.Tilemap
	if !engine.load_world(&a, &tilemap, config.ASSET_PATHS.tilemap) {
		panic("Failed to load world")
	}

	walk_tex, walk_ok := engine.assets_load_texture(&a, config.ASSET_PATHS.walk)
	if !walk_ok do panic("Failed to load walk texture")

	engine.assets_register_clip(
		&a,
		.Idle,
		engine.clip_idle_from_walk_grid(
			walk_tex,
			engine.WALK_DIRECTIONS,
			engine.WALK_FRAMES_PER_DIRECTION,
			config.CONFIG.idle_frame_duration,
		),
	)
	engine.assets_register_clip(
		&a,
		.Walk,
		engine.clip_from_directional_grid(
			walk_tex,
			engine.WALK_DIRECTIONS,
			engine.WALK_FRAMES_PER_DIRECTION,
			config.CONFIG.walk_frame_duration,
		),
	)

	w: engine.World
	engine.world_init(&w)
	defer engine.world_destroy(&w)

	input: engine.InputState

	spawn_player(&w, &a, {100, 100})

	raylib.SetTargetFPS(config.CONFIG.target_fps)

	for !raylib.WindowShouldClose() {
		engine.input_update(&input)

		dt := raylib.GetFrameTime()

		accumulator += dt

		for ; accumulator >= config.CONFIG.fixed_timestep;
		    accumulator -= config.CONFIG.fixed_timestep {
			fixed_update(&w, &a, &input, config.CONFIG.fixed_timestep)
		}

		raylib.BeginDrawing()
		engine.render_tilemap(&tilemap)
		draw(&w)
		raylib.EndDrawing()
	}
}

