extends Panel

# Borrowed from ProtonGraph

# Courtesy of pycbouh, original code can be found there:
# https://gist.github.com/pycbouh/7a88b55697138b646f69da0de40f71ac

# Node references
var graph_edit : GraphEdit
var graph_hscroll : HScrollBar
var graph_vscroll : VScrollBar

var minimap_button : Button

# Public properties
export var toolbar_icon : Texture

# Private properties
var _graph_nodes : Array = [] # of Dictionary
var _graph_lines : Array = [] # of Dictionary
var _camera_position : Vector2 = Vector2(100, 50)
var _camera_size : Vector2 = Vector2(200, 200)
var _graph_proportions : Vector2 = Vector2(1, 1)
var _zoom_level : float = 1.0

var _map_padding : Vector2 = Vector2(5, 5)
var _graph_padding : Vector2 = Vector2(0, 0)

var _is_pressing : bool = false


func _enter_tree() -> void:
	_update_node_references()


func _ready() -> void:
	_update_theme()
	_update_map()

	if (graph_edit):
		minimap_button = ToolButton.new()
		minimap_button.icon = toolbar_icon
		minimap_button.hint_tooltip = "Toggle graph minimap."
		graph_edit.get_zoom_hbox().add_child(minimap_button)
		minimap_button.connect("pressed", self, "_on_minimap_button_pressed")

		graph_edit.connect("draw", self, "_on_graph_edit_changed")
		graph_edit.connect("update_minimap", self, "_on_graph_edit_changed")

	# Update size based on editor scale
	rect_min_size *= 1.0 # EditorUtil.get_editor_scale()

	update()


func _gui_input(event) -> void:
	if (event is InputEventMouseButton && event.button_index == BUTTON_LEFT):
		if (event.is_pressed()):
			_is_pressing = true
			var click_location = _convert_to_graph_position(event.position - _map_padding) - _graph_padding

			if (graph_edit):
				var scroll_offset = get_scroll_offset()
				graph_edit.scroll_offset = click_location + scroll_offset - _camera_size / 2
		elif (_is_pressing):
			_is_pressing = false

		accept_event()
	elif (event is InputEventMouseMotion && _is_pressing):
		var click_location = _convert_to_graph_position(event.position - _map_padding) - _graph_padding

		if (graph_edit):
			var scroll_offset = get_scroll_offset()
			graph_edit.scroll_offset = click_location + scroll_offset - _camera_size / 2

		accept_event()


func _draw() -> void:
	var centering_offset = _convert_from_graph_position(_graph_padding)
	var map_offset = _map_padding + centering_offset

	for node in _graph_nodes:
		var position = _convert_from_graph_position(node.position) + map_offset
		var size = _convert_from_graph_position(node.size)
		var node_shape = Rect2(position - size / 2, size)

		if (node.is_comment):
			var comment_background = node.node_color.linear_interpolate(Color.black, 0.65)
			draw_rect(node_shape, comment_background, true)
			draw_rect(node_shape, node.node_color, false)
		else:
			draw_rect(node_shape, node.node_color)

	for line in _graph_lines:
		var from_position = _convert_from_graph_position(line.from_position) + map_offset
		var to_position = _convert_from_graph_position(line.to_position) + map_offset
		draw_line(from_position, to_position, line.from_color)

	var camera_center = _convert_from_graph_position(_camera_position + _camera_size / 2) + map_offset
	var camera_viewport = _convert_from_graph_position(_camera_size)
	var camera_position = (camera_center - camera_viewport / 2)
	draw_rect(Rect2(camera_position, camera_viewport), Color(0.65, 0.65, 0.65, 0.2), true)
	draw_rect(Rect2(camera_position, camera_viewport), Color(0.65, 0.65, 0.65, 0.45), false)


func _update_theme() -> void:
	if (!Engine.editor_hint || !is_inside_tree()):
		return

	modulate.a = 0.85


func _update_map() -> void:
	if (!graph_edit):
		return

	# Update graph spatial information
	var scroll_offset = get_scroll_offset()
	var graph_size = get_graph_size()

	_zoom_level = graph_edit.zoom
	_camera_position = graph_edit.scroll_offset - scroll_offset
	_camera_size = graph_edit.rect_size

	var render_size = get_render_size()
	var target_ratio = render_size.x / render_size.y
	var graph_ratio = graph_size.x / graph_size.y

	_graph_proportions = graph_size
	_graph_padding = Vector2(0, 0)
	if (graph_ratio > target_ratio):
		_graph_proportions.x = graph_size.x
		_graph_proportions.y = graph_size.x / target_ratio
		_graph_padding.y = abs(graph_size.y - _graph_proportions.y) / 2
	else:
		_graph_proportions.x = graph_size.y * target_ratio
		_graph_proportions.y = graph_size.y
		_graph_padding.x = abs(graph_size.x - _graph_proportions.x) / 2

	# Update node information
	_graph_nodes = []
	_graph_lines = []

	for child in graph_edit.get_children():
		if !(child is GraphNode):
			continue

		var node_data := {
			"position": (child.offset + child.rect_size / 2) * _zoom_level - scroll_offset,
			"size": child.rect_size * _zoom_level,
			"node_color": Color.white,
			"is_comment": child.comment,
		}

		var child_color = child.get("minimap_color")
		if (child_color):
			node_data.node_color = child_color
		elif !child.selected:
			node_data.node_color *= 0.5

		_graph_nodes.append(node_data)

	for connection in graph_edit.get_connection_list():
		var from_child = graph_edit.get_node_or_null(connection.from)
		var to_child = graph_edit.get_node_or_null(connection.to)
		if (!from_child || !to_child):
			continue # We got caught in between two resources switching, some data is outdated

		var from_slot_position = from_child.rect_size if from_child.comment else from_child.rect_size / 2
		var to_slot_position = 0 if from_child.comment else to_child.rect_size / 2

		var line_data := {
			"from_position": (from_child.offset + from_slot_position) * _zoom_level - scroll_offset,
			"to_position": (to_child.offset + to_slot_position) * _zoom_level - scroll_offset,
			"from_color": Color.white,
			"to_color": Color.white,
		}

		var from_child_color = from_child.get("minimap_color")
		if (from_child_color):
			line_data.from_color = from_child_color
		var to_child_color = to_child.get("minimap_color")
		if (to_child_color):
			line_data.to_color = to_child_color

		_graph_lines.append(line_data)

	update()


func _update_node_references() -> void:
	var parent_node = get_parent()
	if !(parent_node is GraphEdit):
		return

	graph_edit = parent_node
	var top_layer
	for c in graph_edit.get_children():
		if c.get_class() == "GraphEditFilter":
			top_layer = c
			break
	for c in top_layer.get_children():
		if c is HScrollBar:
			graph_hscroll = c
		elif c is VScrollBar:
			graph_vscroll = c


### Helpers
func _convert_from_graph_position(graph_position : Vector2) -> Vector2:
	var position = Vector2(0, 0)
	var render_size = get_render_size()

	position.x = graph_position.x * render_size.x / _graph_proportions.x
	position.y = graph_position.y * render_size.y / _graph_proportions.y

	return position


func _convert_to_graph_position(position : Vector2) -> Vector2:
	var graph_position = Vector2(0, 0)
	var render_size = get_render_size()

	graph_position.x = position.x * _graph_proportions.x / render_size.x
	graph_position.y = position.y * _graph_proportions.y / render_size.y

	return graph_position


func get_render_size() -> Vector2:
	if (!is_inside_tree()):
		return Vector2.ZERO

	return rect_size - 2 * _map_padding


func get_scroll_offset() -> Vector2:
	if (!graph_hscroll || !graph_vscroll):
		return Vector2(0, 0)

	return Vector2(graph_hscroll.min_value, graph_vscroll.min_value)


func get_graph_size() -> Vector2:
	if (!graph_hscroll || !graph_vscroll):
		return Vector2(1, 1)

	var scroll_offset = get_scroll_offset()
	var graph_size = Vector2(graph_hscroll.max_value, graph_vscroll.max_value) - scroll_offset

	if (graph_size.x == 0):
		graph_size.x = 1
	if (graph_size.y == 0):
		graph_size.y = 1

	return graph_size


### Event handlers
func _on_graph_edit_changed() -> void:
	_update_map()


func _on_minimap_button_pressed() -> void:
	if (visible):
		hide()
	else:
		show()
