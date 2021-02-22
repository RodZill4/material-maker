extends Node

export var base_lib_name : String = ""
export var base_lib : String = ""
export var alt_base_lib : String = ""
export var user_lib_name : String = ""
export var user_lib : String = ""
export var sections : PoolStringArray

var section_icons : Dictionary = {}
var disabled_sections = []

var libraries : Array = []

const LIBRARY = preload("res://material_maker/tools/library_manager/library.gd")

func _ready():
	init_libraries()
	init_section_icons()

# Libraries

func init_libraries() -> void:
	var library = LIBRARY.new()
	if library.load_library(base_lib, true) or library.load_library(alt_base_lib):
		if library.library_name == "":
			library.library_name = base_lib_name
		libraries.push_back(library)
	library = LIBRARY.new()
	if library.load_library(user_lib):
		if library.library_name == "":
			library.library_name = user_lib_name
		libraries.push_back(library)
	init_section_icons()

func get_items(filter : String) -> Array:
	var array : Array = []
	for l in libraries:
		for i in l.get_items(filter, disabled_sections):
			array.push_back(i)
	return array


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
	for s in libraries[0].get_sections():
		if section_icons.has(s):
			section_list.push_back(s)
	return section_list

func get_section_icon(section_name : String) -> Texture:
	return section_icons[section_name] if section_icons.has(section_name) else null

func toggle_section(section_name : String) -> bool:
	if disabled_sections.find(section_name) == -1:
		disabled_sections.push_back(section_name)
		return false
	else:
		disabled_sections.erase(section_name)
		return true
