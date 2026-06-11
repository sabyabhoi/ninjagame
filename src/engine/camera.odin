package engine

import "../config"
import "vendor:raylib"

init_camera :: proc(camera: ^raylib.Camera2D) {
	camera.rotation = 0.0
	camera.zoom = 1.0

	camera.offset = {f32(config.CONFIG.window_width), f32(config.CONFIG.window_height)} / 2
}

update_camera :: proc(w: ^World, tilemap: ^Tilemap, camera: ^raylib.Camera2D) -> bool {
	for entity in w.player_controlled.data {
		sprite := store_get(&w.sprites, entity) or_return
		transform := store_get(&w.transforms, entity) or_return

		camera.target =
			transform.position + {f32(sprite.texture.width), f32(sprite.texture.height)} / 2

		upper_x :=
			f32(tilemap.num_cols * tilemap.tile_width) * tilemap.transform.scale.x -
			f32(config.CONFIG.window_width) / 2
		upper_y :=
			f32(tilemap.num_rows * tilemap.tile_height) * tilemap.transform.scale.y -
			f32(config.CONFIG.window_height) / 2

		camera.target.x = clamp(camera.target.x, camera.offset.x, upper_x)
		camera.target.y = clamp(camera.target.y, camera.offset.y, upper_y)
	}

	return true
}

