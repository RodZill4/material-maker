extends Tree


signal drop_item(item, dest, position)


func _ready():
	set_column_expand(1, false)
	set_column_min_width(1, 28)

func get_drag_data(position):
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

func can_drop_data(position, data):
	if data is Dictionary and data.has("item") and data.item is TreeItem:
		var destination : TreeItem = get_item_at_position(position)
		if destination == null:
			return true
		if get_drop_section_at_position(position) != 0:
			destination = destination.get_parent()
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

func drop_data(position, data):
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
