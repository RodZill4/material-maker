extends Tree

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func get_drag_data(position):
	var selected_item = get_selected()
	if selected_item != null:
		var data = selected_item.get_metadata(0)
		return data 
	return null


func _ready():
	var root = create_item()
	add_library("res://addons/procedural_material/material_library.json")

func add_library(filename):
	var root = get_root()
	var file = File.new()
	if file.open(filename, File.READ) != OK:
		return
	var lib = parse_json(file.get_as_text())
	file.close()
	for m in lib.lib:
		add_item(m, m.tree_item, root)

func add_item(item, item_name, item_parent):
	var slash_position = item_name.find("/")
	if slash_position == -1:
		var new_item = create_item(item_parent)
		new_item.set_text(0, item_name)
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
			new_parent = create_item(item_parent)
		new_parent.set_text(0, prefix)
		return add_item(item, suffix, new_parent)
