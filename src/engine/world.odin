package engine

// Opaque handle that identifies a single game object in the world.
Entity :: distinct u32

// ECS container holding entity ids and their component maps.
World :: struct {
	next_id:           Entity, // Next id to assign when the free list is empty.
	free_list:         [dynamic]Entity, // Ids recycled by destroyed entities.

	// Components
	transforms:        ComponentStore(Transform), // World position and draw scale per entity.
	velocities:        ComponentStore(Velocity), // Movement speed in pixels per second.
	sprites:           ComponentStore(Sprite), // Texture and source rect used for rendering.
	animations:        ComponentStore(AnimationState), // Current clip, frame, and playback timer.
	facings:           ComponentStore(Facing), // Logical facing for directional sprites.
	player_controlled: ComponentStore(PlayerControlled), // Entities driven by keyboard input.
	player_anim:       ComponentStore(StateMachine(PlayerAnimState)), // Player animation FSM.
	weapon_anim:       ComponentStore(StateMachine(WeaponAnimState)), // Weapon animation FSM.
	equipped_weapon:   ComponentStore(EquippedWeapon),
}

// Allocates and initializes all component maps and bookkeeping for a fresh world.
world_init :: proc(w: ^World) {
	w.next_id = 1
	w.free_list = make([dynamic]Entity)
	store_init(&w.transforms)
	store_init(&w.velocities)
	store_init(&w.sprites)
	store_init(&w.animations)
	store_init(&w.facings)
	store_init(&w.player_controlled)
	store_init(&w.player_anim)
	store_init(&w.weapon_anim)
	store_init(&w.equipped_weapon)
}

// Frees all component maps and bookkeeping owned by the world.
world_destroy :: proc(w: ^World) {
	delete(w.free_list)
	store_destroy(&w.transforms)
	store_destroy(&w.velocities)
	store_destroy(&w.sprites)
	store_destroy(&w.animations)
	store_destroy(&w.facings)
	store_destroy(&w.player_controlled)
	store_destroy(&w.player_anim)
	store_destroy(&w.weapon_anim)
	store_destroy(&w.equipped_weapon)
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
	store_remove(&w.transforms, e)
	store_remove(&w.velocities, e)
	store_remove(&w.sprites, e)
	store_remove(&w.animations, e)
	store_remove(&w.facings, e)
	store_remove(&w.player_controlled, e)
	store_remove(&w.player_anim, e)
	store_remove(&w.weapon_anim, e)
	store_remove(&w.equipped_weapon, e)
	append(&w.free_list, e)
}
