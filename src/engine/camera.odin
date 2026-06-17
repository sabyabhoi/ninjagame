package engine

import "../config"
import "vendor:raylib"

init_camera :: proc(camera: ^raylib.Camera2D) {
	camera.rotation = 0.0
	camera.zoom = config.CONFIG.render_scale

	camera.offset = {f32(config.CONFIG.window_width), f32(config.CONFIG.window_height)} / 2
}

update_camera :: proc(w: ^World, tilemap: ^Tilemap, camera: ^raylib.Camera2D) -> bool {
	for entity in w.player_controlled.data {
		sprite := store_get(&w.sprites, entity) or_return
		transform := store_get(&w.transforms, entity) or_return

		// Center on the current sprite frame (source rect), not the whole sheet.
		frame := raylib.Vector2{sprite.source.width, sprite.source.height}
		if frame.x == 0 {
			frame = {f32(sprite.texture.width), f32(sprite.texture.height)}
		}
		camera.target = transform.position + frame / 2

		// The visible world half-extent shrinks as zoom grows; work in native units.
		half_view := raylib.Vector2 {
			f32(config.CONFIG.window_width) / (2 * camera.zoom),
			f32(config.CONFIG.window_height) / (2 * camera.zoom),
		}
		upper_x := f32(tilemap.num_cols * tilemap.tile_width) - half_view.x
		upper_y := f32(tilemap.num_rows * tilemap.tile_height) - half_view.y

		camera.target.x = clamp(camera.target.x, half_view.x, upper_x)
		camera.target.y = clamp(camera.target.y, half_view.y, upper_y)
	}

	return true
}

