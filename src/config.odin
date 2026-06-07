package main

// File paths for game assets loaded at startup.
AssetPaths :: struct {
	walk: string, // Sprite sheet used for walk and idle animations.
}

// Tunable game and engine parameters.
Config :: struct {
	window_width:        i32, // Window width in pixels.
	window_height:       i32, // Window height in pixels.
	window_title:        string, // Title shown in the window bar.
	player_speed:        f32, // Movement speed in pixels per second.
	player_scale:        f32, // Uniform draw scale applied to the player sprite.
	idle_frame_duration: f32, // Seconds each idle frame is held.
	walk_frame_duration: f32, // Seconds each walk frame is held.
	fixed_timestep:      f32, // Simulation delta used for fixed-rate updates.
	target_fps:          i32, // Frame rate cap for the render loop.
}

ASSET_PATHS :: AssetPaths {
	walk = "assets/Actor/CharacterAnimated/NinjaGreen/Separate/Walk.png",
}

CONFIG :: Config {
	window_width        = 1200,
	window_height       = 800,
	window_title        = "Ninja Game",
	player_speed        = 300,
	player_scale        = 4,
	idle_frame_duration = 0.15,
	walk_frame_duration = 0.10,
	fixed_timestep      = 1.0 / 60.0,
	target_fps          = 60,
}

