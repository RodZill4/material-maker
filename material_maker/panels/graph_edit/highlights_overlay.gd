extends Control

class_name HighlightsOverlay


class AnimatedConnection extends Line2D:
	var connection : Dictionary

@onready var graph : MMGraphEdit = owner

var active_connections : Array[Dictionary]
var is_updating_connections := false

const LINE_MATERIAL := preload("res://material_maker/panels/graph_edit/animated_connection.tres")

func _ready() -> void:
	graph.child_order_changed.connect(_move_above_connections.call_deferred)
	graph.get_node("_connection_layer").draw.connect(queue_redraw)
	graph.get_node("_connection_layer").child_order_changed.connect(update_connections)
	graph.connection_drag_started.connect(update_connections.bind(1).unbind(3))
	graph.node_selected.connect(update_connections.unbind(1))
	graph.node_deselected.connect(update_connections.unbind(1))
	graph.gui_input.connect(_graph_gui_input)


func _draw() -> void:
	if get_children().is_empty():
		return

	for line : AnimatedConnection in get_children():
		var conn : Dictionary = line.connection
		var positions := get_connection_positions(conn)
		if positions.is_empty():
			continue

		line.visible = get_viewport_rect().intersects(
			Rect2(positions.from, positions.to - positions.from).abs())

		line.points = graph._get_connection_line(positions.from, positions.to)
		line.width = graph.connection_lines_thickness


func _move_above_connections() -> void:
	graph.move_child(self, graph.get_node("_connection_layer").get_index() + 1)


func _graph_gui_input(e : InputEvent) -> void:
	if e is InputEventKey:
		update_connections(true)


func update_connections(should_hide_when_updating : bool = false) -> void:
	if is_updating_connections:
		return
	is_updating_connections = true

	if should_hide_when_updating:
		hide()

	while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		await get_tree().process_frame

	active_connections.clear()
	for c in graph.get_connection_list():
		if (graph.get_node(NodePath(c.from_node)).selected
				or graph.get_node(NodePath(c.to_node)).selected):
			active_connections.append(c)
	await get_tree().process_frame
	create_animated_connections()

	# Remove inactive/invalid animated conections
	if get_children().size():
		for anim_line : AnimatedConnection in get_children():
			if (anim_line.connection not in active_connections
					or get_connection_positions(anim_line.connection).is_empty()):
				remove_child(anim_line)
				anim_line.free()

	queue_redraw()
	is_updating_connections = false
	show.call_deferred()


func create_animated_connections() -> void:
	if active_connections.size():
		for active_connection in active_connections:
			var positions := get_connection_positions(active_connection)
			if positions.is_empty():
				continue

			var has_existing_connection : bool = false
			for c in get_children():
				if c.connection == active_connection:
					has_existing_connection = true
					break

			if not has_existing_connection:
				var ac := AnimatedConnection.new()
				ac.connection = active_connection
				ac.texture_mode = Line2D.LINE_TEXTURE_TILE
				ac.material = LINE_MATERIAL
				ac.points = graph._get_connection_line(positions.from, positions.to)
				ac.width = graph.connection_lines_thickness
				add_child(ac)


func get_connection_positions(from_connection : Dictionary) -> Dictionary:
	var c := from_connection
	var positions : Dictionary
	if graph.has_node(NodePath(c.from_node)) and graph.has_node(NodePath(c.to_node)):
		var from_node : GraphNode = graph.get_node(NodePath(c.from_node))
		var to_node : GraphNode = graph.get_node(NodePath(c.to_node))
		if from_node and to_node:
			var from_pos := from_node.get_output_port_position(c.from_port)
			var to_pos := to_node.get_input_port_position(c.to_port)
			positions.from = from_pos * graph.zoom + from_node.position
			positions.to = to_pos * graph.zoom + to_node.position
	return positions
