package main

import "config"
import "engine"

player_input_system :: proc(w: ^engine.World, input: ^engine.InputState) {
	for entity in w.player_controlled.data {
		player_movement_input_system(w, entity, input)
	}
}

// Translates held movement actions into velocity for player-controlled entities.
player_movement_input_system :: proc(
	w: ^engine.World,
	entity: engine.Entity,
	input: ^engine.InputState,
) {
	vel, ok := engine.store_get(&w.velocities, entity)
	if !ok do return

	vel.value = {0, 0}

	if .MoveLeft in input.held do vel.value.x -= config.CONFIG.player.speed
	if .MoveRight in input.held do vel.value.x += config.CONFIG.player.speed
	if .MoveUp in input.held do vel.value.y -= config.CONFIG.player.speed
	if .MoveDown in input.held do vel.value.y += config.CONFIG.player.speed
}
