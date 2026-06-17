package config

// File paths for game assets loaded at startup.
AssetPaths :: struct {
	walk:    string, // Sprite sheet used for player walk and idle animations.
	attack:  string, // Sprite sheet used for player attack animation
	weapon:  string, // Sprite sheet used for player weapon
	tileset: string, // Tiled external tileset (.tsx) referenced by the map.
	tilemap: string, // Tiled map file (.tmx).
}

// Tunable game and engine parameters.
Config :: struct {
	window_width:   i32, // Window width in pixels.
	window_height:  i32, // Window height in pixels.
	window_title:   string, // Title shown in the window bar.
	render_scale:   f32, // Global zoom applied to the whole world at render time.
	player:         PlayerConfig,
	fixed_timestep: f32, // Simulation delta used for fixed-rate updates.
	target_fps:     i32, // Frame rate cap for the render loop.
}

PlayerConfig :: struct {
	speed:                 f32, // Movement speed in native pixels per second.
	idle_frame_duration:   f32, // Seconds each idle frame is held.
	walk_frame_duration:   f32, // Seconds each walk frame is held.
	attack_frame_duration: f32, // Seconds each attack frame is held.
}

ASSET_PATHS :: AssetPaths {
	walk    = "res/assets/Actor/CharacterAnimated/NinjaGreen/Separate/Walk.png",
	attack  = "res/assets/Actor/CharacterAnimated/NinjaGreen/Separate/Attack.png",
	weapon  = "res/assets/Actor/CharacterAnimated/Weapon/Hammer.png",
	tileset = "res/map/TilesetFloor.tsx",
	tilemap = "res/map/map1.tmx",
}

CONFIG :: Config {
	window_width = 1200,
	window_height = 800,
	window_title = "Ninja Game",
	render_scale = 4,
	player = {
		speed = 75,
		idle_frame_duration = 0.15,
		walk_frame_duration = 0.10,
		attack_frame_duration = 0.10,
	},
	fixed_timestep = 1.0 / 60.0,
	target_fps = 60,
}

