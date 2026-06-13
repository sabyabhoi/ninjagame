package main

import "config"
import "core:fmt"
import "core:strings"
import "engine"
import "vendor:raylib"

// Runs one fixed-timestep simulation tick: input, animation, and physics systems.
fixed_update :: proc(
	w: ^engine.World,
	a: ^engine.Assets,
	input: ^engine.InputState,
	camera: ^raylib.Camera2D,
	tilemap: ^engine.Tilemap,
	dt: f32,
) {
	player_input_system(w, input)
	player_attack_system(w, input)
	player_movement_system(w)

	engine.attack_system(w, dt)
	engine.animation_system(w, a, dt)
	engine.physics_system(w, dt)
	engine.update_camera(w, tilemap, camera)
}

// Clears the screen and renders the current frame.
draw :: proc(w: ^engine.World, tilemap: ^engine.Tilemap) {
	raylib.ClearBackground(raylib.WHITE)

	engine.render_tilemap(tilemap)
	engine.render_system(w)
}

load_tilemap :: proc(a: ^engine.Assets) -> engine.Tilemap {
	tilemap: engine.Tilemap
	if !engine.load_world_tilemap(a, &tilemap, config.ASSET_PATHS.tilemap) {
		panic("Failed to load world tilemap")
	}
	return tilemap
}

register_player_clips :: proc(a: ^engine.Assets) {
	walk_spritesheet, walk_ok := engine.assets_load_texture(a, config.ASSET_PATHS.walk)
	if !walk_ok do panic("Failed to load walk texture")

	attack_spritesheet, attack_ok := engine.assets_load_texture(a, config.ASSET_PATHS.attack)
	if !attack_ok do panic("Failed to load attack texture")

	engine.assets_register_clip(
		a,
		.Idle,
		engine.build_clip_idle_from_walk_grid(
			walk_spritesheet,
			engine.PLAYER_DIRECTIONS,
			engine.WALK_FRAMES_PER_DIRECTION,
			config.CONFIG.idle_frame_duration,
		),
	)
	engine.assets_register_clip(
		a,
		.Walk,
		engine.build_clip_from_directional_grid(
			walk_spritesheet,
			engine.PLAYER_DIRECTIONS,
			engine.WALK_FRAMES_PER_DIRECTION,
			config.CONFIG.walk_frame_duration,
		),
	)
	engine.assets_register_clip(
		a,
		.Attack,
		engine.build_clip_from_directional_grid(
			attack_spritesheet,
			engine.PLAYER_DIRECTIONS,
			engine.ATTACK_FRAMES_PER_DIRECTION,
			config.CONFIG.attack_frame_duration,
		),
	)
}

init_game :: proc(w: ^engine.World, a: ^engine.Assets, camera: ^raylib.Camera2D) {
	engine.world_init(w)
	spawn_player(w, a, {400, 400})
	engine.init_camera(camera)
	raylib.SetTargetFPS(config.CONFIG.target_fps)
}

process_frame :: proc(
	accumulator: ^f32,
	w: ^engine.World,
	a: ^engine.Assets,
	input: ^engine.InputState,
	camera: ^raylib.Camera2D,
	tilemap: ^engine.Tilemap,
) {
	engine.input_update(input)

	accumulator^ += raylib.GetFrameTime()

	for ; accumulator^ >= config.CONFIG.fixed_timestep;
	    accumulator^ -= config.CONFIG.fixed_timestep {
		fixed_update(w, a, input, camera, tilemap, config.CONFIG.fixed_timestep)
	}
}

present_frame :: proc(w: ^engine.World, camera: ^raylib.Camera2D, tilemap: ^engine.Tilemap) {
	raylib.BeginDrawing()
	raylib.BeginMode2D(camera^)
	draw(w, tilemap)
	raylib.EndMode2D()
	raylib.EndDrawing()
}

run_game_loop :: proc(
	w: ^engine.World,
	a: ^engine.Assets,
	input: ^engine.InputState,
	camera: ^raylib.Camera2D,
	tilemap: ^engine.Tilemap,
) {
	accumulator: f32 = 0

	for !raylib.WindowShouldClose() {
		process_frame(&accumulator, w, a, input, camera, tilemap)
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

	tilemap := load_tilemap(&a)
	register_player_clips(&a)

	w: engine.World
	defer engine.world_destroy(&w)

	input: engine.InputState
	camera: raylib.Camera2D
	init_game(&w, &a, &camera)

	run_game_loop(&w, &a, &input, &camera, &tilemap)
}

