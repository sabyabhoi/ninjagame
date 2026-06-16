package main

import "engine"

player_anim_system :: proc(
	w: ^engine.World,
	ga: ^GameAssets,
	input: ^engine.InputState,
	dt: f32,
) {
	for entity, &sm in w.player_anim.data {
		anim, anim_ok := engine.store_get(&w.animations, entity)
		facing, facing_ok := engine.store_get(&w.facings, entity)
		if !anim_ok || !facing_ok do continue

		vel, vel_ok := engine.store_get(&w.velocities, entity)

		switch sm.current {
		case .Idle:
			if .Attack in input.pressed {
				engine.state_machine_transition(&sm, engine.PlayerAnimState.Attack)
			} else if vel_ok && engine.is_moving(vel) {
				engine.update_entity_facing(vel, facing)
				engine.state_machine_transition(&sm, engine.PlayerAnimState.Walk)
			}

		case .Walk:
			if .Attack in input.pressed {
				engine.state_machine_transition(&sm, engine.PlayerAnimState.Attack)
			} else if !vel_ok || !engine.is_moving(vel) {
				engine.state_machine_transition(&sm, engine.PlayerAnimState.Idle)
			} else {
				engine.update_entity_facing(vel, facing)
			}

		case .Attack:
			clip := player_clip(ga, sm.current, facing.direction)
			if sm.time_in_state >= f32(len(clip.frames)) * clip.duration {
				next := engine.PlayerAnimState.Idle
				if vel_ok && engine.is_moving(vel) do next = engine.PlayerAnimState.Walk
				engine.state_machine_transition(&sm, next)
			}
		}

		clip := player_clip(ga, sm.current, facing.direction)
		engine.animation_set_clip(anim, clip)
		engine.state_machine_tick(&sm, dt)
	}
}
