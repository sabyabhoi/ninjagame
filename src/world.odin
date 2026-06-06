package main

Entity :: distinct u32
INVALID_ENTITY :: Entity(0)

World :: struct {
	next_id:   Entity,
	free_list: [dynamic]Entity,
}

world_init :: proc(w: ^World) {
	w.next_id = 1
	w.free_list = make([dynamic]Entity)
}

world_destroy :: proc(w: ^World) {
	delete(w.free_list)
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
	append(&w.free_list, e)
}

