extends MMGraphNodeMinimal


func _ready() -> void:
	var theme: Theme = get_node("/root/MainWindow").theme
	for stylebox in theme.get_stylebox_list("Reroute"):
		add_stylebox_override(stylebox, theme.get_stylebox(stylebox, "Reroute"))


func on_connections_changed():
	var graph_edit = get_parent()
	var color: Color = Color(1.0, 1.0, 1.0)
	var type: int = 42
	var port_type: String = "any"
	for c in graph_edit.get_connection_list():
		if c.to == name:
			var node: GraphNode = graph_edit.get_node(c.from)
			color = node.get_slot_color_right(c.from_port)
			type = node.get_slot_type_right(c.from_port)
			port_type = node.generator.get_output_defs()[c.from_port].type
			break
		if c.from == name:
			var node: GraphNode = graph_edit.get_node(c.to)
			color = node.get_slot_color_left(c.to_port)
			type = node.get_slot_type_left(c.to_port)
			port_type = node.generator.get_input_defs()[c.from_port].type
	set_slot(0, true, type, color, true, type, color)
	generator.set_port_type(port_type)
