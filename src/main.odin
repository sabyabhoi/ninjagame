package main

import "config"
import "core:strings"
import "engine"
import "vendor:raylib"

// Runs one fixed-timestep simulation tick: input, animation, and physics systems.
fixed_update :: proc(
	w: ^engine.World,
	ga: ^GameAssets,
	input: ^engine.InputState,
	camera: ^raylib.Camera2D,
	tilemap: ^engine.Tilemap,
	dt: f32,
) {
	player_input_system(w, input)
	player_anim_system(w, ga, input, dt)
	weapon_anim_system(w, ga, dt)
	engine.animation_system(w, dt)
	engine.physics_system(w, dt)
	engine.update_camera(w, tilemap, camera)
}

// Clears the screen and renders the current frame.
draw :: proc(w: ^engine.World, tilemap: ^engine.Tilemap) {
	raylib.ClearBackground(raylib.WHITE)

	engine.render_tilemap(tilemap)
	engine.render_system(w)
}

// Loads the world tilemap from disk, panicking on failure.
load_tilemap :: proc(a: ^engine.Assets) -> engine.Tilemap {
	tilemap: engine.Tilemap
	if !engine.load_world_tilemap(a, &tilemap, config.ASSET_PATHS.tilemap) {
		panic("Failed to load world tilemap")
	}
	return tilemap
}

// Initialises the game world, spawns the player, and configures the camera.
init_game :: proc(w: ^engine.World, ga: ^GameAssets, camera: ^raylib.Camera2D) {
	engine.world_init(w)
	spawn_player(w, ga, {400, 400})
	engine.init_camera(camera)
	raylib.SetTargetFPS(config.CONFIG.target_fps)
}

// Reads input and advances the simulation by the fixed timestep accumulator.
process_frame :: proc(
	accumulator: ^f32,
	w: ^engine.World,
	ga: ^GameAssets,
	input: ^engine.InputState,
	camera: ^raylib.Camera2D,
	tilemap: ^engine.Tilemap,
) {
	engine.input_update(input)

	accumulator^ += raylib.GetFrameTime()

	for ; accumulator^ >= config.CONFIG.fixed_timestep;
	    accumulator^ -= config.CONFIG.fixed_timestep {
		fixed_update(w, ga, input, camera, tilemap, config.CONFIG.fixed_timestep)
	}
}

// Begins the drawing context and renders the world through the camera.
present_frame :: proc(w: ^engine.World, camera: ^raylib.Camera2D, tilemap: ^engine.Tilemap) {
	raylib.BeginDrawing()
	raylib.BeginMode2D(camera^)
	draw(w, tilemap)
	raylib.EndMode2D()
	raylib.EndDrawing()
}

// The main loop: processes frames and presents them until the window is closed.
run_game_loop :: proc(
	w: ^engine.World,
	ga: ^GameAssets,
	input: ^engine.InputState,
	camera: ^raylib.Camera2D,
	tilemap: ^engine.Tilemap,
) {
	accumulator: f32 = 0

	for !raylib.WindowShouldClose() {
		process_frame(&accumulator, w, ga, input, camera, tilemap)
		present_frame(w, camera, tilemap)
	}
}

// Entry point: sets up the window, assets, world, and runs the main game loop.
main :: proc() {
	raylib.InitWindow(
		config.CONFIG.window_width,
		config.CONFIG.window_height,
		strings.clone_to_cstring(config.CONFIG.window_title),
	)
	defer raylib.CloseWindow()

	a: engine.Assets
	engine.assets_init(&a)
	defer engine.assets_destroy(&a)

	ga: GameAssets
	game_assets_init(&ga, &a)
	defer game_assets_destroy(&ga)

	tilemap := load_tilemap(&a)

	w: engine.World
	defer engine.world_destroy(&w)

	input: engine.InputState
	camera: raylib.Camera2D
	init_game(&w, &ga, &camera)

	run_game_loop(&w, &ga, &input, &camera, &tilemap)
}
