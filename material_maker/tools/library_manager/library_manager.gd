extends Node

@export var base_lib_name : String = ""
@export var base_lib : String = ""
@export var alt_base_lib : String = ""
@export var user_lib_name : String = ""
@export var user_lib : String = ""
@export var sections : PackedStringArray
@export var config_section : String = ""

#var section_icons : Dictionary = {}
var section_colors : Dictionary = {}

var section_default_colors : Dictionary = {}
var section_classic_colors : Dictionary = {}

var node_sections : Dictionary = {}

var disabled_libraries : Array = []
var disabled_sections : Array = []

@export var base_aliases_file_name : String = ""
@export var alt_base_aliases_file_name : String = ""
@export var user_aliases_file_name : String = ""
var base_item_aliases : Dictionary = {}
var user_item_aliases : Dictionary = {}

var item_usage : Dictionary
@export var item_usage_file : String = ""

const LIBRARY = preload("res://material_maker/tools/library_manager/library.gd")

signal libraries_changed()


func _ready():
	init_libraries()
	init_section_icons()
	init_aliases()
	init_usage()

func _exit_tree():
	if item_usage_file == "":
		return
	DirAccess.make_dir_recursive_absolute(item_usage_file.get_base_dir())
	var file = FileAccess.open(item_usage_file, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(item_usage, "\t", true))

# Libraries

func init_libraries() -> void:
	var library = LIBRARY.new()
	if library.load_library(base_lib, true) or library.load_library(alt_base_lib):
		if library.library_name == "":
			library.library_name = base_lib_name
		add_child(library)
		library.generate_node_sections(node_sections)
	library = LIBRARY.new()
	DirAccess.make_dir_recursive_absolute(user_lib.get_base_dir())
	if library.load_library(user_lib):
		if library.library_name == "":
			library.library_name = user_lib_name
	else:
		library.create_library(user_lib, user_lib_name)
	add_child(library)
	library.generate_node_sections(node_sections)
	init_section_icons()
	await get_tree().process_frame
	if mm_globals.config.has_section_key(config_section, "libraries"):
		for p in mm_globals.config.get_value(config_section, "libraries"):
			library = LIBRARY.new()
			if library.load_library(p):
				add_child(library)
				library.generate_node_sections(node_sections)
	if mm_globals.config.has_section_key(config_section, "disabled_libraries"):
		disabled_libraries = mm_globals.config.get_value(config_section, "disabled_libraries")
	if mm_globals.config.has_section_key(config_section, "disabled_sections"):
		disabled_sections = mm_globals.config.get_value(config_section, "disabled_sections")
	emit_signal("libraries_changed")
	print("Libraries updated ("+name+")")

func compare_item_usage(i1, i2) -> int:
	var u1 = item_usage[i1.name] if item_usage.has(i1.name) else 0
	var u2 = item_usage[i2.name] if item_usage.has(i2.name) else 0
	return u1 - u2

func get_item(item_name : String):
	for skip_disabled in [ true, false ]:
		for li in get_child_count():
			var l = get_child(li)
			if ! skip_disabled or disabled_libraries.find(l.library_path) == -1:
				var item = l.get_item(item_name)
				if item != null:
					return item
	return null

func get_items(filter : String, sorted := false) -> Array:
	var array: Array = []
	var aliased_items := [base_item_aliases, user_item_aliases]

	for li in get_child_count():
		var l = get_child(li)
		if disabled_libraries.find(l.library_path) == -1:
			for i in l.get_items(filter, disabled_sections, aliased_items):
				i.library_index = li
				array.push_back(i)

	if sorted:
		var sorted_array: Array = []
		for i in array:
			var u1 = item_usage[i.name] if item_usage.has(i.name) else 0
			var inserted := false
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
		var idx := 0
		for item in array:
			item["idx"] = idx
			idx += 1

	return array


func save_library_list() -> void:
	var library_list = []
	for i in range(2, get_child_count()):
		var lib_path: String = get_child(i).library_path
		library_list.push_back(lib_path)
	mm_globals.config.set_value(config_section, "libraries", library_list)

func has_library(path : String) -> bool:
	for c in get_children():
		if c.library_path == path:
			return true
	return false

func create_library(path : String, library_name : String) -> void:
	var e: Error
	if has_library(path):
		return
	var library = LIBRARY.new()
	library.create_library(path, library_name)
	e = library.save_library()
	if e != OK:
		var message = "Could not create library \"%s\" in \"%s\" \n\nERROR: %s" % [library_name, path, error_string(e)]
		mm_globals.main_window.accept_dialog(message, false, true)
		return
	add_child(library)
	save_library_list()
	mm_globals.set_tip_text("Library \"%s\" created at \"%s\"" % [library_name, path], 5, 1)

func load_library(path : String, data : String = "") -> void:
	if has_library(path):
		return
	var library = LIBRARY.new()
	library.load_library(path, false, data)
	add_child(library)
	if disabled_libraries.find(path) != -1:
		disabled_libraries.erase(path)
	emit_signal("libraries_changed")
	save_library_list()
	library.get_sections()

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
	mm_globals.config.set_value(config_section, "disabled_libraries", disabled_libraries)
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

func update_item_icon_in_library(index : int, item_name : String, icon : Image) -> void:
	get_child(index).update_item_icon(item_name, icon)
	emit_signal("libraries_changed")

# Section icons

func update_section_colors(is_theme_classic : bool = false) -> void:
	section_colors = section_classic_colors if is_theme_classic else section_default_colors

func init_section_icons() -> void:
	const default_theme : Theme = preload("res://material_maker/theme/default.tres")
	const classic_theme : Theme = preload("res://material_maker/theme/classic_base.tres")

	# node colors
	for i in sections.size():
		section_default_colors[sections[i]] = default_theme.get_color(
				"section_" + sections[i].to_lower(), "MM_LibrarySectionButton")
		section_classic_colors[sections[i]] = classic_theme.get_color(
				"section_" + sections[i].to_lower(), "MM_LibrarySectionButton")

	section_colors = section_default_colors


func get_sections() -> Array:
	var section_list : Array = Array()
	for s in get_child(0).get_sections():
		if section_colors.has(s):
			section_list.push_back(s)
	return section_list


func get_section_color(section_name : String) -> Color:
	if section_colors.has(section_name):
		return section_colors[section_name]
	for s in section_colors.keys():
		if TranslationServer.translate(s) == section_name:
			return section_colors[s]
	return Color.DIM_GRAY

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
	mm_globals.config.set_value(config_section, "disabled_sections", disabled_sections)
	return enabled

# Aliases

func init_aliases() -> void:
	base_item_aliases = load_aliases(base_aliases_file_name)
	if base_item_aliases.is_empty():
		base_item_aliases = load_aliases(alt_base_aliases_file_name)
	user_item_aliases = load_aliases(user_aliases_file_name)

func load_aliases(path : String) -> Dictionary:
	path = path.replace("root://", MMPaths.get_resource_dir()+"/")
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	return test_json_conv.get_data()

func save_aliases() -> void:
	if user_aliases_file_name == "":
		return
	DirAccess.open("res://").make_dir_recursive(user_aliases_file_name.get_base_dir())
	var file = FileAccess.open(user_aliases_file_name, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(user_item_aliases, "\t", true))
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
	aliases = ",".join(PackedStringArray(list))
	user_item_aliases[item] = aliases
	save_aliases()

# Sort items by usage in item menu

func init_usage() -> void:
	var file = FileAccess.open(item_usage_file, FileAccess.READ)
	if file != null:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			item_usage = json.get_data()

func item_created(item : String) -> void:
	if item_usage.has(item):
		item_usage[item] += 1
	else:
		item_usage[item] = 1
