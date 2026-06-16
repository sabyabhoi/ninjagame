package engine

// Per-entity finite state machine with typed state enum.
StateMachine :: struct($S: typeid) {
	current:       S,
	previous:      S,
	time_in_state: f32,
}

state_machine_init :: proc(sm: ^StateMachine($S), initial: S) {
	sm.current = initial
	sm.previous = initial
	sm.time_in_state = 0
}

// Switches to next when different; resets time_in_state and returns whether state changed.
state_machine_transition :: proc(sm: ^StateMachine($S), next: S) -> bool {
	if sm.current == next do return false
	sm.previous = sm.current
	sm.current = next
	sm.time_in_state = 0
	return true
}

state_machine_tick :: proc(sm: ^StateMachine($S), dt: f32) {
	sm.time_in_state += dt
}

state_machine_just_entered :: proc(sm: ^StateMachine($S)) -> bool {
	return sm.current != sm.previous
}
