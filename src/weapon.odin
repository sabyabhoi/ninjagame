package main

import "engine"
import "vendor:raylib"

weapon_anim_system :: proc(w: ^engine.World, ga: ^GameAssets, dt: f32) {
	for owner, equip in w.equipped_weapon.data {
		weapon := equip.weapon_entity

		if ot, ok := engine.store_get(&w.transforms, owner); ok {
			if wt, ok2 := engine.store_get(&w.transforms, weapon); ok2 do wt^ = ot^
		}

		owner_sm, osm_ok := engine.store_get(&w.player_anim, owner)
		owner_facing, of_ok := engine.store_get(&w.facings, owner)
		wsm, wsm_ok := engine.store_get(&w.weapon_anim, weapon)
		wanim, wa_ok := engine.store_get(&w.animations, weapon)
		wsprite, sp_ok := engine.store_get(&w.sprites, weapon)
		if !osm_ok || !of_ok || !wsm_ok || !wa_ok || !sp_ok do continue

		next: engine.WeaponAnimState = .Hidden
		if owner_sm.current == .Attack do next = .Attacking

		engine.state_machine_transition(wsm, next)

		clip := weapon_clip(ga, wsm.current, owner_facing.direction)
		engine.animation_set_clip(wanim, clip)

		if wsm.current == .Attacking {
			wsprite.tint = raylib.WHITE
		} else {
			wsprite.tint = raylib.BLANK
		}

		engine.state_machine_tick(wsm, dt)
	}
}
