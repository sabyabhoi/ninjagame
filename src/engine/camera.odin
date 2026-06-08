package engine

import "vendor:raylib"

update_camera :: proc(w: ^World, tilemap: ^Tilemap, camera: ^raylib.Camera2D) -> bool {
	camera.rotation = 0.0
	camera.zoom = 1.0

	for entity in w.player_controlled.data {
		sprite := store_get(&w.sprites, entity) or_return

		transform := store_get(&w.transforms, entity) or_return
	}

	return true
}

