package main

import "config"
import "core:math"
import "engine"

// Translates held movement actions into velocity for player-controlled entities.
player_input_system :: proc(w: ^engine.World, input: ^engine.InputState) {
	for entity in w.player_controlled.data {
		vel, ok := engine.store_get(&w.velocities, entity)
		if !ok do continue

		vel.value = {0, 0}

		if .MoveLeft in input.held do vel.value.x -= config.CONFIG.player_speed
		if .MoveRight in input.held do vel.value.x += config.CONFIG.player_speed
		if .MoveUp in input.held do vel.value.y -= config.CONFIG.player_speed
		if .MoveDown in input.held do vel.value.y += config.CONFIG.player_speed
	}
}

player_attack_system :: proc(w: ^engine.World, input: ^engine.InputState) {
	for entity in w.player_controlled.data {
		if .Attack in input.pressed {
			if _, already_attacking := engine.store_get(&w.attack_state, entity);
			   already_attacking {
				continue
			}

			engine.store_add(&w.attack_state, entity, engine.AttackState{timer = 0})

			animation_state, ok := engine.store_get(&w.animations, entity)
			if !ok do panic("Animation state not found for player")

			animation_state.kind = .Attack
			animation_state.frame_index = 0
			animation_state.timer = 0
		}
	}
}

// Chooses walk/idle animation kind and facing direction from the player's velocity.
player_movement_system :: proc(w: ^engine.World) {
	for entity in w.player_controlled.data {
		state, state_ok := engine.store_get(&w.animations, entity)
		if !state_ok do continue

		vel, vel_ok := engine.store_get(&w.velocities, entity)
		if !vel_ok do continue

		prev_kind := state.kind
		prev_direction := state.direction

		moving := vel.value.x != 0 || vel.value.y != 0
		if moving {
			if state.kind != .Attack {
				state.kind = .Walk
			}

			abs_x := math.abs(vel.value.x)
			abs_y := math.abs(vel.value.y)

			if abs_x >= abs_y {
				if vel.value.x < 0 {
					state.direction = engine.Direction.Left
				} else {
					state.direction = engine.Direction.Right
				}
			} else {
				if vel.value.y < 0 {
					state.direction = engine.Direction.Up
				} else {
					state.direction = engine.Direction.Down
				}
			}
		} else {
			if state.kind != .Attack {
				state.kind = .Idle
			}
		}

		if state.kind != prev_kind || state.direction != prev_direction {
			state.frame_index = 0
			state.timer = 0
		}
	}
}

