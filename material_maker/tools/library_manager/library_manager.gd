extends Node

export var base_lib_name : String = ""
export var base_lib : String = ""
export var alt_base_lib : String = ""
export var user_lib_name : String = ""
export var user_lib : String = ""
export var sections : PoolStringArray
export var config_section : String = ""

var section_icons : Dictionary = {}
var section_colors : Dictionary = {}

var disabled_libraries : Array = []
var disabled_sections : Array = []

export var base_aliases_file_name : String = ""
export var alt_base_aliases_file_name : String = ""
export var user_aliases_file_name : String = ""
var base_item_aliases : Dictionary = {}
var user_item_aliases : Dictionary = {}

var item_usage : Dictionary
export var item_usage_file : String = ""

const LIBRARY = preload("res://material_maker/tools/library_manager/library.gd")


signal libraries_changed


func _ready():
	init_libraries()
	init_section_icons()
	init_aliases()
	init_usage()

func _exit_tree():
	if item_usage_file == "":
		return
	Directory.new().make_dir_recursive(item_usage_file.get_base_dir())
	var file = File.new()
	if file.open(item_usage_file, File.WRITE) == OK:
		file.store_string(JSON.print(item_usage, "\t", true))
		file.close()

# Libraries

func init_libraries() -> void:
	var config = get_config()
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
	yield(get_tree(), "idle_frame")
	if config.has_section_key(config_section, "libraries"):
		for p in config.get_value(config_section, "libraries"):
			library = LIBRARY.new()
			if library.load_library(p):
				add_child(library)
	if config.has_section_key(config_section, "disabled_libraries"):
		disabled_libraries = config.get_value(config_section, "disabled_libraries")
	if config.has_section_key(config_section, "disabled_sections"):
		disabled_sections = config.get_value(config_section, "disabled_sections")
	emit_signal("libraries_changed")

func get_config() -> ConfigFile:
	return get_node("/root/MainWindow").config_cache

func compare_item_usage(i1, i2) -> int:
	var u1 = item_usage[i1.name] if item_usage.has(i1.name) else 0
	var u2 = item_usage[i2.name] if item_usage.has(i2.name) else 0
	return u1 - u2

func get_items(filter : String, sorted = false) -> Array:
	var array : Array = []
	var aliased_items = []
	for al in [ base_item_aliases, user_item_aliases ]:
		for a in al.keys():
			if al[a].find(filter) != -1 and aliased_items.find(a) == -1:
				aliased_items.push_back(a)
	for li in get_child_count():
		var l = get_child(li)
		if disabled_libraries.find(l.library_path) == -1:
			for i in l.get_items(filter, disabled_sections, aliased_items):
				i.library_index = li
				array.push_back(i)
	if sorted:
		var sorted_array : Array = []
		for i in array:
			var u1 = item_usage[i.name] if item_usage.has(i.name) else 0
			var inserted = false
			for p in sorted_array.size():
				var i2 = sorted_array[p]
				var u2 = item_usage[i2.name] if item_usage.has(i2.name) else 0
				if u1 > u2:
					sorted_array.insert(p, i)
					inserted = true
					break
			if !inserted:
				sorted_array.push_back(i)
		array = sorted_array
	return array

func save_library_list() -> void:
	var library_list = []
	for i in range(2, get_child_count()):
		library_list.push_back(get_child(i).library_path)
	get_config().set_value(config_section, "libraries", library_list)

func has_library(path : String) -> bool:
	for c in get_children():
		if c.library_path == path:
			return true
	return false

func create_library(path : String, name : String) -> void:
	if has_library(path):
		return
	var library = LIBRARY.new()
	library.create_library(path, name)
	add_child(library)
	save_library_list()

func load_library(path : String) -> void:
	if has_library(path):
		return
	var library = LIBRARY.new()
	library.load_library(path)
	add_child(library)
	if disabled_libraries.find(path) != -1:
		disabled_libraries.erase(path)
	emit_signal("libraries_changed")
	save_library_list()

func unload_library(index : int) -> void:
	var lib = get_child(index).library_path
	if disabled_libraries.find(lib) != -1:
		disabled_libraries.erase(lib)
	remove_child(get_child(index))
	emit_signal("libraries_changed")
	save_library_list()

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
	get_config().set_value(config_section, "disabled_libraries", disabled_libraries)
	return enabled

func add_item_to_library(index : int, item_name : String, image : Image, data : Dictionary) -> void:
	get_child(index).add_item(item_name, image, data)
	emit_signal("libraries_changed")

func remove_item_from_library(index : int, item_name : String) -> void:
	get_child(index).remove_item(item_name)
	emit_signal("libraries_changed")

func rename_item_in_library(index : int, old_name : String, new_name : String) -> void:
	get_child(index).rename_item(old_name, new_name)
	emit_signal("libraries_changed")

func update_item_icon_in_library(index : int, name : String, icon : Image) -> void:
	get_child(index).update_item_icon(name, icon)
	emit_signal("libraries_changed")

# Section icons

func init_section_icons() -> void:
	var atlas = preload("res://material_maker/icons/icons.tres")
	var atlas_image = atlas.get_data()
	if atlas_image == null and atlas is ProxyTexture:
		atlas_image = atlas.base.get_data()
	atlas_image.lock()
	for i in sections.size():
		var x = 128+32*(i%4)
		var y = 32+32*(i/4)
		var texture : AtlasTexture = AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(x, y, 32, 32)
		section_icons[sections[i]] = texture
		section_colors[sections[i]] = atlas_image.get_pixel(x, y)
	atlas_image.unlock()

func get_sections() -> Array:
	var section_list : Array = Array()
	for s in get_child(0).get_sections():
		if section_icons.has(s):
			section_list.push_back(s)
	return section_list

func get_section_icon(section_name : String) -> Texture:
	return section_icons[section_name] if section_icons.has(section_name) else null

func get_section_color(section_name : String) -> Color:
	var color = null
	if section_colors.has(section_name):
		return section_colors[section_name]
	for s in section_colors.keys():
		if TranslationServer.translate(s) == section_name:
			return section_colors[s]
	return color

func is_section_enabled(section_name : String) -> bool:
	return disabled_sections.find(section_name) == -1

func toggle_section(section_name : String) -> bool:
	var enabled : bool = false
	if disabled_sections.find(section_name) == -1:
		disabled_sections.push_back(section_name)
	else:
		disabled_sections.erase(section_name)
		enabled = true
	emit_signal("libraries_changed")
	get_config().set_value(config_section, "disabled_sections", disabled_sections)
	return enabled

# Aliases

func init_aliases() -> void:
	base_item_aliases = load_aliases(base_aliases_file_name)
	if base_item_aliases.empty():
		base_item_aliases = load_aliases(alt_base_aliases_file_name)
	user_item_aliases = load_aliases(user_aliases_file_name)

func load_aliases(path : String) -> Dictionary:
	path = path.replace("root://", OS.get_executable_path().get_base_dir()+"/")
	var file = File.new()
	if ! file.open(path, File.READ) == OK:
		return {}
	return parse_json(file.get_as_text())

func save_aliases() -> void:
	if user_aliases_file_name == "":
		return
	Directory.new().make_dir_recursive(user_aliases_file_name.get_base_dir())
	var file = File.new()
	if file.open(user_aliases_file_name, File.WRITE) == OK:
		file.store_string(JSON.print(user_item_aliases, "\t", true))
		file.close()

func get_aliases(item : String) -> String:
	return user_item_aliases[item] if user_item_aliases.has(item) else base_item_aliases[item] if base_item_aliases.has(item) else ""

func set_aliases(item : String, aliases : String) -> void:
	aliases = aliases.to_lower()
	var regex = RegEx.new()
	regex.compile("[^\\w]+") # Negated whitespace character class.
	aliases = regex.sub(aliases, ",", true)
	var list = []
	for i in aliases.split(",", false):
		if list.find(i) == -1:
			list.push_back(i)
	aliases = PoolStringArray(list).join(",")
	user_item_aliases[item] = aliases
	save_aliases()

# Sort items by usage in item menu

func init_usage() -> void:
	var file = File.new()
	if ! file.open(item_usage_file, File.READ) == OK:
		return
	item_usage = parse_json(file.get_as_text())

func item_created(item : String) -> void:
	if item_usage.has(item):
		item_usage[item] += 1
	else:
		item_usage[item] = 1
