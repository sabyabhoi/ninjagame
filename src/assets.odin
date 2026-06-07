package main

import "core:strings"
import "vendor:raylib"

Assets :: struct {
	textures: map[string]raylib.Texture2D,
	clips:    map[string]AnimationClip,
}

assets_init :: proc(a: ^Assets) {
	a.textures = make(map[string]raylib.Texture2D)
	a.clips = make(map[string]AnimationClip)
}

assets_destroy :: proc(a: ^Assets) {
	for _, clip in a.clips {
		delete(clip.frames)
	}
	delete(a.clips)

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

assets_register_clip :: proc(a: ^Assets, name: string, clip: AnimationClip) {
	if existing, ok := a.clips[name]; ok {
		delete(existing.frames)
	}
	a.clips[name] = clip
}

assets_get_clip :: proc(a: ^Assets, name: string) -> ^AnimationClip {
	if clip, ok := &a.clips[name]; ok {
		return clip
	}
	return nil
}
