extends TabContainer

func _ready():
	pass

func _drop_data(_at_position, data):
	var source : TabContainer = get_node(data.from_path).get_parent()
	var panel = source.get_tab_control(data.tab_index)
	source.remove_child(panel)
	add_child(panel)

func _can_drop_data(_at_position, data):
	if data is Dictionary and data.has("type") and data.type == "tab_container_tab":
		return true
	return false
