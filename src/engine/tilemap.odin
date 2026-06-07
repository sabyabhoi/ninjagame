package engine

import "core:encoding/csv"
import "core:encoding/xml"
import "core:fmt"
import "core:path/filepath"
import "core:strconv"
import "core:strings"
import "vendor:raylib"

Tilemap :: struct {
	map_width:   u64,
	map_height:  u64,
	tile_width:  u64,
	tile_height: u64,
	data:        [][]u64,
	tileset:     Tileset,
}

Tileset :: struct {
	texture:     raylib.Texture2D,
	tile_width:  u64,
	tile_height: u64,
	tile_count:  u64,
	columns:     u64,
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

	value, found := fetch_attribute_u64(doc, 0, "tilewidth")
	if !found do return false
	tileset.tile_width = value

	value, found = fetch_attribute_u64(doc, 0, "tileheight")
	if !found do return false
	tileset.tile_height = value

	value, found = fetch_attribute_u64(doc, 0, "tilecount")
	if !found do return false
	tileset.tile_count = value

	value, found = fetch_attribute_u64(doc, 0, "columns")
	if !found do return false
	tileset.columns = value

	image_id, image_found := xml.find_child_by_ident(doc, 0, "image")
	if !image_found do return false

	image_source, source_found := xml.find_attribute_val_by_key(doc, image_id, "source")
	if !source_found do return false

	tex, tex_ok := assets_load_texture(a, strings.concatenate({"res/", image_source}))
	if !tex_ok {
		fmt.eprintf("Failed to load tileset texture: %s\n", image_source)
		return false
	}

	tileset.texture = tex
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
	r.fields_per_record = int(cols)
	defer csv.reader_destroy(&r)

	csv.reader_init_with_string(&r, raw_data)

	row_idx := 0
	for record, idx in csv.iterator_next(&r) {
		if u64(row_idx) >= rows {
			fmt.eprintfln("Warning: More rows (%d) than expected (%d)", idx + 1, rows)
			break
		}

		if u64(len(record)) != cols {
			fmt.eprintfln("Row %d has %d columns, expected %d", idx, len(record), cols)
			return nil, false
		}
		// Convert each field
		for field, col_idx in record {
			value, ok := strconv.parse_u64(field)
			if !ok {
				fmt.eprintfln("Failed to convert at [%d,%d]: %q", row_idx, col_idx, field)
				return nil, false
			}
			result[row_idx][col_idx] = value
		}
		row_idx += 1
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

	value, found := fetch_attribute_u64(doc, 0, "width")
	if !found do return false
	tilemap.map_width = value

	value, found = fetch_attribute_u64(doc, 0, "height")
	if !found do return false
	tilemap.map_height = value

	value, found = fetch_attribute_u64(doc, 0, "tilewidth")
	if !found do return false
	tilemap.tile_width = value

	value, found = fetch_attribute_u64(doc, 0, "tileheight")
	if !found do return false
	tilemap.tile_height = value

	tileset_id, ok := xml.find_child_by_ident(doc, 0, "tileset")
	if !ok do return false

	tileset_filepath, tileset_ok := xml.find_attribute_val_by_key(doc, tileset_id, "source")
	if !tileset_ok do return false

	tileset: Tileset
	ok = load_tileset(a, &tileset, resolve_relative(filepath, tileset_filepath))
	if !ok do return false
	tilemap.tileset = tileset

	layer_id, layer_ok := xml.find_child_by_ident(doc, 0, "layer")
	if !layer_ok do return false

	data_id, data_ok := xml.find_child_by_ident(doc, layer_id, "data")
	if !data_ok do return false

	raw_csv_data := doc.elements[data_id].value
	switch value in raw_csv_data[0] {
	case string:
		data, data_ok := parse_csv(value, tilemap.map_height, tilemap.map_width)
		if !data_ok do return false
		tilemap.data = data
	case u32:
		panic("Expected string")
	}

	return true
}

