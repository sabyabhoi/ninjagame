package main

import "vendor:raylib"

// Creates the player entity with transform, velocity, sprite, animation, and input components.
spawn_player :: proc(w: ^World, a: ^Assets, position: raylib.Vector2) -> Entity {
	player := entity_create(w)
	add_transform(
		w,
		player,
		Transform{position = position, scale = {CONFIG.player_scale, CONFIG.player_scale}},
	)
	add_velocity(w, player, Velocity{})
	add_sprite(w, player, Sprite{texture = a.clips[.Idle].texture, tint = raylib.WHITE})
	add_animation(w, player, AnimationState{kind = .Idle})
	add_player_controlled(w, player)
	animation_apply_initial_frame(w, a, player)
	return player
}

