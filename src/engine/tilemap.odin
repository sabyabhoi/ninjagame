package engine

import "core:encoding/csv"
import "core:encoding/xml"
import "core:fmt"
import "core:path/filepath"
import "core:strconv"
import "core:strings"
import "vendor:raylib"

Tilemap :: struct {
	num_cols:    u64,
	num_rows:    u64,
	tile_width:  u64,
	tile_height: u64,
	data:        [][]u64,
	tileset:     Tileset,
	transform:   Transform,
}

Tileset :: struct {
	texture:     raylib.Texture2D,
	tile_width:  u64,
	tile_height: u64,
	tile_count:  u64,
	columns:     u64,
}

render_tilemap :: proc(tilemap: ^Tilemap) {
	for row in 0 ..< tilemap.num_rows {
		for col in 0 ..< tilemap.num_cols {
			src_rect := get_tile_rect_from_index(&tilemap.tileset, tilemap.data[row][col])
			dest_rect := raylib.Rectangle {
				x      = f32(col * tilemap.tile_width) * tilemap.transform.scale.x,
				y      = f32(row * tilemap.tile_height) * tilemap.transform.scale.y,
				width  = f32(tilemap.tile_width) * tilemap.transform.scale.x,
				height = f32(tilemap.tile_height) * tilemap.transform.scale.y,
			}
			raylib.DrawTexturePro(
				tilemap.tileset.texture,
				src_rect,
				dest_rect,
				{0, 0},
				0,
				raylib.WHITE,
			)
		}
	}
}

resolve_relative :: proc(base_path, filename: string) -> string {
	dir := filepath.dir(base_path) // "res/map"
	s, err := filepath.join({dir, filename}) // "res/map/TilesetFloor.tsx"
	if err != .None {
		fmt.eprintln("Failed to resolve filepaths")
		return ""
	}
	return s
}

get_tile_rect :: proc {
	get_tile_rect_from_index,
	get_tile_rect_from_row_cols,
}

get_tile_rect_from_index :: proc(tileset: ^Tileset, index: u64) -> raylib.Rectangle {
	row := index / tileset.columns
	col := index - row * tileset.columns
	return get_tile_rect_from_row_cols(tileset, row, col)
}

get_tile_rect_from_row_cols :: proc(tileset: ^Tileset, row, col: u64) -> raylib.Rectangle {
	return raylib.Rectangle {
		x = f32(tileset.tile_width * col),
		y = f32(tileset.tile_height * row),
		width = f32(tileset.tile_width),
		height = f32(tileset.tile_height),
	}
}

fetch_attribute_u64 :: proc(doc: ^xml.Document, element_id: u32, key: string) -> (u64, bool) {
	value, found := xml.find_attribute_val_by_key(doc, element_id, key)
	if !found {
		return 0, false
	}

	return strconv.parse_u64(value)
}

load_tileset :: proc(a: ^Assets, tileset: ^Tileset, filepath: string) -> bool {
	doc, err := xml.load_from_file(filepath)
	if err != .None {
		fmt.eprintln("Failed to parse tileset XML:", err)
		return false
	}
	defer xml.destroy(doc)

	tileset.tile_width = fetch_attribute_u64(doc, 0, "tilewidth") or_return
	tileset.tile_height = fetch_attribute_u64(doc, 0, "tileheight") or_return
	tileset.tile_count = fetch_attribute_u64(doc, 0, "tilecount") or_return
	tileset.columns = fetch_attribute_u64(doc, 0, "columns") or_return

	image_id := xml.find_child_by_ident(doc, 0, "image") or_return
	image_source := xml.find_attribute_val_by_key(doc, image_id, "source") or_return

	tileset.texture = assets_load_texture(a, strings.concatenate({"res/", image_source})) or_return

	return true
}

parse_csv :: proc(raw_data: string, rows, cols: u64) -> (result_arr: [][]u64, ok: bool) {
	result := make([][]u64, rows)
	defer if !ok {
		for row in result {
			delete(row)
		}
		delete(result)
		result = nil
	}

	for i in 0 ..< rows {
		result[i] = make([]u64, cols)
	}

	r: csv.Reader
	r.trim_leading_space = true
	r.reuse_record = true
	r.reuse_record_buffer = true
	// Tiled writes a trailing comma on each row (and the final row has none), so the
	// field count per record varies. Disable the check and validate columns ourselves.
	r.fields_per_record = -1
	defer csv.reader_destroy(&r)

	csv.reader_init_with_string(&r, raw_data)

	row_idx := 0
	for record in csv.iterator_next(&r) {
		if u64(row_idx) >= rows {
			fmt.eprintfln("Warning: More rows than expected (%d)", rows)
			break
		}

		col_idx := 0
		for field in record {
			// Skip empty fields, e.g. the one produced by Tiled's trailing comma.
			if strings.trim_space(field) == "" {
				continue
			}

			if u64(col_idx) >= cols {
				fmt.eprintfln("Row %d has more columns than expected (%d)", row_idx, cols)
				return nil, false
			}

			value, ok := strconv.parse_u64(field)
			if !ok {
				fmt.eprintfln("Failed to convert at [%d,%d]: %q", row_idx, col_idx, field)
				return nil, false
			}
			result[row_idx][col_idx] = value
			col_idx += 1
		}

		if u64(col_idx) != cols {
			fmt.eprintfln("Row %d has %d columns, expected %d", row_idx, col_idx, cols)
			return nil, false
		}
		row_idx += 1
	}

	// iterator_next stops on the first error (including EOF) by returning more=false.
	// Anything other than EOF is a genuine parse failure we should report.
	if err := csv.iterator_last_error(r); err != nil && !csv.is_io_error(err, .EOF) {
		fmt.eprintfln("CSV parse error: %v", err)
		return nil, false
	}

	if u64(row_idx) != rows {
		fmt.eprintfln("Parsed %d rows, expected %d", row_idx, rows)
		return nil, false
	}

	return result, true
}

load_world :: proc(a: ^Assets, tilemap: ^Tilemap, filepath: string) -> bool {
	doc, err := xml.load_from_file(filepath)
	if err != .None {
		fmt.eprintln("Failed to parse tilemap XML:", err)
		return false
	}
	defer xml.destroy(doc)

	tilemap.num_cols = fetch_attribute_u64(doc, 0, "width") or_return
	tilemap.num_rows = fetch_attribute_u64(doc, 0, "height") or_return
	tilemap.tile_width = fetch_attribute_u64(doc, 0, "tilewidth") or_return
	tilemap.tile_height = fetch_attribute_u64(doc, 0, "tileheight") or_return
	tilemap.transform.position = {0, 0}
	tilemap.transform.scale = {4.0, 4.0}

	tileset_id := xml.find_child_by_ident(doc, 0, "tileset") or_return

	tileset_filepath := xml.find_attribute_val_by_key(doc, tileset_id, "source") or_return

	tileset: Tileset
	load_tileset(a, &tileset, resolve_relative(filepath, tileset_filepath)) or_return

	tilemap.tileset = tileset

	layer_id := xml.find_child_by_ident(doc, 0, "layer") or_return
	data_id := xml.find_child_by_ident(doc, layer_id, "data") or_return

	raw_csv_data := doc.elements[data_id].value
	switch value in raw_csv_data[0] {
	case string:
		tilemap.data = parse_csv(value, tilemap.num_rows, tilemap.num_cols) or_return
	case u32:
		panic("Expected string")
	}

	return true
}

