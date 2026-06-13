package engine

import "../config"
import "core:slice"
import "vendor:raylib"

// Temporary render entry used to depth-sort sprites before drawing.
Drawable :: struct {
	entity: Entity, // Entity whose sprite should be drawn.
	sort_y: f32, // Y position used for back-to-front ordering.
}

// Advances each entity's position by its velocity scaled by the timestep.
physics_system :: proc(w: ^World, dt: f32) {
	for entity, &vel in w.velocities.data {
		t, ok := store_get(&w.transforms, entity)
		if !ok do continue
		t.position += vel.value * dt
	}
}

// Draws all sprites sorted back-to-front by their y position for depth ordering.
render_system :: proc(w: ^World) {
	drawables: [dynamic]Drawable
	defer delete(drawables)

	for entity in w.sprites.data {
		t, ok := store_get(&w.transforms, entity)
		if !ok do continue

		append(&drawables, Drawable{entity = entity, sort_y = t.position.y})
	}

	slice.stable_sort_by(drawables[:], proc(a, b: Drawable) -> bool {
		return a.sort_y < b.sort_y
	})

	for drawable in drawables {
		sprite, sprite_ok := store_get(&w.sprites, drawable.entity)
		t, transform_ok := store_get(&w.transforms, drawable.entity)
		if !sprite_ok || !transform_ok do continue

		src := sprite.source
		if src.width == 0 {
			src = {0, 0, f32(sprite.texture.width), f32(sprite.texture.height)}
		}

		dest := raylib.Rectangle {
			x      = t.position.x,
			y      = t.position.y,
			width  = src.width * t.scale.x,
			height = src.height * t.scale.y,
		}

		raylib.DrawTexturePro(sprite.texture, src, dest, {0, 0}, 0, sprite.tint)

		if overlay, overlay_ok := store_get(&w.weapon_overlays, drawable.entity);
		   overlay_ok && overlay.visible {
			overlay_src := overlay.sprite.source
			if overlay_src.width == 0 {
				overlay_src = {
					0,
					0,
					f32(overlay.sprite.texture.width),
					f32(overlay.sprite.texture.height),
				}
			}

			raylib.DrawTexturePro(
				overlay.sprite.texture,
				overlay_src,
				dest,
				{0, 0},
				0,
				overlay.sprite.tint,
			)
		}
	}
}

// Advances animation timers and applies the resulting frame to each animated sprite.
animation_system :: proc(w: ^World, a: ^Assets, dt: f32) {
	for entity, &state in w.animations.data {
		sprite, sprite_ok := store_get(&w.sprites, entity)
		if !sprite_ok do continue

		clip := assets_get_clip(a, state.kind)
		if len(clip.frames) == 0 do continue

		state.timer += dt
		for state.timer >= clip.duration {
			state.timer -= clip.duration
			state.frame_index = (state.frame_index + 1) % clip.frames_per_direction
		}

		animation_apply_sprite_frame(sprite, &state, clip)

		overlay, overlay_ok := store_get(&w.weapon_overlays, entity)
		weapon, weapon_ok := store_get(&w.weapons, entity)
		if !overlay_ok || !weapon_ok do continue

		overlay.visible = weapon_overlay_visible(&state)
		if overlay.visible {
			weapon_clip := assets_get_weapon_attack_clip(a, weapon.kind)
			if len(weapon_clip.frames) > 0 {
				animation_apply_sprite_frame(&overlay.sprite, &state, weapon_clip)
			}
		}
	}
}

attack_system :: proc(w: ^World, dt: f32) {
	for entity, &attack in w.attack_state.data {
		attack.timer += dt
		if attack.timer >= ATTACK_FRAMES_PER_DIRECTION * config.CONFIG.attack_frame_duration {
			state, ok := store_get(&w.animations, entity)
			if !ok {
				panic("Animation not found for player")
			}
			state.kind = .Idle
			state.frame_index = 0
			state.timer = 0
			store_remove(&w.attack_state, entity)
		}
	}
}

