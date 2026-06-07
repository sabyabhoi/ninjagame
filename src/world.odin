package main

import "core:slice"
import "vendor:raylib"

Entity :: distinct u32

World :: struct {
	next_id:   Entity,
	free_list: [dynamic]Entity,

	// Components
	transforms:        map[Entity]Transform,
	velocities:        map[Entity]Velocity,
	sprites:           map[Entity]Sprite,
	animations:        map[Entity]AnimationState,
	player_controlled: map[Entity]PlayerControlled,
}

Transform :: struct {
	position: raylib.Vector2,
	scale:    raylib.Vector2,
}

Velocity :: struct {
	value: raylib.Vector2,
}

Sprite :: struct {
	texture: raylib.Texture2D,
	source:  raylib.Rectangle,
	tint:    raylib.Color,
}

PlayerControlled :: struct {}

world_init :: proc(w: ^World) {
	w.next_id = 1
	w.free_list = make([dynamic]Entity)
	w.transforms = make(map[Entity]Transform)
	w.velocities = make(map[Entity]Velocity)
	w.sprites = make(map[Entity]Sprite)
	w.animations = make(map[Entity]AnimationState)
	w.player_controlled = make(map[Entity]PlayerControlled)
}

world_destroy :: proc(w: ^World) {
	delete(w.free_list)
	delete(w.transforms)
	delete(w.velocities)
	delete(w.sprites)
	delete(w.animations)
	delete(w.player_controlled)
}

entity_create :: proc(w: ^World) -> Entity {
	if len(w.free_list) > 0 {
		return pop(&w.free_list)
	}
	id := w.next_id
	w.next_id += 1
	return id
}

entity_destroy :: proc(w: ^World, e: Entity) {
	delete_key(&w.transforms, e)
	delete_key(&w.velocities, e)
	delete_key(&w.sprites, e)
	delete_key(&w.animations, e)
	delete_key(&w.player_controlled, e)
	append(&w.free_list, e)
}

add_transform :: proc(w: ^World, e: Entity, t: Transform) {w.transforms[e] = t}
add_velocity :: proc(w: ^World, e: Entity, v: Velocity) {w.velocities[e] = v}
add_sprite :: proc(w: ^World, e: Entity, s: Sprite) {w.sprites[e] = s}
add_animation :: proc(w: ^World, e: Entity, a: AnimationState) {w.animations[e] = a}
add_player_controlled :: proc(w: ^World, e: Entity) {w.player_controlled[e] = {}}

get_transform :: proc(w: ^World, e: Entity) -> (^Transform, bool) {
	if t, ok := &w.transforms[e]; ok {
		return t, true
	}
	return nil, false
}

get_velocity :: proc(w: ^World, e: Entity) -> (^Velocity, bool) {
	if v, ok := &w.velocities[e]; ok {
		return v, true
	}
	return nil, false
}

get_sprite :: proc(w: ^World, e: Entity) -> (^Sprite, bool) {
	if s, ok := &w.sprites[e]; ok {
		return s, true
	}
	return nil, false
}

get_animation :: proc(w: ^World, e: Entity) -> (^AnimationState, bool) {
	if a, ok := &w.animations[e]; ok {
		return a, true
	}
	return nil, false
}

// Systems

physics_system :: proc(w: ^World, dt: f32) {
	for entity, &vel in w.velocities {
		t, ok := get_transform(w, entity)
		if !ok do continue
		t.position += vel.value * dt
	}
}

player_input_system :: proc(w: ^World, input: ^InputState) {
	SPEED :: f32(300)

	for entity in w.player_controlled {
		vel, ok := get_velocity(w, entity)
		if !ok do continue

		vel.value = {0, 0}

		if .MoveLeft in input.held do vel.value.x -= SPEED
		if .MoveRight in input.held do vel.value.x += SPEED
		if .MoveUp in input.held do vel.value.y -= SPEED
		if .MoveDown in input.held do vel.value.y += SPEED
	}
}

Drawable :: struct {
	entity: Entity,
	sort_y: f32,
}

render_system :: proc(w: ^World) {
	drawables: [dynamic]Drawable
	defer delete(drawables)

	for entity in w.sprites {
		t, ok := get_transform(w, entity)
		if !ok do continue

		append(&drawables, Drawable{entity = entity, sort_y = t.position.y})
	}

	slice.stable_sort_by(drawables[:], proc(a, b: Drawable) -> bool {
		return a.sort_y < b.sort_y
	})

	for drawable in drawables {
		sprite, sprite_ok := get_sprite(w, drawable.entity)
		t, transform_ok := get_transform(w, drawable.entity)
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
