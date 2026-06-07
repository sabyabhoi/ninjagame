package main

AssetPaths :: struct {
	idle: string,
	walk: string,
}

Config :: struct {
	window_width:        i32,
	window_height:       i32,
	window_title:        string,
	player_speed:        f32,
	player_scale:        f32,
	idle_frame_duration: f32,
	walk_frame_duration: f32,
	fixed_timestep:      f32,
	target_fps:          i32,
}

ASSET_PATHS :: AssetPaths {
	idle = "assets/Actor/Character/Boy/SeparateAnim/Idle.png",
	walk = "assets/Actor/Character/Boy/SeparateAnim/Walk.png",
}

CONFIG :: Config {
	window_width        = 800,
	window_height       = 600,
	window_title        = "Ninja Game",
	player_speed        = 300,
	player_scale        = 4,
	idle_frame_duration = 0.15,
	walk_frame_duration = 0.10,
	fixed_timestep      = 1.0 / 60.0,
	target_fps          = 60,
}
