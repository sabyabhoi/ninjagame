package main

import "vendor:raylib"

Entity :: distinct u32
INVALID_ENTITY :: Entity(0)

World :: struct {
	next_id:    Entity,
	free_list:  [dynamic]Entity,

	// Components
	transforms: map[Entity]Transform,
	velocities: map[Entity]Velocity,
	sprites:    map[Entity]Sprite,
}

Transform :: struct {
	position: raylib.Vector2,
}

Velocity :: struct {
	value: raylib.Vector2,
}

Sprite :: struct {
	texture: raylib.Texture2D,
	source:  raylib.Rectangle,
	tint:    raylib.Color,
}

world_init :: proc(w: ^World) {
	w.next_id = 1
	w.free_list = make([dynamic]Entity)
	w.transforms = make(map[Entity]Transform)
	w.velocities = make(map[Entity]Velocity)
	w.sprites = make(map[Entity]Sprite)
}

world_destroy :: proc(w: ^World) {
	delete(w.free_list)
	delete(w.transforms)
	delete(w.velocities)
	delete(w.sprites)
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
	append(&w.free_list, e)
}

add_transform :: proc(w: ^World, e: Entity, t: Transform) {w.transforms[e] = t}
add_velocity :: proc(w: ^World, e: Entity, v: Velocity) {w.velocities[e] = v}
add_sprite :: proc(w: ^World, e: Entity, s: Sprite) {w.sprites[e] = s}

get_transform :: proc(w: ^World, e: Entity) -> ^Transform {return &w.transforms[e]}
get_velocity :: proc(w: ^World, e: Entity) -> ^Velocity {return &w.velocities[e]}
get_sprite :: proc(w: ^World, e: Entity) -> ^Sprite {return &w.sprites[e]}

has_transform :: proc(w: ^World, e: Entity) -> bool {return e in w.transforms}
has_velocity :: proc(w: ^World, e: Entity) -> bool {return e in w.velocities}
has_sprite :: proc(w: ^World, e: Entity) -> bool {return e in w.sprites}

// Systems

physics_system :: proc(w: ^World, dt: f32) {
	for entity, &vel in w.velocities {
		if t, ok := &w.transforms[entity]; ok {
			t.position += vel.value * dt
		}
	}
}

player_input_system :: proc(w: ^World, input: ^InputState, player: Entity) {
	vel, ok := &w.velocities[player]
	if !ok do return

	SPEED :: f32(300)
	vel.value = {0, 0}

	if .MoveLeft in input.held do vel.value.x -= SPEED
	if .MoveRight in input.held do vel.value.x += SPEED
	if .MoveUp in input.held do vel.value.y -= SPEED
	if .MoveDown in input.held do vel.value.y += SPEED
}

render_system :: proc(w: ^World) {
	for entity, &sprite in w.sprites {
		t, ok := w.transforms[entity]
		if !ok do continue

		src := sprite.source
		if src.width == 0 {
			src = {0, 0, f32(sprite.texture.width), f32(sprite.texture.height)}
		}

		dest := raylib.Rectangle {
			x      = t.position.x,
			y      = t.position.y,
			width  = src.width,
			height = src.height,
		}

		raylib.DrawTexturePro(sprite.texture, src, dest, {0, 0}, 0, sprite.tint)
	}
}

