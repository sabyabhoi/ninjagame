package main

import "core:fmt"
import "core:strings"
import "vendor:raylib"

Assets :: struct {
	textures: map[string]raylib.Texture2D,
	clips:    [AnimationKind]AnimationClip,
}

assets_init :: proc(a: ^Assets) {
	a.textures = make(map[string]raylib.Texture2D)
}

assets_destroy :: proc(a: ^Assets) {
	for &clip in a.clips {
		delete(clip.frames)
	}

	for _, tex in a.textures {
		raylib.UnloadTexture(tex)
	}
	delete(a.textures)
}

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

assets_register_clip :: proc(a: ^Assets, kind: AnimationKind, clip: AnimationClip) {
	if existing := a.clips[kind]; len(existing.frames) > 0 {
		delete(existing.frames)
	}
	a.clips[kind] = clip
}

