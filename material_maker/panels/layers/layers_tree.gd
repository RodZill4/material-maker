extends Tree

var layers = null
var selected_item : TreeItem = null
var just_selected : bool = false

const ICON_LAYER_PAINT = preload("res://material_maker/panels/layers/icons/layer_paint.tres")
const ICON_LAYER_PROC = preload("res://material_maker/panels/layers/icons/layer_proc.tres")
const ICON_LAYER_MASK = preload("res://material_maker/panels/layers/icons/layer_mask.tres")
const ICONS = [ ICON_LAYER_PAINT, ICON_LAYER_PROC, ICON_LAYER_MASK ]

const BUTTON_SHOWN = preload("res://material_maker/panels/layers/icons/visible.tres")
const BUTTON_HIDDEN = preload("res://material_maker/panels/layers/icons/not_visible.tres")

signal selection_changed(old_selected, new_selected)

func _ready():
	set_column_expand(1, false)
	set_column_custom_minimum_width(1, 30)

func _make_custom_tooltip(for_text):
	if for_text == "":
		return null
	var panel = preload("res://material_maker/panels/layers/layer_tooltip.tscn").instantiate()
	var item : TreeItem = instance_from_id(int(for_text)) as TreeItem
	panel.set_layer(item.get_meta("layer"))
	return panel

func update_from_layers(layers_array : Array, selected_layer) -> void:
	selected_item = null
	clear()
	do_update_from_layers(layers_array, create_item(), selected_layer)

func do_update_from_layers(layers_array : Array, item : TreeItem, selected_layer) -> void:
	for l in layers_array:
		var new_item = create_item(item)
		new_item.set_text(0, l.name)
		new_item.set_icon(0, ICONS[l.get_layer_type()])
		new_item.add_button(1, BUTTON_HIDDEN if l.hidden else BUTTON_SHOWN, 0)
		new_item.set_editable(0, false)
		new_item.set_meta("layer", l)
		new_item.set_tooltip(0, str(new_item.get_instance_id()))
		if l == selected_layer:
			new_item.select(0)
			selected_item = new_item
		do_update_from_layers(l.layers, new_item, selected_layer)

func _get_drag_data(_position : Vector2):
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

func _can_drop_data(position : Vector2, data):
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

func _drop_data(position : Vector2, data):
	var target_item : TreeItem = get_item_at_position(position)
	if data != null and target_item != null and !item_is_child(target_item, data):
		var layer = data.get_meta("layer")
		match get_drop_section_at_position(position):
			0:
				layers.move_layer_into(layer, target_item.get_meta("layer"))
			-1:
				if target_item.get_parent() != null:
					layers.move_layer_into(layer, target_item.get_parent().get_meta("layer"), get_item_index(target_item))
				else:
					print("Cannot move item")
			1:
				if target_item.get_parent() != null:
					layers.move_layer_into(layer, target_item.get_parent().get_meta("layer"), get_item_index(target_item)+1)
				else:
					print("Cannot move item")
		_on_layers_changed()

func _on_Tree_button_pressed(item : TreeItem, _column : int, _id : int):
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !event.pressed and selected_item != null and just_selected:
		selected_item.set_editable(0, true)
		just_selected = false

func _on_Tree_item_edited():
	selected_item.get_meta("layer").name = selected_item.get_text(0)

func _on_layers_changed():
	layers._on_layers_changed()
