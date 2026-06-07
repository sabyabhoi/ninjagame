package main

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
	data:        [dynamic][dynamic]u64,
}

Tileset :: struct {
	texture:     raylib.Texture2D,
	tile_width:  u64,
	tile_height: u64,
	tile_count:  u64,
	columns:     u64,
}

// Joins a path relative to the directory containing base_file.
resolve_relative_path :: proc(base_file: string, relative: string) -> string {
	dir := filepath.dir(base_file, context.temp_allocator)
	return filepath.join({dir, relative}, context.temp_allocator)
}

fetch_attribute_u64 :: proc(doc: ^xml.Document, element_id: u32, key: string) -> (u64, bool) {
	value, found := xml.find_attribute_val_by_key(doc, element_id, key)
	if !found {
		return 0, false
	}

	return strconv.parse_u64(value)
}

fetch_attribute_string :: proc(doc: ^xml.Document, element_id: u32, key: string) -> (string, bool) {
	return xml.find_attribute_val_by_key(doc, element_id, key)
}

element_text :: proc(doc: ^xml.Document, element_id: u32) -> (string, bool) {
	if element_id >= doc.element_count {
		return "", false
	}

	element := doc.elements[element_id]
	text: strings.Builder
	strings.builder_init(&text, context.temp_allocator)

	for val in element.value {
		if part, ok := val.(string); ok {
			strings.write_string(&text, part)
		}
	}

	result := strings.to_string(text)
	if len(result) == 0 {
		return "", false
	}

	return result, true
}

parse_csv_tile_data :: proc(
	data: string,
	firstgid: u32,
	width: u32,
	height: u32,
	tilemap: ^Tilemap,
) -> bool {
	resize(&tilemap.data, int(height))
	for row in 0 ..< int(height) {
		tilemap.data[row] = make([dynamic]u32, int(width))
	}

	row: u32 = 0
	col: u32 = 0

	csv := data
	for part in strings.split_iterator(&csv, ",") {
		trimmed := strings.trim_space(part)
		if len(trimmed) == 0 do continue

		gid, ok := strconv.parse_u32(trimmed)
		if !ok do return false

		local_id: u32 = 0
		if gid != 0 {
			if gid < firstgid do return false
			local_id = gid - firstgid
		}

		if row < height && col < width {
			tilemap.data[row][col] = local_id
		}

		col += 1
		if col >= width {
			col = 0
			row += 1
		}
	}

	return true
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

	image_source, source_found := fetch_attribute_string(doc, image_id, "source")
	if !source_found do return false

	image_path := resolve_relative_path(filepath, image_source)
	tex, tex_ok := assets_load_texture(a, image_path)
	if !tex_ok {
		fmt.eprintf("Failed to load tileset texture: %s\n", image_path)
		return false
	}

	tileset.texture = tex
	return true
}

load_world :: proc(a: ^Assets, tilemap: ^Tilemap, tileset: ^Tileset, filepath: string) -> bool {
	doc, err := xml.load_from_file(filepath)
	if err != .None {
		fmt.eprintln("Failed to parse map XML:", err)
		return false
	}
	defer xml.destroy(doc)

	width, width_ok := fetch_attribute_u64(doc, 0, "width")
	if !width_ok do return false
	tilemap.map_width = width

	height, height_ok := fetch_attribute_u64(doc, 0, "height")
	if !height_ok do return false
	tilemap.map_height = height

	tile_width, tile_width_ok := fetch_attribute_u64(doc, 0, "tilewidth")
	if !tile_width_ok do return false
	tilemap.tile_width = tile_width

	tile_height, tile_height_ok := fetch_attribute_u64(doc, 0, "tileheight")
	if !tile_height_ok do return false
	tilemap.tile_height = tile_height

	tileset_id, tileset_found := xml.find_child_by_ident(doc, 0, "tileset")
	if !tileset_found do return false

	firstgid, firstgid_ok := fetch_attribute_u64(doc, tileset_id, "firstgid")
	if !firstgid_ok do return false

	tileset_source, tileset_source_ok := fetch_attribute_string(doc, tileset_id, "source")
	if !tileset_source_ok do return false

	tileset_path := resolve_relative_path(filepath, tileset_source)
	if !load_tileset(a, tileset, tileset_path) do return false

	layer_id, layer_found := xml.find_child_by_ident(doc, 0, "layer")
	if !layer_found do return false

	data_id, data_found := xml.find_child_by_ident(doc, layer_id, "data")
	if !data_found do return false

	csv_data, csv_ok := element_text(doc, data_id)
	if !csv_ok do return false

	return parse_csv_tile_data(csv_data, firstgid, width, height, tilemap)
}
