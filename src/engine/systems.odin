package engine

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
	}
}

// Selects clips from gameplay state, then advances frames for each animated entity.
animation_system :: proc(w: ^World, a: ^Assets, dt: f32) {
	for entity, &state in w.animations.data {
		entity_update_animation_state(w, entity, &state)
		entity_advance_animation(w, a, entity, &state, dt)
	}
}

attack_system :: proc(w: ^World, a: ^Assets, dt: f32) {
	for entity, &attack in w.attack_state.data {
		attack.timer += dt

		state, ok := store_get(&w.animations, entity)
		if !ok {
			panic("Animation not found for player")
		}

		clip := assets_get_clip(a, .Attack, state.direction)
		if attack.timer >= f32(len(clip.frames)) * clip.duration {
			store_remove(&w.attack_state, entity)
		}
	}
}

