package main

import "config"
import "engine"
import "vendor:raylib"

// Creates the player entity with transform, velocity, sprite, animation, and input components.
spawn_player :: proc(
	w: ^engine.World,
	a: ^engine.Assets,
	position: raylib.Vector2,
) -> engine.Entity {
	player := engine.entity_create(w)
	engine.store_add(
		&w.transforms,
		player,
		engine.Transform {
			position = position,
			scale = {config.CONFIG.player_scale, config.CONFIG.player_scale},
		},
	)
	engine.store_add(&w.velocities, player, engine.Velocity{})
	engine.store_add(
		&w.sprites,
		player,
		engine.Sprite{texture = a.clips[.Idle].texture, tint = raylib.WHITE},
	)
	engine.store_add(&w.animations, player, engine.AnimationState{kind = .Idle})
	engine.store_add(&w.player_controlled, player, engine.PlayerControlled{})
	engine.animation_apply_initial_frame(w, a, player)
	return player
}

