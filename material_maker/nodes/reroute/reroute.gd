extends MMGraphNodeMinimal

func _ready() -> void:
	super._ready()
	var current_theme : Theme = mm_globals.main_window.theme
	for stylebox in current_theme.get_stylebox_list("Reroute"):
		add_theme_stylebox_override(stylebox, current_theme.get_stylebox(stylebox, "Reroute"))
	call_deferred("on_connections_changed")

func on_connections_changed():
	var graph_edit = get_parent()
	var color : Color = Color(1.0, 1.0, 1.0)
	var type : int = 42
	var port_type : String = "any"
	for c in graph_edit.get_connection_list():
		if c.to == name:
			var node : GraphNode = graph_edit.get_node(NodePath(c.from))
			color = node.get_slot_color_right(c.from_port)
			type = node.get_slot_type_right(c.from_port)
			port_type = node.generator.get_output_defs()[c.from_port].type
			break
		if c.from == name:
			var node : GraphNode = graph_edit.get_node(NodePath(c.to))
			color = node.get_slot_color_left(c.to_port)
			type = node.get_slot_type_left(c.to_port)
			port_type = node.generator.get_input_defs()[c.from_port].type
	set_slot(0, true, type, color, true, type, color)
	generator.set_port_type(port_type)
