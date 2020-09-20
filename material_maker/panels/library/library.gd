extends VBoxContainer

var libraries = []
var libraries_data = {}
var current_filter = ""
var expanded_items : Array = []

onready var tree : Tree = $Tree
onready var filter_line_edit : LineEdit = $HBoxContainer/Filter

func _ready() -> void:
	tree.set_column_expand(0, true)
	tree.set_column_expand(1, false)
	tree.set_column_min_width(1, 32)
	var lib_path = OS.get_executable_path().get_base_dir()+"/library/base.json"
	if !add_library(lib_path):
		add_library("res://material_maker/library/base.json")
	add_library("user://library/user.json")
	init_expanded_items()
	update_tree()

func init_expanded_items() -> void:
	var f = File.new()
	if f.open("user://expanded_items.bin", File.READ) == OK:
		expanded_items = parse_json(f.get_as_text())
		f.close()
	else:
		expanded_items = []
		for l in libraries:
			for m in libraries_data[l]:
				var n : String = m.tree_item
				var slash_position = n.find("/")
				if slash_position != -1:
					n = m.tree_item.left(slash_position)
				if expanded_items.find(n) == -1:
					expanded_items.push_back(n)

func _exit_tree() -> void:
	var f = File.new()
	if f.open("user://expanded_items.bin", File.WRITE) == OK:
		f.store_string(to_json(expanded_items))
		f.close()

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.command and event.scancode == KEY_F:
		filter_line_edit.grab_focus()
		filter_line_edit.select_all()

func get_selected_item_name() -> String:
	return get_item_path(tree.get_selected())

func get_selected_item_doc_name() -> String:
	var item : TreeItem = tree.get_selected()
	if item == null:
		return ""
	var m : Dictionary = item.get_metadata(0)
	if m == null or !m.has("icon"):
		return ""
	return m.icon

func add_library(file_name : String, _filter : String = "") -> bool:
	var file = File.new()
	if file.open(file_name, File.READ) != OK:
		return false
	var lib = parse_json(file.get_as_text())
	file.close()
	if lib != null and lib.has("lib"):
		for m in lib.lib:
			m.library = file_name
		libraries.push_back(file_name)
		libraries_data[file_name] = lib.lib
		return true
	return false

func get_expanded_items(item : TreeItem = null) -> PoolStringArray:
	var expanded_items : PoolStringArray = PoolStringArray()
	if item == null:
		item = tree.get_root()
		if item == null:
			return expanded_items
	elif !item.collapsed:
		expanded_items.push_back(get_item_path(item))
	var i = item.get_children()
	while i != null:
		expanded_items.append_array(get_expanded_items(i))
		i = i.get_next()
	return expanded_items

func update_tree(filter : String = "") -> void:
	filter = filter.to_lower()
	current_filter = filter
	tree.clear()
	tree.create_item()
	for l in libraries:
		for m in libraries_data[l]:
			if filter == "" or m.tree_item.to_lower().find(filter) != -1:
				add_item(m, m.tree_item, get_preview_texture(m, l), null, filter != "")

func get_preview_texture(data : Dictionary, library = null) -> ImageTexture:
	if library == null:
		if data.has("library"):
			library = data.library
		else:
			return null
	if !data.has("icon"):
		return null
	var image_path = library.get_basename()+"/"+data.icon+".png"
	var t : ImageTexture
	if image_path.left(6) == "res://":
		image_path = ProjectSettings.globalize_path(image_path)
	t = ImageTexture.new()
	var image : Image = Image.new()
	if image.load(image_path) == OK:
		t.create_from_image(image)
	else:
		print("Cannot load image "+image_path)
	return t

func add_item(item, item_name, item_icon = null, item_parent = null, force_expand = false) -> TreeItem:
	if item_parent == null:
		item.tree_item = item_name
		item_parent = tree.get_root()
	var slash_position = item_name.find("/")
	if slash_position == -1:
		var new_item : TreeItem = null
		var c = item_parent.get_children()
		while c != null:
			if c.get_text(0) == item_name:
				new_item = c
				break
			c = c.get_next()
		if new_item == null:
			new_item = tree.create_item(item_parent)
			new_item.set_text(0, item_name)
			new_item.collapsed = !force_expand and expanded_items.find(item.tree_item) == -1
			new_item.set_icon(1, item_icon)
			new_item.set_icon_max_width(1, 32)
		if item.has("type") || item.has("nodes"):
			new_item.set_metadata(0, item)
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
			new_parent = tree.create_item(item_parent)
			new_parent.set_text(0, prefix)
			new_parent.collapsed = !force_expand and expanded_items.find(get_item_path(new_parent)) == -1
		return add_item(item, suffix, item_icon, new_parent, force_expand)

func get_item_path(item : TreeItem) -> String:
	if item == null:
		return ""
	var item_path = item.get_text(0)
	var item_parent = item.get_parent()
	while item_parent != tree.get_root():
		item_path = item_parent.get_text(0)+"/"+item_path
		item_parent = item_parent.get_parent()
	return item_path

func get_icon_name(item_name : String) -> String:
	return item_name.to_lower().replace("/", "_").replace(" ", "_")

func serialize_library(array : Array, library_name : String = "", icon_dir : String = "", item : TreeItem = null) -> void:
	if item == null:
		item = tree.get_root()
	item = item.get_children()
	while item != null:
		if item.get_metadata(0) != null:
			var m : Dictionary = item.get_metadata(0)
			if library_name == "" or (m.has("library") and m.library == library_name):
				var copy : Dictionary = m.duplicate()
				copy.erase("library")
				if icon_dir != "" and m.has("icon"):
					var src_path = m.library.get_basename()+"/"+m.icon+".png"
					var icon_name : String = get_icon_name(get_item_path(item))
					var icon_path = icon_dir+"/"+icon_name+".png"
					var dir : Directory = Directory.new()
					dir.copy(src_path, icon_path)
					copy.icon = icon_name
				array.append(copy)
		serialize_library(array, library_name, icon_dir, item)
		item = item.get_next()

func save_library(library_name : String, _item : TreeItem = null) -> void:
	assert(current_filter == "")
	var array : Array = []
	serialize_library(array, library_name)
	var file = File.new()
	if file.open(library_name, File.WRITE) == OK:
		file.store_string(JSON.print({lib=array}, "\t", true))
		file.close()

func add_to_user_library(data : Dictionary, name : String, image : Image) -> void:
	data.tree_item = name
	data.icon = get_icon_name(name)
	var library_path = "user://library/user.json"
	var dir = Directory.new()
	dir.make_dir_recursive(library_path.get_basename())
	image.save_png(library_path.get_basename()+"/"+data.icon+".png")
	if !libraries_data.has(library_path):
		libraries.push_back(library_path)
		libraries_data[library_path] = []
	libraries_data[library_path].push_back(data)
	var file = File.new()
	if file.open(library_path, File.WRITE) == OK:
		file.store_string(JSON.print({lib=libraries_data[library_path]}, "\t", true))
		file.close()
	update_tree(current_filter)

func _on_Filter_text_changed(filter : String) -> void:
	update_tree(filter)

func export_libraries(path : String) -> void:
	var dir : Directory = Directory.new()
	var icon_path = path.get_basename()
	dir.make_dir(icon_path)
	var array = []
	serialize_library(array, "", icon_path)
	var file = File.new()
	if file.open(path, File.WRITE) == OK:
		file.store_string(JSON.print({lib=array}, "\t", true))
		file.close()


func generate_screenshots(graph_edit, item : TreeItem = null) -> int:
	var count : int = 0
	if item == null:
		item = tree.get_root()
	item = item.get_children()
	while item != null:
		if item.get_metadata(0) != null:
			var timer : Timer = Timer.new()
			add_child(timer)
			var new_nodes = graph_edit.create_nodes(item.get_metadata(0))
			timer.wait_time = 0.05
			timer.one_shot = true
			timer.start()
			yield(timer, "timeout")
			var image = get_viewport().get_texture().get_data()
			image.flip_y()
			image = image.get_rect(Rect2(new_nodes[0].rect_global_position-Vector2(1, 2), new_nodes[0].rect_size+Vector2(4, 4)))
			print(get_icon_name(get_item_path(item)))
			image.save_png("res://material_maker/doc/images/node_"+get_icon_name(get_item_path(item))+".png")
			for n in new_nodes:
				graph_edit.remove_node(n)
			timer.queue_free()
			count += 1
		var result = generate_screenshots(graph_edit, item)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		count += result
		item = item.get_next()
	return count

func _on_Tree_item_collapsed(item) -> void:
	var path : String = get_item_path(item)
	if item.collapsed:
		while true:
			var index = expanded_items.find(path)
			if index == -1:
				break
			expanded_items.remove(index)
	else:
		expanded_items.push_back(path)
