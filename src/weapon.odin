package main

import "engine"
import "vendor:raylib"

weapon_anim_system :: proc(w: ^engine.World, ga: ^GameAssets, dt: f32) {
	for owner, equip in w.equipped_weapon.data {
		weapon := equip.weapon_entity

		if owner_transform, ok := engine.store_get(&w.transforms, owner); ok {
			if weapon_transform, ok2 := engine.store_get(&w.transforms, weapon); ok2 do weapon_transform^ = owner_transform^
		}

		owner_state_machine, osm_ok := engine.store_get(&w.player_anim, owner)
		owner_facing, of_ok := engine.store_get(&w.facings, owner)
		weapon_state_machine, wsm_ok := engine.store_get(&w.weapon_anim, weapon)
		weapon_anim, wa_ok := engine.store_get(&w.animations, weapon)
		weapon_sprite, sp_ok := engine.store_get(&w.sprites, weapon)
		if !osm_ok || !of_ok || !wsm_ok || !wa_ok || !sp_ok do continue

		next: engine.WeaponAnimState = .Hidden
		if owner_state_machine.current == .Attack do next = .Attacking

		engine.state_machine_transition(weapon_state_machine, next)

		clip := weapon_clip(ga, weapon_state_machine.current, owner_facing.direction)
		engine.animation_set_clip(weapon_anim, clip)

		if weapon_state_machine.current == .Attacking {
			weapon_sprite.tint = raylib.WHITE
		} else {
			weapon_sprite.tint = raylib.BLANK
		}

		engine.state_machine_tick(weapon_state_machine, dt)
	}
}

