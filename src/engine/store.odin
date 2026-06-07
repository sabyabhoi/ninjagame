package engine

ComponentStore :: struct($T: typeid) {
	data: map[Entity]T,
}

store_init :: proc(s: ^ComponentStore($T)) {
	s.data = make(map[Entity]T)
}

store_destroy :: proc(s: ^ComponentStore($T)) {
	delete(s.data)
}

store_add :: proc(s: ^ComponentStore($T), e: Entity, v: T) {
	s.data[e] = v
}

store_remove :: proc(s: ^ComponentStore($T), e: Entity) {
	delete_key(&s.data, e)
}

store_get :: proc(s: ^ComponentStore($T), e: Entity) -> (^T, bool) {
	v, ok := &s.data[e]
	return v, ok
}
