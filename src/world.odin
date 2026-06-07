package main

import "core:slice"
import "vendor:raylib"

// Opaque handle that identifies a single game object in the world.
Entity :: distinct u32

// ECS container holding entity ids and their component maps.
World :: struct {
	next_id:           Entity, // Next id to assign when the free list is empty.
	free_list:         [dynamic]Entity, // Ids recycled by destroyed entities.

	// Components
	transforms:        map[Entity]Transform, // World position and draw scale per entity.
	velocities:        map[Entity]Velocity, // Movement speed in pixels per second.
	sprites:           map[Entity]Sprite, // Texture and source rect used for rendering.
	animations:        map[Entity]AnimationState, // Current clip, frame, and playback timer.
	player_controlled: map[Entity]PlayerControlled, // Entities driven by keyboard input.
}

// Spatial placement and size multiplier for an entity on screen.
Transform :: struct {
	position: raylib.Vector2, // Top-left corner in screen space.
	scale:    raylib.Vector2, // Multiplier applied to the sprite source rect.
}

// Per-frame movement vector for physics integration.
Velocity :: struct {
	value: raylib.Vector2, // Pixels per second along each axis.
}

// Drawable appearance pulled from a texture atlas region.
Sprite :: struct {
	texture: raylib.Texture2D, // GPU texture backing this sprite.
	source:  raylib.Rectangle, // Sub-rectangle within the texture; full texture when zero-sized.
	tint:    raylib.Color, // Color multiplier applied at draw time.
}

// Marker component: entity receives player input each tick.
PlayerControlled :: struct {}

// Allocates and initializes all component maps and bookkeeping for a fresh world.
world_init :: proc(w: ^World) {
	w.next_id = 1
	w.free_list = make([dynamic]Entity)
	w.transforms = make(map[Entity]Transform)
	w.velocities = make(map[Entity]Velocity)
	w.sprites = make(map[Entity]Sprite)
	w.animations = make(map[Entity]AnimationState)
	w.player_controlled = make(map[Entity]PlayerControlled)
}

// Frees all component maps and bookkeeping owned by the world.
world_destroy :: proc(w: ^World) {
	delete(w.free_list)
	delete(w.transforms)
	delete(w.velocities)
	delete(w.sprites)
	delete(w.animations)
	delete(w.player_controlled)
}

// Returns a new entity id, reusing a freed id when one is available.
entity_create :: proc(w: ^World) -> Entity {
	if len(w.free_list) > 0 {
		return pop(&w.free_list)
	}
	id := w.next_id
	w.next_id += 1
	return id
}

// Removes all components for an entity and recycles its id onto the free list.
entity_destroy :: proc(w: ^World, e: Entity) {
	delete_key(&w.transforms, e)
	delete_key(&w.velocities, e)
	delete_key(&w.sprites, e)
	delete_key(&w.animations, e)
	delete_key(&w.player_controlled, e)
	append(&w.free_list, e)
}

// Attaches (or replaces) the transform component on an entity.
add_transform :: proc(w: ^World, e: Entity, t: Transform) {w.transforms[e] = t}
// Attaches (or replaces) the velocity component on an entity.
add_velocity :: proc(w: ^World, e: Entity, v: Velocity) {w.velocities[e] = v}
// Attaches (or replaces) the sprite component on an entity.
add_sprite :: proc(w: ^World, e: Entity, s: Sprite) {w.sprites[e] = s}
// Attaches (or replaces) the animation state component on an entity.
add_animation :: proc(w: ^World, e: Entity, a: AnimationState) {w.animations[e] = a}
// Tags an entity as player-controlled so input drives its movement.
add_player_controlled :: proc(w: ^World, e: Entity) {w.player_controlled[e] = {}}

// Returns a pointer to the entity's transform, or false if it has none.
get_transform :: proc(w: ^World, e: Entity) -> (^Transform, bool) {
	if t, ok := &w.transforms[e]; ok {
		return t, true
	}
	return nil, false
}

// Returns a pointer to the entity's velocity, or false if it has none.
get_velocity :: proc(w: ^World, e: Entity) -> (^Velocity, bool) {
	if v, ok := &w.velocities[e]; ok {
		return v, true
	}
	return nil, false
}

// Returns a pointer to the entity's sprite, or false if it has none.
get_sprite :: proc(w: ^World, e: Entity) -> (^Sprite, bool) {
	if s, ok := &w.sprites[e]; ok {
		return s, true
	}
	return nil, false
}

// Returns a pointer to the entity's animation state, or false if it has none.
get_animation :: proc(w: ^World, e: Entity) -> (^AnimationState, bool) {
	if a, ok := &w.animations[e]; ok {
		return a, true
	}
	return nil, false
}

// Systems

// Advances each entity's position by its velocity scaled by the timestep.
physics_system :: proc(w: ^World, dt: f32) {
	for entity, &vel in w.velocities {
		t, ok := get_transform(w, entity)
		if !ok do continue
		t.position += vel.value * dt
	}
}

// Translates held movement actions into velocity for player-controlled entities.
player_input_system :: proc(w: ^World, input: ^InputState) {
	for entity in w.player_controlled {
		vel, ok := get_velocity(w, entity)
		if !ok do continue

		vel.value = {0, 0}

		if .MoveLeft in input.held do vel.value.x -= CONFIG.player_speed
		if .MoveRight in input.held do vel.value.x += CONFIG.player_speed
		if .MoveUp in input.held do vel.value.y -= CONFIG.player_speed
		if .MoveDown in input.held do vel.value.y += CONFIG.player_speed
	}
}

// Temporary render entry used to depth-sort sprites before drawing.
Drawable :: struct {
	entity: Entity, // Entity whose sprite should be drawn.
	sort_y: f32, // Y position used for back-to-front ordering.
}

// Draws all sprites sorted back-to-front by their y position for depth ordering.
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

