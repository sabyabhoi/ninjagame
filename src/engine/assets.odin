package engine

import "core:fmt"
import "core:strings"
import "vendor:raylib"

// Central store for loaded textures and registered animation clips.
Assets :: struct {
	textures:     map[string]raylib.Texture2D, // Path-keyed cache of loaded GPU textures.
	entity_clips: [AnimationKind][Direction]AnimationClip, // One clip per kind and facing.
}

// Initializes the asset store's texture cache.
assets_init :: proc(a: ^Assets) {
	a.textures = make(map[string]raylib.Texture2D)
}

// Frees clip frame data and unloads every cached GPU texture.
assets_destroy :: proc(a: ^Assets) {
	for &kind_clips in a.entity_clips {
		for &clip in kind_clips {
			delete(clip.frames)
		}
	}

	for _, tex in a.textures {
		raylib.UnloadTexture(tex)
	}
	delete(a.textures)
}

// Loads a texture from disk, returning a cached copy when already loaded.
assets_load_texture :: proc(a: ^Assets, path: string) -> (raylib.Texture2D, bool) {
	if tex, ok := a.textures[path]; ok {
		return tex, true
	}

	tex := raylib.LoadTexture(strings.clone_to_cstring(path, context.temp_allocator))
	if tex.id == 0 {
		fmt.eprintf("Failed to load texture: %s\n", path)
		return {}, false
	}

	a.textures[path] = tex
	return tex, true
}

// Returns the animation clip for the given kind and facing direction.
assets_get_clip :: proc(a: ^Assets, kind: AnimationKind, dir: Direction) -> ^AnimationClip {
	return &a.entity_clips[kind][dir]
}

// Stores an animation clip under the given kind and direction, freeing any clip it replaces.
assets_register_clip :: proc(
	a: ^Assets,
	kind: AnimationKind,
	dir: Direction,
	clip: AnimationClip,
) {
	if existing := a.entity_clips[kind][dir]; len(existing.frames) > 0 {
		fmt.println(
			"[WARN] Frames already exist for this animation kind and direction. Overwritting...",
		)
		fmt.println(kind, dir)
		delete(existing.frames)
	}
	a.entity_clips[kind][dir] = clip
}

