package main

import "core:strings"
import "vendor:raylib"

Assets :: struct {
	textures: map[string]raylib.Texture2D,
}

assets_init :: proc(a: ^Assets) {
	a.textures = make(map[string]raylib.Texture2D)
}

assets_destroy :: proc(a: ^Assets) {
	for _, tex in a.textures {
		raylib.UnloadTexture(tex)
	}
	delete(a.textures)
}

assets_load_texture :: proc(a: ^Assets, path: string) -> raylib.Texture2D {
	if tex, ok := a.textures[path]; ok {
		return tex
	}

	tex := raylib.LoadTexture(strings.clone_to_cstring(path))
	a.textures[path] = tex

	return tex
}

