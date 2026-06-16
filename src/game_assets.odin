package main

import "config"
import "engine"

PlayerAnimClips :: struct {
	clips: [engine.PlayerAnimState][engine.Direction]engine.AnimationClip,
}

WeaponAnimClips :: struct {
	clips: [engine.WeaponAnimState][engine.Direction]engine.AnimationClip,
}

GameAssets :: struct {
	player: PlayerAnimClips,
	weapon: WeaponAnimClips,
}

player_clip :: proc(
	ga: ^GameAssets,
	state: engine.PlayerAnimState,
	dir: engine.Direction,
) -> ^engine.AnimationClip {
	return &ga.player.clips[state][dir]
}

weapon_clip :: proc(
	ga: ^GameAssets,
	state: engine.WeaponAnimState,
	dir: engine.Direction,
) -> ^engine.AnimationClip {
	return &ga.weapon.clips[state][dir]
}

game_assets_init :: proc(ga: ^GameAssets, a: ^engine.Assets) {
	walk_spritesheet, walk_ok := engine.assets_load_texture(a, config.ASSET_PATHS.walk)
	if !walk_ok do panic("Failed to load walk texture")

	attack_spritesheet, attack_ok := engine.assets_load_texture(a, config.ASSET_PATHS.attack)
	if !attack_ok do panic("Failed to load attack texture")

	weapon_spritesheet, weapon_ok := engine.assets_load_texture(a, config.ASSET_PATHS.weapon)
	if !weapon_ok do panic("Failed to load weapon texture")

	walk_frames_per_direction := 4
	attack_frames_per_direction := 4
	sheet_columns := 4

	for dir in engine.Direction {
		column := engine.DIRECTION_SHEET_COLUMNS[dir]

		ga.player.clips[.Idle][dir] = engine.create_clip_from_sheet_column(
			walk_spritesheet,
			column,
			sheet_columns,
			walk_frames_per_direction,
			1,
			config.CONFIG.player.idle_frame_duration,
		)
		ga.player.clips[.Walk][dir] = engine.create_clip_from_sheet_column(
			walk_spritesheet,
			column,
			sheet_columns,
			walk_frames_per_direction,
			walk_frames_per_direction,
			config.CONFIG.player.walk_frame_duration,
		)
		ga.player.clips[.Attack][dir] = engine.create_clip_from_sheet_column(
			attack_spritesheet,
			column,
			sheet_columns,
			attack_frames_per_direction,
			attack_frames_per_direction,
			config.CONFIG.player.attack_frame_duration,
		)

		ga.weapon.clips[.Attacking][dir] = engine.create_clip_from_sheet_column(
			weapon_spritesheet,
			column,
			sheet_columns,
			attack_frames_per_direction,
			attack_frames_per_direction,
			config.CONFIG.player.attack_frame_duration,
		)

		ga.player.clips[.Attack][dir].loop = false
		// The swing plays once and holds its final frame; without this it would
		// loop back to the start frame for one tick before being hidden.
		ga.weapon.clips[.Attacking][dir].loop = false
		// Hidden uses an empty clip; playback and rendering are skipped.
		ga.weapon.clips[.Hidden][dir] = {}
	}
}

game_assets_destroy :: proc(ga: ^GameAssets) {
	for &state_clips in ga.player.clips {
		for &clip in state_clips {
			delete(clip.frames)
		}
	}
	for &state_clips in ga.weapon.clips {
		for &clip in state_clips {
			delete(clip.frames)
		}
	}
}

