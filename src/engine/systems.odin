package engine

import "../config"
import "core:slice"
import "vendor:raylib"

// Temporary render entry used to depth-sort sprites before drawing.
Drawable :: struct {
	entity: Entity, // Entity whose sprite should be drawn.
	sort_y: f32, // Y position used for back-to-front ordering.
}

// Computes the on-screen rectangle for a sprite source rect and transform scale.
sprite_dest_rect :: proc(t: ^Transform, src: raylib.Rectangle) -> raylib.Rectangle {
	return {
		x      = t.position.x,
		y      = t.position.y,
		width  = src.width * t.scale.x,
		height = src.height * t.scale.y,
	}
}

// Draws a sprite using its source sub-rect scaled by the entity transform.
draw_sprite :: proc(sprite: ^Sprite, t: ^Transform) {
	src := sprite.source
	if src.width == 0 {
		src = {0, 0, f32(sprite.texture.width), f32(sprite.texture.height)}
	}

	dest := sprite_dest_rect(t, src)
	raylib.DrawTexturePro(sprite.texture, src, dest, {0, 0}, 0, sprite.tint)
}

// Draws a weapon overlay frame into the same on-screen slot as the body sprite.
draw_weapon_overlay :: proc(overlay: ^WeaponOverlay, t: ^Transform, body_src: raylib.Rectangle) {
	if !overlay.visible do return
	if overlay.sprite.source.width <= 0 || overlay.sprite.source.height <= 0 do return

	dest := sprite_dest_rect(t, body_src)
	raylib.DrawTexturePro(
		overlay.sprite.texture,
		overlay.sprite.source,
		dest,
		{0, 0},
		0,
		overlay.sprite.tint,
	)
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

		body_src := sprite.source
		if body_src.width == 0 {
			body_src = {0, 0, f32(sprite.texture.width), f32(sprite.texture.height)}
		}

		draw_sprite(sprite, t)

		if overlay, overlay_ok := store_get(&w.weapon_overlays, drawable.entity); overlay_ok {
			draw_weapon_overlay(overlay, t, body_src)
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

		if weapon_overlay_visible(&state) {
			weapon_clip := assets_get_weapon_attack_clip(a, weapon.kind)
			if len(weapon_clip.frames) > 0 {
				overlay.visible = true
				animation_apply_sprite_frame(&overlay.sprite, &state, weapon_clip)
			}
		} else {
			overlay.visible = false
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

