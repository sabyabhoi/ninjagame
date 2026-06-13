package engine

// Identifies which weapon overlay an entity uses during attack.
WeaponKind :: enum {
	Katana,
	Shuriken,
	Kunai,
	Bow,
	Staff,
}

// Per-entity equipped weapon; only the kind is runtime state.
Weapon :: struct {
	kind: WeaponKind,
}

// Returns the shared character animation clip for idle, walk, or attack.
assets_get_clip :: proc(a: ^Assets, kind: AnimationKind) -> ^AnimationClip {
	return &a.clips[kind]
}

// Returns the attack overlay clip for a weapon kind.
assets_get_weapon_attack_clip :: proc(a: ^Assets, weapon: WeaponKind) -> ^AnimationClip {
	return &a.weapon_attack_clips[weapon]
}

// True when the weapon overlay should be drawn for the current attack frame.
weapon_overlay_visible :: proc(state: ^AnimationState) -> bool {
	return state.kind == .Attack &&
	       state.frame_index == ATTACK_FRAMES_PER_DIRECTION - 1
}

// Loads the attack overlay clip for one weapon from its sprite sheet.
assets_load_weapon_attack :: proc(
	a: ^Assets,
	weapon: WeaponKind,
	attack_path: string,
	attack_duration: f32,
) -> bool {
	attack_tex := assets_load_texture(a, attack_path) or_return

	assets_register_weapon_attack_clip(
		a,
		weapon,
		clip_from_directional_grid(
			attack_tex,
			PLAYER_DIRECTIONS,
			ATTACK_FRAMES_PER_DIRECTION,
			attack_duration,
		),
	)

	return true
}
