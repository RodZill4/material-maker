extends Control

class_name LazyLink

enum LazyNode {
	FROM,
	TO,
}

enum Port {
	INPUT,
	OUTPUT,
}

var csf : float
var popup_menu_item_height : int

const MAX_POPUP_HEIGHT = 375
const SLOT_SVG = "<svg width=\"16\"height=\"16\">
		<circle cx=\"8\"cy=\"8\"r=\"5\"fill=\"#FFF\"/></svg>"

var inactive_color : Color
var inactive_link_color : Color
var active_color : Color
var active_link_color : Color
var context_color : Color
var context_link_color : Color

var source : GraphNode
var target : GraphNode

var frame: StyleBoxFlat
var linked_frame: StyleBoxFlat

var from_point: Vector2
var has_context : bool = false
var is_lazy_linking: bool = false
var is_context_link: bool = false
var is_context_linking : bool = false


func _ready() -> void:
	csf = get_window().content_scale_factor
	popup_menu_item_height = (get_theme_constant("v_separation", "PopupMenu")
		+ get_theme_font_size("font"))

	_setup_colors()
	frame = StyleBoxFlat.new()
	frame.shadow_size = 4
	frame.shadow_color = Color(0, 0, 0, 0.1)
	frame.draw_center = false
	frame.border_color = inactive_color
	frame.corner_detail = get_theme_constant("corner_detail", "MM_LazyLink")
	frame.set_border_width_all(get_theme_constant("border_width", "MM_LazyLink"))
	frame.set_corner_radius_all(get_theme_constant("corner_radius", "MM_LazyLink"))
	frame.set_expand_margin_all(get_theme_constant("expand_margin", "MM_LazyLink"))

	linked_frame = frame.duplicate()
	linked_frame.border_color = active_color

func _setup_colors() -> void:
	inactive_color = get_theme_color("inactive_color", "MM_LazyLink")
	inactive_link_color = get_theme_color("inactive_link_color", "MM_LazyLink")
	active_color = get_theme_color("active_color", "MM_LazyLink")
	active_link_color = get_theme_color("active_link_color", "MM_LazyLink")
	context_color = get_theme_color("context_color", "MM_LazyLink")
	context_link_color = get_theme_color("context_link_color", "MM_LazyLink")

func _draw() -> void:
	if not is_context_linking and source:
		if target:
			if is_context_link:
				_set_colors(inactive_color, context_color,
					context_link_color, context_color)
			else:
				_set_colors(active_color, active_color,
						active_link_color, active_color)
			draw_style_box(linked_frame, source.get_rect())
			draw_style_box(linked_frame, target.get_rect())
		else:
			_set_colors(inactive_color, inactive_color,
					inactive_link_color, inactive_color)
			draw_style_box(frame, source.get_rect())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		end_link(true)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and event.alt_pressed:
				invalidate_link()
				if event.shift_pressed:
					is_context_link = true
				accept_event()
				is_lazy_linking = true
				source = get_parent().get_closest_node_at_point(
						get_local_mouse_position())
				show_node(LazyNode.TO)
				from_point = get_local_mouse_position()
			elif is_lazy_linking or is_context_link:
				end_link()
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT != 0 and is_lazy_linking:
			accept_event()
			target = null
			var closest = get_parent().get_closest_node_at_point(
					get_local_mouse_position())
			if closest != source:
				target = closest
			set_link([from_point, get_local_mouse_position()])
			show_node(LazyNode.FROM)


func _set_colors(frame_color: Color, linked_frame_color: Color,
		link_color: Color, node_color: Color) -> void:
	frame.border_color = frame_color
	linked_frame.border_color = linked_frame_color
	$Link.gradient.colors[LazyNode.FROM] = link_color
	$NodeA.material.set_shader_parameter("node_color", node_color)


func set_link(pts: PackedVector2Array) -> void:
	$Link.points = pts


func end_link(is_cancel: bool = false) -> void:
	$NodeA.hide()
	$NodeB.hide()
	$Link.points = PackedVector2Array()
	if not is_cancel:
		if is_context_link:
			is_context_linking = true
			has_context = true
			create_context_connection()
		else:
			do_lazy_connection()
	if not is_context_linking:
		invalidate_link()
	queue_redraw()


func invalidate_link() -> void:
	source = null
	target = null
	is_context_link = false
	is_lazy_linking = false
	is_context_linking = false
	has_context = false


func show_node(node: LazyNode) -> void:
	var color_rect := $NodeA if node else $NodeB
	color_rect.show()
	color_rect.position = get_local_mouse_position() - Vector2(16, 16) 
	move_to_front()
	queue_redraw()


func port_attr(node: GraphNode, port_idx: int,
		is_output: bool, key: String) -> String:
	if node:
		var defs : Array = (node.generator.get_output_defs()
				if is_output else node.generator.get_input_defs())
		if defs[port_idx].has(key):
			return defs[port_idx][key]
	return ""


func has_input_link(node: GraphNode, port_idx: int) -> bool:
	var graph : GraphEdit = get_parent()
	if graph:
		for c : Dictionary in graph.connections:
			if c.to_port == port_idx and c.to_node == node.name:
				return true
	return false


func connect_port_type(types: Array, allow_any: bool = false) -> bool:
	var graph : GraphEdit = get_parent()
	if not graph:
		return false
	for out_port : int in source.get_output_port_count():
		for in_port : int in target.get_input_port_count():
			if (source.get_output_port_type(out_port) == target.get_input_port_type(in_port)
					and not has_input_link(target, in_port)):
				var link := (port_attr(source, out_port, Port.OUTPUT, "type") + "_" +
					port_attr(target, in_port, Port.INPUT, "type"))
				if allow_any or link in types:
					graph.on_connect_node(source.name, out_port, target.name, in_port)
					return true
	return false


func create_context_menu(is_output: bool, source_output: int = -1) -> void:
	var context_node : GraphNode = source if is_output else target

	# skip context menu if target node only has one input
	if not is_output and context_node.get_input_port_count() == 1:
		do_context_link(0, source_output)
		return

	var popup : PopupMenu = PopupMenu.new()
	popup.add_theme_constant_override(
		"item_%s_padding" % [ "end" if is_output else "start" ], 16)

	if not is_output:
		popup.set_layout_direction(Window.LAYOUT_DIRECTION_RTL)

	var context_port_count : int = (context_node.get_output_port_count()
			if is_output else context_node.get_input_port_count())

	# determine port label
	for i in context_port_count:
		var port_name : String
		for attr : String in ["label", "shortdesc", "name"]:
			port_name = port_attr(context_node, i, is_output, attr)
			# skip positional label if there's nothing in it
			if attr == "label" and port_name.split(":")[0].is_valid_int():
				if port_name.split(":")[1].is_empty():
					continue
			if not port_name.is_empty():
				break
			port_name = " - "
		port_name = tr(port_name)

		var context_port_color : Color = (context_node.get_output_port_color(i)
				if is_output else context_node.get_input_port_color(i))

		var slot_icon : Image = Image.new()
		slot_icon.load_svg_from_buffer(SLOT_SVG.replace("#FFF",
				"#"+context_port_color.to_html(false)).to_utf8_buffer())
		popup.add_icon_item(ImageTexture.create_from_image(slot_icon), port_name)

	popup.content_scale_factor = csf
	popup.close_requested.connect(invalidate_link)
	popup.window_input.connect(popup_window_input)
	popup.popup_hide.connect(popup_hidden.bind(popup))
	popup.set_focused_item(0)

	if source_output != -1:
		popup.id_pressed.connect(do_context_link.bind(source_output))
	else:
		popup.id_pressed.connect(do_context_link.bind(-1 if is_output else 0))

	add_child(popup)
	popup.position = get_screen_transform() * (get_local_mouse_position() -
			Vector2(popup.get_contents_minimum_size().x - 16,
			popup_menu_item_height))

	popup.size = popup.get_contents_minimum_size() * csf
	popup.max_size.y = MAX_POPUP_HEIGHT * int(csf)
	popup.show()


func popup_window_input(event : InputEvent) -> void:
	if event.is_action("ui_cancel"):
		invalidate_link()


func popup_hidden(popup: PopupMenu) -> void:
	if not has_context:
		invalidate_link()
	popup.queue_free()


func create_context_connection() -> void:
	var graph : GraphEdit = get_parent()
	if (source and target and graph
			and source.get_output_port_count()
			and target.get_input_port_count()):
				create_context_menu(source.get_output_port_count() != 1)


func do_context_link(to: int, from: int) -> void:
	if from != -1:
		if (source.get_output_port_type(from) == target.get_input_port_type(to)
				or source.get_output_port_type(from) == 42
				or target.get_input_port_type(to) == 42):	
			get_parent().on_connect_node(source.name, from, target.name, to)
			invalidate_link()
	else:
		create_context_menu(Port.INPUT, to)


# handle lazy connection (alt + rmb)
func do_lazy_connection() -> void:
	var graph : GraphEdit = get_parent()
	if (not (source and target and graph) or
			not (source.get_output_port_count()
			and target.get_input_port_count())
			):
		return

	# connect by exact port name (short description, case-sensitive)
	for out_port : int in source.get_output_port_count():
		for in_port : int in target.get_input_port_count():
			if not has_input_link(target, in_port):
				if (port_attr(source, out_port, Port.OUTPUT, "shortdesc")
					== port_attr(target, in_port, Port.INPUT, "shortdesc")):
					graph.on_connect_node(source.name, out_port, target.name, in_port)
					return

	# connect by exact port type (e.g. float, rgba)
	for out_port : int in source.get_output_port_count():
		for in_port : int in target.get_input_port_count():
			if (port_attr(source, out_port, Port.OUTPUT, "type")
				== port_attr(target, in_port, Port.INPUT, "type")
				and not has_input_link(target, in_port)):
					graph.on_connect_node(source.name, out_port, target.name, in_port)
					return

	# connect color to color type first (i.e. from rgb/rgba)
	for type in [["rgba_rgba", "rgba_rgb", "rgb_rgba"], ["rgb_f"]]:
		if connect_port_type(type):
			return

	# connect by compatible slot type
	if connect_port_type([], true):
		return

	# allow "any" type (i.e. Switch/Reroute) to form connections
	for out_port : int in source.get_output_port_count():
		for in_port : int in target.get_input_port_count():
			if (source.get_output_port_type(out_port) == 42 or
				target.get_input_port_type(in_port) == 42
				and not has_input_link(target, in_port)):
					graph.on_connect_node(source.name, out_port, target.name, in_port)
					return

	# force at least one connection(compatible slot type) even when all slots are used
	for in_port : int in target.get_input_port_count():
		if (source.get_output_port_type(0) == target.get_input_port_type(in_port)
			or source.get_output_port_type(0) == 42
			or target.get_input_port_type(in_port) == 42):
				graph.on_connect_node(source.name, 0, target.name, in_port)
				return
