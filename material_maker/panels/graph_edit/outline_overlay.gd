extends Control

# Connection lines outline overlay

func _ready() -> void:
	owner.begin_node_move.connect(hide)
	owner.end_node_move.connect(show)
	owner.child_order_changed.connect(_move_behind_connections.call_deferred)


func _move_behind_connections() -> void:
	# Move behind connection lines to make outlines visible in comment nodes
	owner.move_child(self, owner.get_node("_connection_layer").get_index()-1)


func _draw() -> void:
	if owner.active_connections.is_empty():
		return

	var reroute_positions : PackedVector2Array
	var reroute_colors : PackedColorArray

	var zoom : float = owner.zoom
	for line in owner.active_connections:
		if owner.has_node(NodePath(line.to_node)) and owner.has_node(NodePath(line.to_node)):
			var from_node : GraphNode = owner.get_node(NodePath(line.from_node))
			var to_node : GraphNode = owner.get_node(NodePath(line.to_node))

			if not(from_node and to_node):
				continue

			var from_pos := from_node.get_output_port_position(line.from_port)*zoom + from_node.position
			var to_pos := to_node.get_input_port_position(line.to_port)*zoom + to_node.position

			if get_viewport_rect().intersects(Rect2(from_pos, to_pos-from_pos).abs()):
				# connection outline
				var line_width := maxf(10.0, owner.connection_lines_thickness)
				line_width = line_width + zoom if zoom < 0.9 else line_width * zoom
				draw_polyline(owner._get_connection_line(from_pos, to_pos),
						to_node.get_input_port_color(line.to_port).darkened(0.35),
						 line_width, true)

				# find unique reroute positions to avoid redrawing overlapping outlines
				var reroute_highlight_color := from_node.get_output_port_color(line.from_port).darkened(0.35)
				for node in [from_node, to_node]:
					if node is MMGraphReroute and node.get_rect().get_center() not in reroute_positions:
						reroute_positions.append(node.get_rect().get_center())
						reroute_colors.append(reroute_highlight_color)

		# draw reroute outlines
		for p in len(reroute_positions):
			draw_circle(reroute_positions[p], 20.0*zoom, reroute_colors[p], true, -1, true)
