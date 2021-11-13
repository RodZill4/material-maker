extends Node

var library_path : String = ""
var library_name : String = ""
var library_items : Array = []
var library_items_by_name : Dictionary = {}
var library_icons : Dictionary = {}
var read_only : bool = false

func _ready():
	pass

func create_library(path : String, name : String) -> void:
	library_path = path
	library_name = name
	library_items = []
	library_items_by_name = {}
	library_icons = {}
	read_only = false

func load_library(path : String, ro : bool = false) -> bool:
	var file : File = File.new()
	if OS.get_name() == "Android":
		path = path.replace("root://", "res://material_maker/")
	else:
		path = path.replace("root://", OS.get_executable_path().get_base_dir()+"/")
	if ! file.open(path, File.READ) == OK:
		print("Failed to open "+path)
		return false
	var data = parse_json(file.get_as_text())
	library_path = path
	library_name = data.name if data.has("name") else ""
	library_items = data.lib
	read_only = ro
	for i in data.lib:
		library_items_by_name[i.tree_item] = i
		var texture : ImageTexture = ImageTexture.new()
		var image : Image = Image.new()
		if i.has("icon_data"):
			image.load_png_from_buffer(Marshalls.base64_to_raw(i.icon_data))
		elif i.has("icon"):
			image.load(path.get_basename()+"/"+i.icon+".png")
			i.icon_data = Marshalls.raw_to_base64(image.save_png_to_buffer())
		else:
			library_icons[i.tree_item] = null
			continue
		texture.create_from_image(image)
		library_icons[i.tree_item] = texture
	return true

func get_items(filter : String, disabled_sections : Array, aliased_items : Array) -> Array:
	var array : Array = []
	for i in library_items:
		if filter == "" or i.tree_item.to_lower().find(filter) != -1 or aliased_items.find(i.tree_item) != -1:
			var slash_pos = i.tree_item.find("/")
			var section_name = i.tree_item.left(slash_pos) if slash_pos != -1 else i.tree_item
			if disabled_sections.find(section_name) == -1:
				array.push_back({ name=i.tree_item, item=i, icon=library_icons[i.tree_item] })
	return array

func get_item_section(item_name : String) -> String:
	for i in library_items:
		if i.has("name"):
			if i["name"] == item_name:
				return i["tree_item"].rsplit("/")[0]
		if i.has("type"):
			if i["type"] == item_name:
				return i["tree_item"].rsplit("/")[0]
	return ""

func get_node_sections(node_sections : Dictionary) -> void:
	for i in library_items:
		var slash_position = i.tree_item.find("/")
		if slash_position == -1:
			continue
		var section = i.tree_item.left(slash_position)
		if !i.has("type"):
			continue
		if mm_loader.predefined_generators.has(i.type):
			i = mm_loader.predefined_generators[i.type]
		if i.has("shader_model"):
			if i.shader_model.has("name"):
				node_sections[i.shader_model.name] = section
		elif i.has("label"):
			node_sections[i.label] = section
		elif i.has("type"):
			node_sections[i.type] = section

func get_sections() -> Array:
	var sections : Array = Array()
	for i in library_items:
		var section_name = i.tree_item.left(i.tree_item.find("/"))
		if sections.find(section_name) == -1:
			sections.push_back(section_name)
	return Array(sections)

func save_library() -> void:
	Directory.new().make_dir_recursive(library_path.get_base_dir())
	var file = File.new()
	if file.open(library_path, File.WRITE) == OK:
		file.store_string(JSON.print({name=library_name, lib=library_items}, "\t", true))
		file.close()

func add_item(item_name : String, image : Image, data : Dictionary) -> void:
	if read_only:
		return
	data.tree_item = item_name
	data.icon_data = Marshalls.raw_to_base64(image.save_png_to_buffer())
	var new_library_items = []
	var inserted = false
	for i in library_items:
		if i.tree_item != item_name:
			new_library_items.push_back(i)
		elif !inserted:
			new_library_items.push_back(data)
			inserted = true
	if !inserted:
		new_library_items.push_back(data)
	library_items = new_library_items
	library_items_by_name[item_name] = data
	var texture : ImageTexture = ImageTexture.new()
	texture.create_from_image(image)
	library_icons[item_name] = texture
	save_library()

func remove_item(item_name : String) -> void:
	if read_only:
		return
	var new_library_items = []
	for i in library_items:
		if i.tree_item != item_name:
			new_library_items.push_back(i)
	library_items = new_library_items
	library_items_by_name.erase(item_name)
	library_icons.erase(item_name)
	save_library()

func rename_item(old_name : String, new_name : String) -> void:
	if read_only or library_items_by_name.has(new_name):
		return
	library_items_by_name[new_name] = library_items_by_name[old_name]
	library_icons[new_name] = library_icons[old_name]
	library_items_by_name[new_name].tree_item = new_name
	library_items_by_name.erase(old_name)
	library_icons.erase(old_name)
	save_library()

func update_item_icon(name : String, icon : Image) -> void:
	if read_only:
		return
	var data = library_items_by_name[name]
	data.icon_data = Marshalls.raw_to_base64(icon.save_png_to_buffer())
	library_icons[name].create_from_image(icon)
	save_library()
