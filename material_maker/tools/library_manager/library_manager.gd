extends Node

export var base_lib_name : String = ""
export var base_lib : String = ""
export var alt_base_lib : String = ""
export var user_lib_name : String = ""
export var user_lib : String = ""
export var sections : PoolStringArray

var section_icons : Dictionary = {}
var disabled_libraries : Array = []
var disabled_sections : Array = []


const LIBRARY = preload("res://material_maker/tools/library_manager/library.gd")


signal libraries_changed


func _ready():
	init_libraries()
	init_section_icons()

# Libraries

func init_libraries() -> void:
	var library = LIBRARY.new()
	if library.load_library(base_lib, true) or library.load_library(alt_base_lib):
		if library.library_name == "":
			library.library_name = base_lib_name
		add_child(library)
	library = LIBRARY.new()
	if library.load_library(user_lib):
		if library.library_name == "":
			library.library_name = user_lib_name
	else:
		library.create_library(user_lib, user_lib_name)
	add_child(library)
	init_section_icons()

func get_items(filter : String) -> Array:
	var array : Array = []
	for li in get_child_count():
		var l = get_child(li)
		if disabled_libraries.find(l.library_path) == -1:
			for i in l.get_items(filter, disabled_sections):
				i.library_index = li
				array.push_back(i)
	return array

func is_library_enabled(index : int) -> bool:
	return disabled_libraries.find(get_child(index).library_path) == -1

func toggle_library(index : int) -> bool:
	var enabled : bool = false
	var lib = get_child(index).library_path
	if disabled_libraries.find(lib) == -1:
		disabled_libraries.push_back(lib)
	else:
		disabled_libraries.erase(lib)
		enabled = true
	emit_signal("libraries_changed")
	return enabled

func add_item_to_library(index : int, item_name : String, image : Image, data : Dictionary) -> void:
	get_child(index).add_item(item_name, image, data)
	emit_signal("libraries_changed")

func remove_item_from_library(index : int, item_name : String) -> void:
	get_child(index).remove_item(item_name)
	emit_signal("libraries_changed")

# Section icons

func init_section_icons() -> void:
	var atlas = preload("res://material_maker/icons/icons.tres")
	for i in sections.size():
		var texture : AtlasTexture = AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(128+32*(i%4), 32+32*(i/4), 32, 32)
		section_icons[sections[i]] = texture

func get_sections() -> Array:
	var section_list : Array = Array()
	for s in get_child(0).get_sections():
		if section_icons.has(s):
			section_list.push_back(s)
	return section_list

func get_section_icon(section_name : String) -> Texture:
	return section_icons[section_name] if section_icons.has(section_name) else null

func toggle_section(section_name : String) -> bool:
	var enabled : bool = false
	if disabled_sections.find(section_name) == -1:
		disabled_sections.push_back(section_name)
	else:
		disabled_sections.erase(section_name)
		enabled = true
	emit_signal("libraries_changed")
	return enabled
