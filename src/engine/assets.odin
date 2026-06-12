package engine

import "core:fmt"
import "core:strings"
import "vendor:raylib"

// Central store for loaded textures and registered animation clips.
Assets :: struct {
	textures: map[string]raylib.Texture2D, // Path-keyed cache of loaded GPU textures.
	clips:    [AnimationKind]AnimationClip, // One clip per animation kind (idle, walk, etc.).
}

// Initializes the asset store's texture cache.
assets_init :: proc(a: ^Assets) {
	a.textures = make(map[string]raylib.Texture2D)
}

// Frees clip frame data and unloads every cached GPU texture.
assets_destroy :: proc(a: ^Assets) {
	for &clip in a.clips {
		delete(clip.frames)
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

// Stores an animation clip under the given kind, freeing any clip it replaces.
assets_register_clip :: proc(a: ^Assets, kind: AnimationKind, clip: AnimationClip) {
	if existing := a.clips[kind]; len(existing.frames) > 0 {
		fmt.println("[WARN] Frames already exist for this animation kind. Overwritting...")
		fmt.println(kind)
		delete(existing.frames)
	}
	a.clips[kind] = clip
}

