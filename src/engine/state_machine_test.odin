package engine

import "core:testing"

TestState :: enum {
	A,
	B,
}

@(test)
test_state_machine_init :: proc(t: ^testing.T) {
	sm: StateMachine(TestState)
	state_machine_init(&sm, TestState.A)

	testing.expect(t, sm.current == TestState.A, "expected initial state A")
	testing.expect(t, sm.previous == TestState.A, "expected previous equal to initial")
	testing.expect(t, sm.time_in_state == 0, "expected zero time in state")
}

@(test)
test_state_machine_transition :: proc(t: ^testing.T) {
	sm: StateMachine(TestState)
	state_machine_init(&sm, TestState.A)

	changed := state_machine_transition(&sm, TestState.B)
	testing.expect(t, changed, "expected transition to return true")
	testing.expect(t, sm.current == TestState.B, "expected current B")
	testing.expect(t, sm.previous == TestState.A, "expected previous A")
	testing.expect(t, sm.time_in_state == 0, "expected time reset on transition")

	unchanged := state_machine_transition(&sm, TestState.B)
	testing.expect(t, !unchanged, "expected same-state transition to return false")
}

@(test)
test_state_machine_tick :: proc(t: ^testing.T) {
	sm: StateMachine(TestState)
	state_machine_init(&sm, TestState.A)

	state_machine_tick(&sm, 0.5)
	testing.expect(t, sm.time_in_state == 0.5, "expected time to accumulate")

	state_machine_transition(&sm, TestState.B)
	testing.expect(t, sm.time_in_state == 0, "expected time reset after transition")
}

@(test)
test_state_machine_just_entered :: proc(t: ^testing.T) {
	sm: StateMachine(TestState)
	state_machine_init(&sm, TestState.A)

	testing.expect(t, !state_machine_just_entered(&sm), "expected false on init")

	state_machine_transition(&sm, TestState.B)
	testing.expect(t, state_machine_just_entered(&sm), "expected true after transition")
}
