extends Tree

var layers = null
var selected_item : TreeItem = null
var just_selected : bool = false
var layer_count : int = 0

const BUTTON_SHOWN = preload("res://material_maker/panels/paint/icons/visible.png")
const BUTTON_HIDDEN = preload("res://material_maker/panels/paint/icons/not_visible.png")

signal layers_changed()
signal selection_changed(old_selected, new_selected)

func _ready():
	set_column_expand(1, false)
	set_column_min_width(1, 30)

func update_from_layers(layers_array : Array, selected_layer) -> void:
	selected_item = null
	clear()
	do_update_from_layers(layers_array, create_item(), selected_layer)

func do_update_from_layers(layers_array : Array, item : TreeItem, selected_layer) -> void:
	for l in layers_array:
		var new_item = create_item(item)
		new_item.set_text(0, l.name)
		new_item.add_button(1, BUTTON_HIDDEN if l.hidden else BUTTON_SHOWN, 0)
		new_item.set_editable(0, false)
		new_item.set_meta("layer", l)
		if l == selected_layer:
			new_item.select(0)
			selected_item = new_item
		do_update_from_layers(l.layers, new_item, selected_layer)

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

func get_drag_data(position : Vector2):
	var layer = get_selected().get_meta("layer")
	var label : Label = Label.new()
	label.text = layer.name
	set_drag_preview(label)
	return get_selected()

func item_is_child(i1 : TreeItem, i2 : TreeItem):
	while i1 != null:
		if i1 == i2:
			return true
		i1 = i1.get_parent()
	return false

func can_drop_data(position : Vector2, data):
	drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
	var target_item = get_item_at_position(position)
	if target_item != null and !item_is_child(target_item, data):
		return true
	return false

static func get_item_index(item : TreeItem) -> int:
	var rv : int = 0
	while item.get_prev() != null:
		item = item.get_prev()
		rv += 1
	return rv

func drop_data(position : Vector2, data):
	var target_item : TreeItem = get_item_at_position(position)
	if data != null and target_item != null and !item_is_child(target_item, data):
		match get_drop_section_at_position(position):
			0:
				layers.move_layer_into(data.get_meta("layer"), target_item.get_meta("layer"))
			-1:
				layers.move_layer_into(data.get_meta("layer"), target_item.get_parent().get_meta("layer"), get_item_index(target_item))
			1:
				layers.move_layer_into(data.get_meta("layer"), target_item.get_parent().get_meta("layer"), get_item_index(target_item)+1)
		_on_layers_changed()
		
func move_item_before(item, target_item):
	while target_item != item && target_item != null:
		var next_item = target_item.get_next()
		target_item.move_to_bottom()
		target_item = next_item

func _on_Tree_button_pressed(item : TreeItem, column : int, id : int):
	var layer = item.get_meta("layer")
	layer.hidden = !layer.hidden
	_on_layers_changed()

func _on_Tree_cell_selected():
	just_selected = true
	if selected_item != null:
		selected_item.set_editable(0, false)
	if selected_item != get_selected():
		emit_signal("selection_changed", selected_item, get_selected())

func _on_Tree_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed and selected_item != null and just_selected:
		selected_item.set_editable(0, true)
		just_selected = false

func _on_Tree_item_edited():
	selected_item.get_meta("layer").name = selected_item.get_text(0)

func _on_layers_changed():
	layers._on_layers_changed()

# Update from layers data structure

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
