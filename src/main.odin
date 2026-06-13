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

// Loads the tilemap, player animation clips, and weapon attack overlays.
load_game_assets :: proc(a: ^engine.Assets, tilemap: ^engine.Tilemap) -> bool {
	if !engine.load_world(a, tilemap, config.ASSET_PATHS.tilemap) {
		return false
	}

	walk_tex, walk_ok := engine.assets_load_texture(a, config.ASSET_PATHS.walk)
	if !walk_ok do return false

	attack_tex, attack_ok := engine.assets_load_texture(a, config.ASSET_PATHS.attack)
	if !attack_ok do return false

	engine.assets_register_clip(
		a,
		.Idle,
		engine.clip_idle_from_walk_grid(
			walk_tex,
			engine.PLAYER_DIRECTIONS,
			engine.WALK_FRAMES_PER_DIRECTION,
			config.CONFIG.idle_frame_duration,
		),
	)
	engine.assets_register_clip(
		a,
		.Walk,
		engine.clip_from_directional_grid(
			walk_tex,
			engine.PLAYER_DIRECTIONS,
			engine.WALK_FRAMES_PER_DIRECTION,
			config.CONFIG.walk_frame_duration,
		),
	)
	engine.assets_register_clip(
		a,
		.Attack,
		engine.clip_from_directional_grid(
			attack_tex,
			engine.PLAYER_DIRECTIONS,
			engine.ATTACK_FRAMES_PER_DIRECTION,
			config.CONFIG.attack_frame_duration,
		),
	)

	weapons := []struct {
		kind:        engine.WeaponKind,
		attack_path: string,
	} {
		{.Katana, config.WEAPON_ASSETS.katana.attack},
		{.Shuriken, config.WEAPON_ASSETS.shuriken.attack},
		{.Kunai, config.WEAPON_ASSETS.kunai.attack},
		{.Bow, config.WEAPON_ASSETS.bow.attack},
		{.Staff, config.WEAPON_ASSETS.staff.attack},
	}

	for entry in weapons {
		if !engine.assets_load_weapon_attack(
			a,
			entry.kind,
			entry.attack_path,
			config.CONFIG.attack_frame_duration,
		) {
			fmt.eprintf("Warning: failed to load weapon attack overlay %v\n", entry.kind)
		}
	}

	return true
}

// Runs the fixed-timestep update loop and draws each frame until the window closes.
run_game_loop :: proc(w: ^engine.World, a: ^engine.Assets, tilemap: ^engine.Tilemap) {
	input: engine.InputState
	camera: raylib.Camera2D
	accumulator: f32

	engine.init_camera(&camera)
	raylib.SetTargetFPS(config.CONFIG.target_fps)

	for !raylib.WindowShouldClose() {
		engine.input_update(&input)

		accumulator += raylib.GetFrameTime()

		for ; accumulator >= config.CONFIG.fixed_timestep;
		    accumulator -= config.CONFIG.fixed_timestep {
			fixed_update(w, a, &input, &camera, tilemap, config.CONFIG.fixed_timestep)
		}

		raylib.BeginDrawing()
		raylib.BeginMode2D(camera)
		draw(w, tilemap)
		raylib.EndMode2D()
		raylib.EndDrawing()
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

	tilemap: engine.Tilemap
	if !load_game_assets(&a, &tilemap) {
		panic("Failed to load game assets")
	}

	w: engine.World
	engine.world_init(&w)
	defer engine.world_destroy(&w)

	spawn_player(&w, &a, {400, 400})
	run_game_loop(&w, &a, &tilemap)
}

