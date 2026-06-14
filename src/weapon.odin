package main

import "engine"
import "vendor:raylib"

// Mirrors the owner's attack animation and follows their position.
weapon_sync_system :: proc(w: ^engine.World) {
	for owner, equip in w.equipped_weapon.data {
		weapon := equip.weapon_entity

		if ot, ok := engine.store_get(&w.transforms, owner); ok {
			if wt, ok2 := engine.store_get(&w.transforms, weapon); ok2 do wt^ = ot^
		}

		owner_state, os_ok := engine.store_get(&w.animations, owner)
		wstate, ws_ok := engine.store_get(&w.animations, weapon)
		wsprite, sp_ok := engine.store_get(&w.sprites, weapon)
		if !os_ok || !ws_ok || !sp_ok do continue

		if _, attacking := engine.store_get(&w.attack_state, owner); attacking {
			engine.animation_set_state(wstate, .AttackWeapon, owner_state.direction)
			wsprite.tint = raylib.WHITE
		} else {
			engine.animation_set_state(wstate, .None, owner_state.direction)
			wsprite.tint = raylib.BLANK
		}
	}
}
