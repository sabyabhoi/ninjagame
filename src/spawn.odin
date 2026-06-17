package main

import "engine"
import "vendor:raylib"

// Creates the player entity with transform, velocity, sprite, animation, and input components.
spawn_player :: proc(
	w: ^engine.World,
	ga: ^GameAssets,
	position: raylib.Vector2,
) -> engine.Entity {
	player := engine.entity_create(w)
	player_transform := engine.Transform {
		position = position,
	}

	idle_clip := player_clip(ga, .Idle, .Down)

	engine.store_add(&w.transforms, player, player_transform)
	engine.store_add(&w.velocities, player, engine.Velocity{})
	engine.store_add(
		&w.sprites,
		player,
		engine.Sprite{texture = idle_clip.texture, tint = raylib.WHITE},
	)
	engine.store_add(&w.facings, player, engine.Facing{direction = .Down})

	player_sm: engine.StateMachine(engine.PlayerAnimState)
	engine.state_machine_init(&player_sm, engine.PlayerAnimState.Idle)
	engine.store_add(&w.player_anim, player, player_sm)

	engine.store_add(
		&w.animations,
		player,
		engine.AnimationState{clip = idle_clip},
	)
	engine.store_add(&w.player_controlled, player, engine.PlayerControlled{})

	weapon_entity := spawn_weapon(w, ga, &player_transform)
	engine.store_add(
		&w.equipped_weapon,
		player,
		engine.EquippedWeapon{weapon_entity = weapon_entity},
	)

	engine.animation_apply_initial_frame(w, player)
	return player
}

spawn_weapon :: proc(
	w: ^engine.World,
	ga: ^GameAssets,
	transform: ^engine.Transform,
) -> engine.Entity {
	weapon := engine.entity_create(w)
	hidden_clip := weapon_clip(ga, .Hidden, .Down)

	engine.store_add(&w.transforms, weapon, transform^)

	weapon_sm: engine.StateMachine(engine.WeaponAnimState)
	engine.state_machine_init(&weapon_sm, engine.WeaponAnimState.Hidden)
	engine.store_add(&w.weapon_anim, weapon, weapon_sm)

	engine.store_add(
		&w.animations,
		weapon,
		engine.AnimationState{clip = hidden_clip},
	)
	engine.store_add(&w.sprites, weapon, engine.Sprite{tint = raylib.BLANK})
	return weapon
}
