package main

import "engine"

player_anim_system :: proc(
	w: ^engine.World,
	game_assets: ^GameAssets,
	input: ^engine.InputState,
	dt: f32,
) {
	for entity, &state_machine in w.player_anim.data {
		anim_state, anim_ok := engine.store_get(&w.animations, entity)
		facing, facing_ok := engine.store_get(&w.facings, entity)
		if !anim_ok || !facing_ok do continue

		velocity, vel_ok := engine.store_get(&w.velocities, entity)

		switch state_machine.current {
		case .Idle:
			if .Attack in input.pressed {
				engine.state_machine_transition(&state_machine, engine.PlayerAnimState.Attack)
			} else if vel_ok && engine.is_moving(velocity) {
				engine.update_entity_facing(velocity, facing)
				engine.state_machine_transition(&state_machine, engine.PlayerAnimState.Walk)
			}

		case .Walk:
			if .Attack in input.pressed {
				engine.state_machine_transition(&state_machine, engine.PlayerAnimState.Attack)
			} else if !vel_ok || !engine.is_moving(velocity) {
				engine.state_machine_transition(&state_machine, engine.PlayerAnimState.Idle)
			} else {
				engine.update_entity_facing(velocity, facing)
			}

		case .Attack:
			clip := player_clip(game_assets, state_machine.current, facing.direction)
			if state_machine.time_in_state >= f32(len(clip.frames)) * clip.frame_duration {
				next: engine.PlayerAnimState

				if vel_ok && engine.is_moving(velocity) do next = engine.PlayerAnimState.Walk
				else do next = engine.PlayerAnimState.Idle

				engine.state_machine_transition(&state_machine, next)
			}
		}

		clip := player_clip(game_assets, state_machine.current, facing.direction)
		engine.animation_set_clip(anim_state, clip)
		engine.state_machine_tick(&state_machine, dt)
	}
}

