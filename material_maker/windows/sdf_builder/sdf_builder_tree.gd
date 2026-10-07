extends Tree

var tree_scrollbar : VScrollBar

signal drop_item(item, dest, position)


func _ready():
	set_column_expand(1, false)
	set_column_custom_minimum_width(1, 28)
	set_column_expand(2, false)
	set_column_custom_minimum_width(2, 28)
	set_column_expand(3, false)
	set_column_custom_minimum_width(3, 32)

	if mm_globals.get_config("touch_optimization"):
		add_theme_constant_override("v_separation", 12)

	for node in get_children(true):
		if node is VScrollBar:
			tree_scrollbar = node

func get_drag_handle_pos(item : TreeItem) -> float:
	if not item:
		return 0.0
	var scroll_w : float = 0.0
	if tree_scrollbar.visible:
		scroll_w = tree_scrollbar.size.x
	var item_w : float = get_item_area_rect(item).size.x
	return maxf(item_w - scroll_w - 72.0, 0.0)

var dragged_from_handle : bool = false

func _gui_input(event : InputEvent) -> void:
	if event is InputEventScreenDrag and event.index == 0:
		var item : TreeItem = get_item_at_position(event.position)
		if dragged_from_handle and item and event.position.x < get_drag_handle_pos(item):
			tree_scrollbar.value -= event.relative.y
		accept_event()
	elif event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			var item : TreeItem = get_item_at_position(event.position)
			if item:
				item.select(0, false)
				if event.position.x > get_drag_handle_pos(item):
					dragged_from_handle = true
			else:
				deselect_all()
		else:
			dragged_from_handle = false
		accept_event()

func get_sdf_item_type(item : TreeItem) -> Object:
	if item == null or not item.has_meta("scene"):
		return null
	var scene = item.get_meta("scene")
	return mm_sdf_builder.scene_get_type(scene)

func get_sdf_item_type_name(item : TreeItem) -> String:
	var type : Object = get_sdf_item_type(item)
	if type == null:
		return ""
	return type.item_category

func get_nearest_parent(item : TreeItem, type : String) -> TreeItem:
	while item != null:
		if get_sdf_item_type_name(item) == type:
			break
		item = item.get_parent()
	return item

func _get_drag_data(at_position : Vector2):
	var item : TreeItem = get_item_at_position(at_position)
	if item == null:
		return null
	else:
		if at_position.x < get_drag_handle_pos(item):
			return null
		var label = Label.new()
		label.text = item.get_text(0)
		set_drag_preview(label)
		drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
		return { item=item }

# return true if item1 is parent of item2
func item_is_parent(item1 : TreeItem, item2 : TreeItem) -> bool:
	while item2 != null:
		if item1 == item2:
			return true
		item2 = item2.get_parent()
	return false

func get_valid_children_types(parent : TreeItem):
	var valid_children_types : Array = []
	var parent_type : Object = get_sdf_item_type(parent)
	if parent_type == null:
		if get_root().get_children().is_empty():
			valid_children_types = [ "SDF2D", "SDF3D" ]
		else:
			valid_children_types = [ get_sdf_item_type_name(get_root().get_children()[0]) ]
	elif parent_type.has_method("get_children_types"):
		valid_children_types = parent_type.get_children_types()
	else:
		valid_children_types.push_back(parent_type.item_category)
	return valid_children_types

func _can_drop_data(at_position : Vector2, data : Variant):
	if data is Dictionary and data.has("item") and data.item is TreeItem:
		var destination : TreeItem = get_item_at_position(at_position)
		if destination != null and get_drop_section_at_position(at_position) != 0:
			destination = destination.get_parent()
		if not mm_sdf_builder.scene_get_type(data.item.get_meta("scene")).item_category in get_valid_children_types(destination):
			return false
		if destination == null:
			return true
		return ! item_is_parent(data.item, destination)
	return false

func get_item_index(item : TreeItem) -> int:
	var index = 0
	for i in item.get_parent().get_children():
		if i == item:
			return index
		index += 1
	return -1

func _drop_data(at_position : Vector2, data : Variant):
	if data is Dictionary and data.has("item") and data.item is TreeItem:
		var item = get_item_at_position(at_position)
		match get_drop_section_at_position(at_position):
			0:
				emit_signal("drop_item", data.item, item, -1)
			-1:
				emit_signal("drop_item", data.item, item.get_parent(), get_item_index(item))
			1:
				emit_signal("drop_item", data.item, item.get_parent(), get_item_index(item)+1)
			_:
				emit_signal("drop_item", data.item, get_root(), -1)
