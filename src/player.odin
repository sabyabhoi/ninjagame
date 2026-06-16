package main

import "config"
import "engine"

player_input_system :: proc(w: ^engine.World, input: ^engine.InputState) {
	for entity in w.player_controlled.data {
		vel, ok := engine.store_get(&w.velocities, entity)
		if !ok do continue

		vel.value = {0, 0}

		if .MoveLeft in input.held do vel.value.x -= config.CONFIG.player.speed
		if .MoveRight in input.held do vel.value.x += config.CONFIG.player.speed
		if .MoveUp in input.held do vel.value.y -= config.CONFIG.player.speed
		if .MoveDown in input.held do vel.value.y += config.CONFIG.player.speed
	}
}

