extends Tree

var selected_item : TreeItem = null
var just_selected : bool = false
var layer_count : int = 0

const BUTTON_SHOWN = preload("res://material_maker/panels/paint/icons/visible.png")
const BUTTON_HIDDEN = preload("res://material_maker/panels/paint/icons/not_visible.png")

signal layers_changed(layers)
signal selection_changed(old_selected, new_selected)

func _ready():
	set_column_expand(1, false)
	set_column_min_width(1, 30)
	create_item()

func init_item(new_item : TreeItem, src : TreeItem = null):
	new_item.set_selectable(0, true)
	if src != null:
		new_item.set_text(0, src.get_text(0))
		new_item.add_button(1, src.get_button(1, 0), 0)
		new_item.set_meta("albedo", src.get_meta("albedo"))
		new_item.set_editable(0, src.is_editable(0))
		if selected_item == src:
			selected_item = new_item
			new_item.select(0)
	else:
		layer_count += 1
		new_item.set_text(0, "New layer "+str(layer_count))
		new_item.add_button(1, BUTTON_SHOWN, 0)
		new_item.set_editable(0, false)

func create_layer():
	var new_item = create_item(get_root())
	init_item(new_item)
	var target_item = get_root().get_children()
	while target_item != new_item:
		var next_item = target_item.get_next()
		target_item.move_to_bottom()
		target_item = next_item
	new_item.select(0)

func remove_current():
	selected_item = null
	var current_item = get_selected()
	if current_item != null:
		current_item.get_parent().remove_child(current_item)
		current_item = get_root().get_children()
		if current_item != null:
			current_item.select(0)
		_on_layers_changed()
		update()

func move_current_up():
	var current = get_selected()
	if current != null:
		print("move_current_up")
		var target = current.get_prev()
		print(target)
		if target != null:
			current.move_to_bottom()
			move_item_before(current, target)
			_on_layers_changed()
			update()

func move_current_down():
	var current = get_selected()
	if current != null:
		print("move_current_down")
		var target = current.get_next()
		print(target)
		if target != null:
			target = target.get_next()
			current.move_to_bottom()
			move_item_before(current, target)
			_on_layers_changed()
			update()

func get_drag_data(position : Vector2):
	return get_selected()

func item_is_child(i1 : TreeItem, i2 : TreeItem):
	while i1 != null:
		if i1 == i2:
			return true
		i1 = i1.get_parent()
	return false

func copy_item_into(src : TreeItem, dest : TreeItem):
	var new_item : TreeItem = create_item(dest)
	init_item(new_item, src)
	var i = src.get_children()
	while i != null:
		copy_item_into(i, new_item)
		i = i.get_next()
	return new_item

func can_drop_data(position : Vector2, data):
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
			move_item_before(new_item, target_item)
		_on_layers_changed()
		
func move_item_before(item, target_item):
	while target_item != item && target_item != null:
		var next_item = target_item.get_next()
		target_item.move_to_bottom()
		target_item = next_item

func _on_Tree_button_pressed(item : TreeItem, column : int, id : int):
	item.set_button(column, id, BUTTON_HIDDEN if item.get_button(column, id) == BUTTON_SHOWN else BUTTON_SHOWN)
	_on_layers_changed()
	update()

func _on_Tree_cell_selected():
	just_selected = true
	if selected_item != null:
		selected_item.set_editable(0, false)
	if selected_item != get_selected():
		emit_signal("selection_changed", selected_item, get_selected())
		selected_item = get_selected()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	_on_layers_changed()

func _on_Tree_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed and selected_item != null and just_selected:
		selected_item.set_editable(0, true)
		just_selected = false

func get_item_list(item : TreeItem):
	var list = []
	if item == get_root() or item.get_button(1, 0) == BUTTON_SHOWN:
		var i : TreeItem = item.get_children()
		while i != null:
			var child_list = get_item_list(i)
			for i2 in list:
				child_list.append(i2)
			list = child_list
			i = i.get_next()
		if item != get_root():
			list.push_front(item)
	return list

func _on_layers_changed():
	var item_list = get_item_list(get_root())
	emit_signal("layers_changed", item_list)

# resize

func resize_layers(item : TreeItem, channels : Array, size : int):
	var i : TreeItem = item.get_children()
	if i != null:
		while i != null:
			var d = { name=i.get_text(0), hidden=i.get_button(1, 0) != BUTTON_SHOWN }
			for c in channels:
				if i.has_meta(c):
					var texture = i.get_meta(c)
					var image = texture.get_data()
					image.resize(size, size)
					texture.set_data(image)
			resize_layers(i, channels, size)
			i = i.get_next()

# load/save

func load_layers(data : Dictionary, path : String, channels : Array):
	selected_item = null
	clear()
	do_load_layers(data, create_item(), path, channels)
	get_root().get_children().select(0)

func do_load_layers(data : Dictionary, parent : TreeItem, path : String, channels : Array):
	if data.has("layers"):
		for l in data.layers:
			var new_item = create_item(parent)
			new_item.set_text(0, l.name)
			new_item.add_button(1, BUTTON_HIDDEN if l.hidden else BUTTON_SHOWN, 0)
			for c in channels:
				if l.has(c):
					var texture = ImageTexture.new()
					texture.load(path+"/"+l[c])
					new_item.set_meta(c, texture)
			new_item.set_editable(0, false)
			do_load_layers(l, new_item, path, channels)

func save_layers(data : Dictionary, item : TreeItem, layer_index : int, path : String, channels : Array):
	var i : TreeItem = item.get_children()
	if i != null:
		data.layers = []
		while i != null:
			var d = { name=i.get_text(0), hidden=i.get_button(1, 0) != BUTTON_SHOWN }
			for c in channels:
				if i.has_meta(c):
					if i.get_meta(c).get_data() == null:
						print(i.get_meta(c))
						continue
					var file_name : String = c + "_" + str(layer_index) + ".png"
					var file_path : String = path + "/" + file_name
					i.get_meta(c).get_data().save_png(file_path)
					d[c] = file_name
					layer_index += 1
			layer_index = save_layers(d, i, layer_index, path, channels)
			data.layers.append(d)
			i = i.get_next()
	return layer_index
