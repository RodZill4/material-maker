extends Tree


signal drop_item(item, dest, position)


func _ready():
	set_column_expand(1, false)
	set_column_custom_minimum_width(1, 28)
	set_column_expand(2, false)
	set_column_custom_minimum_width(2, 28)

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

func _get_drag_data(position):
	var item : TreeItem = get_item_at_position(position)
	if item == null:
		return null
	else:
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

func _can_drop_data(position, data):
	if data is Dictionary and data.has("item") and data.item is TreeItem:
		var destination : TreeItem = get_item_at_position(position)
		if destination != null and get_drop_section_at_position(position) != 0:
			destination = destination.get_parent()
		if not mm_sdf_builder.scene_get_type(data.item.get_meta("scene")).item_category in get_valid_children_types(destination):
			return false
		if destination == null:
			return true
		return ! item_is_parent(data.item, destination)
	return false

func get_item_index(item : TreeItem) -> int:
	var index = 0
	var i = item.get_parent().get_children()
	while i != null:
		if i == item:
			return index
		i = i.get_next()
		index += 1
	return -1

func _drop_data(position, data):
	if data is Dictionary and data.has("item") and data.item is TreeItem:
		var item = get_item_at_position(position)
		match get_drop_section_at_position(position):
			0:
				emit_signal("drop_item", data.item, item, -1)
			-1:
				emit_signal("drop_item", data.item, item.get_parent(), get_item_index(item))
			1:
				emit_signal("drop_item", data.item, item.get_parent(), get_item_index(item)+1)
			_:
				emit_signal("drop_item", data.item, get_root(), -1)
