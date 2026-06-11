package engine

import "../config"
import "vendor:raylib"

update_camera :: proc(w: ^World, tilemap: ^Tilemap, camera: ^raylib.Camera2D) -> bool {
	camera.rotation = 0.0
	camera.zoom = 1.0

	for entity in w.player_controlled.data {
		sprite := store_get(&w.sprites, entity) or_return
		transform := store_get(&w.transforms, entity) or_return

		camera.target =
			transform.position + {f32(sprite.texture.width) / 2, f32(sprite.texture.height) / 2}
		camera.offset = {f32(config.CONFIG.window_width) / 2, f32(config.CONFIG.window_height) / 2}
	}

	return true
}

