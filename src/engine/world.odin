package engine

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

