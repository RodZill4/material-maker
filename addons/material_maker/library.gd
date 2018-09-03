tool
extends Tree

func get_drag_data(position):
	var selected_item = get_selected()
	if selected_item != null:
		var data = selected_item.get_metadata(0)
		if data == null:
			return null
		var preview
		if data.has("icon") && data.has("library"):
			var filename = data.library.left(data.library.rfind("."))+"/"+data.icon+".png"
			preview = TextureRect.new()
			preview.texture = ImageTexture.new()
			preview.texture.load(filename)
		elif data.has("type") and data.type == "uniform":
			preview = ColorRect.new()
			preview.rect_size = Vector2(32, 32)
			if data.has("color"):
				preview.color = Color(data.color.r, data.color.g, data.color.b, data.color.a)
		else:
			preview = Label.new()
			preview.text = data.tree_item
		set_drag_preview(preview)
		return data 
	return null

func _ready():
	var root = create_item()
	var lib_path = OS.get_executable_path()
	lib_path = lib_path.left(max(lib_path.rfind("\\"), lib_path.rfind("/"))+1)+"library/base.json"
	if !add_library(lib_path):
		add_library("res://addons/material_maker/library/base.json")
	add_library("user://library/user.json")

func add_library(filename):
	var root = get_root()
	var file = File.new()
	if file.open(filename, File.READ) != OK:
		return false
	var lib = parse_json(file.get_as_text())
	file.close()
	if lib != null && lib.has("lib"):
		for m in lib.lib:
			m.library = filename
			add_item(m, m.tree_item)
		return true
	return false

func add_item(item, item_name, item_parent = null):
	if item_parent == null:
		item.tree_item = item_name
		item_parent = get_root()
	var slash_position = item_name.find("/")
	if slash_position == -1:
		var new_item = null
		var c = item_parent.get_children()
		while c != null:
			if c.get_text(0) == item_name:
				new_item = c
				break
			c = c.get_next()
		if new_item == null:
			new_item = create_item(item_parent)
			new_item.set_text(0, item_name)
			new_item.collapsed = true
		if item.has("type") || item.has("nodes"):
			new_item.set_metadata(0, item)
		if item.has("collapsed"):
			new_item.collapsed = item.collapsed
		return new_item
	else:
		var prefix = item_name.left(slash_position)
		var suffix = item_name.right(slash_position+1)
		var new_parent = null
		var c = item_parent.get_children()
		while c != null:
			if c.get_text(0) == prefix:
				new_parent = c
				break
			c = c.get_next()
		if new_parent == null:
			new_parent = create_item(item_parent)
			new_parent.collapsed = true
		new_parent.set_text(0, prefix)
		return add_item(item, suffix, new_parent)

func serialize_library(array, library_name, item = null):
	if item == null:
		item = get_root()
	item = item.get_children()
	while item != null:
		var m = item.get_metadata(0)
		if m != null && m.has("library") and m.library == library_name:
			array.append(m)
		serialize_library(array, library_name, item)
		item = item.get_next()

func save_library(library_name, item = null):
	var array = []
	serialize_library(array, library_name)
	print("Saving library "+library_name)
	var file = File.new()
	if file.open(library_name, File.WRITE) == OK:
		file.store_string(to_json({lib=array}))
		file.close()
