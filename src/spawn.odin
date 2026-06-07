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
	engine.add_transform(
		w,
		player,
		engine.Transform {
			position = position,
			scale = {config.CONFIG.player_scale, config.CONFIG.player_scale},
		},
	)
	engine.add_velocity(w, player, engine.Velocity{})
	engine.add_sprite(
		w,
		player,
		engine.Sprite{texture = a.clips[.Idle].texture, tint = raylib.WHITE},
	)
	engine.add_animation(w, player, engine.AnimationState{kind = .Idle})
	engine.add_player_controlled(w, player)
	engine.animation_apply_initial_frame(w, a, player)
	return player
}

