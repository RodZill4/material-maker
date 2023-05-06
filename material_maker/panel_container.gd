extends TabContainer


func _drop_data(_at_position, data):
	var source : TabContainer = get_node(data.from_path)
	var panel = source.get_tab_control(data.tabc_element)
	source.remove_child(panel)
	add_child(panel)

func _can_drop_data(_at_position, data):
	if data is Dictionary and data.has("type") and data.type == "tabc_element":
		return true
	return false
