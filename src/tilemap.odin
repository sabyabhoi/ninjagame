package main

import "core:encoding/xml"
import "core:fmt"
import "core:strconv"
import "vendor:raylib"

Tilemap :: struct {
	map_width:   u32,
	map_height:  u32,
	tile_width:  u32,
	tile_height: u32,
	data:        [dynamic][dynamic]u32,
}

Tileset :: struct {
	texture:     raylib.Texture2D,
	tile_width:  u64,
	tile_height: u64,
	tile_count:  u64,
	columns:     u64,
}

load_world :: proc(tilemap: ^Tilemap, filepath: string) {
	doc, err := xml.load_from_file(filepath)
	if err != .None {
		fmt.eprintln("Failed to parse XML: ", err)
		return
	}
	defer xml.destroy(doc)

	fmt.println(doc)
}

fetch_and_parse :: proc(doc: ^xml.Document, s: string) -> (u64, bool) {
	value, found := xml.find_attribute_val_by_key(doc, 0, s)
	if !found {
		return 0, false
	}

	return strconv.parse_u64(value)
}

load_tileset :: proc(tileset: ^Tileset, filepath: string) {
	doc, err := xml.load_from_file(filepath)
	if err != .None {
		fmt.eprintln("Failed to parse XML: ", err)
		return
	}
	defer xml.destroy(doc)

	fmt.println(doc.elements)

	value, found := fetch_and_parse(doc, "tilewidth")
	if !found do return

	tileset.tile_width = value

	value, found = fetch_and_parse(doc, "tileheight")
	if !found do return

	tileset.tile_height = value

	value, found = fetch_and_parse(doc, "tilecount")
	if !found do return

	tileset.tile_count = value

	value, found = fetch_and_parse(doc, "columns")
	if !found do return

	tileset.columns = value

	element_id, element_found := xml.find_child_by_ident(doc, 0, "image")
	if !element_found do return

	xml.find_attribute_val_by_key(doc, element_id, "source")
}

