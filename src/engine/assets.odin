package engine

import "core:fmt"
import "core:strings"
import "vendor:raylib"

// Central store for loaded textures from disk.
Assets :: struct {
	textures: map[string]raylib.Texture2D, // Path-keyed cache of loaded GPU textures.
}

// Initializes the asset store's texture cache.
assets_init :: proc(a: ^Assets) {
	a.textures = make(map[string]raylib.Texture2D)
}

// Unloads every cached GPU texture.
assets_destroy :: proc(a: ^Assets) {
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
