tool
extends Tree

var selected_item : TreeItem = null
var just_selected : bool = true
var brush_count : int = 0

const DEFAULT_BRUSH = {
	has_albedo = false,
	albedo_color = { r=0.0, g=0.0, b=0.0, a=1.0 },
	albedo_texture_mode = 0,
	albedo_texture = null,
	albedo_texture_file_name = null,
	has_metallic = false,
	metallic = 0.0,
	has_roughness = false,
	roughness = 0.0,
	has_emission = false,
	emission_color = { r=0.0, g=0.0, b=0.0, a=1.0 },
	emission_texture_mode = 0,
	emission_texture = null,
	emission_texture_file_name = null,
	has_depth = false,
	depth_color = { r=0.0, g=0.0, b=0.0, a=1.0 },
	depth_texture_mode = 0,
	depth_texture = null,
	depth_texture_file_name = null
}

func _ready():
	create_item()

func create_brush(brush):
	var new_item = create_item(get_root())
	brush_count += 1
	new_item.set_text(0, "New brush "+str(brush_count))
	new_item.set_metadata(0, brush)
	new_item.set_selectable(0, true)

func update_brush(brush):
	var item = get_selected()
	if item != null:
		item.set_metadata(0, brush)

func get_drag_data(position):
	return get_selected()

func item_is_child(i1 : TreeItem, i2 : TreeItem):
	while i1 != null:
		if i1 == i2:
			return true
		i1 = i1.get_parent()
	return false

func copy_item_into(src, dest):
	var new_item : TreeItem = create_item(dest)
	new_item.set_text(0, src.get_text(0))
	new_item.set_metadata(0, src.get_metadata(0))
	new_item.set_selectable(0, true)
	var i = src.get_children()
	while i != null:
		copy_item_into(i, new_item)
		i = i.get_next()
	return new_item

func can_drop_data(position, data):
	drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
	var target_item = get_item_at_position(position) 
	if target_item != null and !item_is_child(target_item, data):
		return true
	return false

func drop_data(position : Vector2, data):
	var target_item : TreeItem = get_item_at_position(position) 
	if target_item != null and !item_is_child(target_item, data):
		var new_item = null
		match get_drop_section_at_position(position):
			0:
				copy_item_into(data, target_item)
			-1:
				new_item = copy_item_into(data, target_item.get_parent())
			1:
				new_item = copy_item_into(data, target_item.get_parent())
				target_item = target_item.get_next()
		data.get_parent().remove_child(data)
		if new_item != null:
			while target_item != new_item:
				var next_item = target_item.get_next()
				target_item.move_to_bottom()
				target_item = next_item

func encode_color(c):
	return { r=c.r, g=c.g, b=c.b, a=c.a }
	
func decode_color(c):
	return Color(c.r, c.g, c.b, c.a)

func set_lib(lib, parent = null):
	if lib == null:
		return null
	var item
	if parent == null:
		clear()
		item = create_item()
	else:
		item = create_item(parent)
		item.set_selectable(0, true)
	if lib.has("name"):
		item.set_text(0, lib.name)
	if lib.has("brush"):
		for k in DEFAULT_BRUSH.keys():
			if !lib.brush.has(k):
				lib.brush[k] = DEFAULT_BRUSH[k]
		lib.brush.albedo_color = decode_color(lib.brush.albedo_color)
		lib.brush.emission_color = decode_color(lib.brush.emission_color)
		lib.brush.depth_color = decode_color(lib.brush.depth_color)
		item.set_metadata(0, lib.brush)
	if lib.has("children"):
		for c in lib.children:
			set_lib(c, item)

func get_lib(item = null):
	if item == null:
		item = get_root()
	var lib = {}
	lib.name=item.get_text(0)
	if item.get_metadata(0) != null:
		lib.brush=item.get_metadata(0)
		lib.brush.albedo_color = encode_color(lib.brush.albedo_color)
		lib.brush.emission_color = encode_color(lib.brush.emission_color)
		lib.brush.depth_color = encode_color(lib.brush.depth_color)
	var child_item = item.get_children()
	if child_item != null:
		lib.children = []
		while child_item != null:
			lib.children.append(get_lib(child_item))
			child_item = child_item.get_next()
	return lib

func _on_Tree_cell_selected():
	just_selected = true
	if selected_item != null:
		selected_item.set_editable(0, false)
	selected_item = get_selected()

func _on_Tree_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed and just_selected:
		selected_item.set_editable(0, true)
		just_selected = false
