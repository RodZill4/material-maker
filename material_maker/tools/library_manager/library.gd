extends Node

var library_path : String = ""
var library_name : String = ""
var library_items : Array = []
var library_items_by_name : Dictionary = {}
var library_icons : Dictionary = {}
var read_only : bool = false

func _ready():
	pass

func create_library(path : String, lib_name : String) -> void:
	library_path = path
	library_name = lib_name
	library_items = []
	library_items_by_name = {}
	library_icons = {}
	read_only = false

func load_library(path : String, ro : bool = false, raw_data : String = "") -> bool:
	if raw_data == "":
		if OS.get_name() == "Android":
			path = path.replace("root://", "res://material_maker/")
		else:
			path = path.replace("root://", MMPaths.get_resource_dir()+"/")
		var file : FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			print("Failed to open "+path)
			return false
		raw_data = file.get_as_text()
	var json = JSON.new()
	if json.parse(raw_data) == OK and json.get_data() is Dictionary:
		var data : Dictionary = json.get_data()
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
			texture = ImageTexture.create_from_image(image)
			library_icons[i.tree_item] = texture
		print("Successfully read library %s" % path)
		return true
	else:
		print("%s is not a valid library file" % path)
	return false

func get_item(lib_name : String):
	for i in library_items:
		if lib_name == i.tree_item:
			return { name=i.tree_item, item=i, icon=library_icons[i.tree_item] }
	return null

func get_items(filter : String, disabled_sections : Array, aliased_items : Array) -> Array:
	var array : Array = []
	for i in library_items:
		if filter == "" or i.tree_item.to_lower().find(filter) != -1 or aliased_items.find(i.tree_item) != -1:
			var slash_pos = i.tree_item.find("/")
			var section_name = i.tree_item.left(slash_pos) if slash_pos != -1 else i.tree_item
			if disabled_sections.find(section_name) == -1:
				array.push_back({ name=i.tree_item, item=i, icon=library_icons[i.tree_item] })
	return array

func generate_node_sections(node_sections : Dictionary) -> void:
	for i in library_items:
		var section = i.tree_item
		var slash_position = section.find("/")
		if slash_position != -1:
			section = i.tree_item.left(slash_position)
		if !i.has("type"):
			continue
		var node_name = ""
		if mm_loader.predefined_generators.has(i.type):
			node_name = i.type
			i = mm_loader.predefined_generators[i.type]
		elif i.has("shader_model"):
			if i.shader_model.has("name"):
				node_name = i.shader_model.name
		elif i.has("label"):
			node_name = i.label
		elif i.has("type"):
			node_name = i.type
		if node_name != "":
			if not node_sections.has(node_name):
				node_sections[node_name] = section
#			else:
#				print(node_name+" already defined in "+section)


func get_sections() -> Array:
	var sections : Array = Array()
	for i in library_items:
		var section_name = i.tree_item.left(i.tree_item.find("/"))
		if sections.find(section_name) == -1:
			sections.push_back(section_name)
	return Array(sections)

func save_library() -> void:
	DirAccess.open("res://").make_dir_recursive(library_path.get_base_dir())
	var file : FileAccess = FileAccess.open(library_path, FileAccess.WRITE)
	if file.is_open():
		file.store_string(JSON.stringify({name=library_name, lib=library_items}, "\t", true))
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
	texture.set_image(image)
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

func update_item_icon(item_name : String, icon : Image) -> void:
	if read_only:
		return
	var data = library_items_by_name[item_name]
	data.icon_data = Marshalls.raw_to_base64(icon.save_png_to_buffer())
	library_icons[item_name].set_image(icon)
	save_library()
