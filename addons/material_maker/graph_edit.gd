tool
extends GraphEdit
class_name MMGraphEdit

var editor_interface = null
var node_factory = null
var renderer = null

var save_path = null setget set_save_path
var need_save = false

var top_generator = null
var generator = null

onready var timer : Timer = $Timer

onready var subgraph_ui : HBoxContainer = $GraphUI/SubGraphUI

signal save_path_changed
signal graph_changed

func _ready() -> void:
	OS.low_processor_usage_mode = true
	center_view()

func _gui_input(event) -> void:
	if event is InputEventKey and event.pressed:
		var scancode_with_modifiers = event.get_scancode_with_modifiers()
		if scancode_with_modifiers == KEY_DELETE || scancode_with_modifiers == KEY_BACKSPACE:
			remove_selection()

# Misc. useful functions

func get_source(node, port):
	for c in get_connection_list():
		if c.to == node and c.to_port == port:
			return { node=c.from, slot=c.from_port }

func offset_from_global_position(global_position) -> Vector2:
	return (scroll_offset + global_position - rect_global_position) / zoom

func add_node(node) -> void:
	add_child(node)
	node.connect("close_request", self, "remove_node", [ node ])

func connect_node(from, from_slot, to, to_slot):
	if generator.connect_children(get_node(from).generator, from_slot, get_node(to).generator, to_slot):
		var disconnect = get_source(to, to_slot)
		if disconnect != null:
			.disconnect_node(disconnect.node, disconnect.slot, to, to_slot)
		.connect_node(from, from_slot, to, to_slot)
		send_changed_signal()

func disconnect_node(from, from_slot, to, to_slot) -> void:
	if generator.disconnect_children(get_node(from).generator, from_slot, get_node(to).generator, to_slot):
		.disconnect_node(from, from_slot, to, to_slot)
		send_changed_signal()

func on_connections_changed(removed_connections : Array, added_connections : Array) -> void:
	for c in removed_connections:
		.disconnect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
	for c in added_connections:
		.connect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)

func remove_node(node) -> void:
	if generator.remove_generator(node.generator):
		var node_name = node.name
		for c in get_connection_list():
			if c.from == node_name or c.to == node_name:
				disconnect_node(c.from, c.from_port, c.to, c.to_port)
		node.queue_free()
		send_changed_signal()

# Global operations on graph

func update_tab_title() -> void:
	if !get_parent().has_method("set_tab_title"):
		print("no set_tab_title method")
		return
	var title = "[unnamed]"
	if save_path != null:
		title = save_path.right(save_path.rfind("/")+1)
	if need_save:
		title += " *"
	if get_parent().has_method("set_tab_title"):
		get_parent().set_tab_title(get_index(), title)

func set_need_save(ns) -> void:
	if ns != need_save:
		need_save = ns
		update_tab_title()

func set_save_path(path) -> void:
	if path != save_path:
		save_path = path
		update_tab_title()
		emit_signal("save_path_changed", self, path)

func clear_view() -> void:
	clear_connections()
	for c in get_children():
		if c is GraphNode:
			remove_child(c)
			c.free()

# Center view

func center_view() -> void:
	var center = Vector2(0, 0)
	var node_count = 0
	for c in get_children():
		if c is GraphNode:
			center += c.offset + 0.5*c.rect_size
			node_count += 1
	if node_count > 0:
		center /= node_count
		scroll_offset = center - 0.5*rect_size

func update_view(g) -> void:
	if generator != null:
		generator.disconnect("connections_changed", self, "on_connections_changed")
	clear_view()
	generator = g
	if generator != null:
		generator.connect("connections_changed", self, "on_connections_changed")
	update_graph(generator.get_children(), generator.connections)
	subgraph_ui.visible = generator != top_generator
	subgraph_ui.get_node("Label").text = generator.label
	center_view()

func clear_material() -> void:
	if top_generator != null:
		remove_child(top_generator)
		top_generator.free()
		top_generator = null
		generator = null
	send_changed_signal()

func update_graph(generators, connections) -> Array:
	var rv = []
	for g in generators:
		var node = node_factory.create_node(g.get_type())
		if node != null:
			node.name = "node_"+g.name
			add_node(node)
			node.generator = g
		node.offset = g.position
		rv.push_back(node)
	for c in connections:
		.connect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
	return rv

func new_material() -> void:
	clear_material()
	var loader = MMGenLoader.new()
	top_generator = loader.create_gen({nodes=[{name="Material", type="material","parameters":{"size":11}}], connections=[]})
	if top_generator != null:
		add_child(top_generator)
		update_view(top_generator)
		set_save_path(null)
		set_need_save(false)
		center_view()

func get_free_name(type):
	var i = 0
	while true:
		var node_name = type+"_"+str(i)
		if !has_node(node_name):
			return node_name
		i += 1

func create_nodes(data, position : Vector2 = Vector2(0, 0)):
	if data == null:
		return
	if data.has("type"):
		data = { nodes=[data], connections=[] }
	if typeof(data.nodes) == TYPE_ARRAY and typeof(data.connections) == TYPE_ARRAY:
		var new_stuff = MMGenLoader.add_to_gen_graph(generator, data.nodes, data.connections)
		for g in new_stuff.generators:
			g.position += position
		return update_graph(new_stuff.generators, new_stuff.connections)
	return []

func create_gen_from_type(gen_name) -> void:
	create_nodes({ type=gen_name, parameters={} }, scroll_offset+0.5*rect_size)

func load_file(filename) -> void:
	clear_material()
	top_generator = MMGenLoader.load_gen(filename)
	if top_generator != null:
		add_child(top_generator)
		update_view(top_generator)
		set_save_path(filename)
		set_need_save(false)
		center_view()

func save_file(filename) -> void:
	var data = top_generator.serialize()
	var file = File.new()
	if file.open(filename, File.WRITE) == OK:
		file.store_string(JSON.print(data, "\t", true))
		file.close()
	set_save_path(filename)
	set_need_save(false)

func export_textures() -> void:
	if save_path != null:
		var prefix = save_path.left(save_path.rfind("."))
		for c in get_children():
			if c is GraphNode:
				if c.generator.has_method("render_textures"):
					c.generator.render_textures(renderer)
					if c.generator.has_method("export_textures"):
						c.generator.export_textures(prefix, editor_interface)

# Cut / copy / paste

func get_selected_nodes() -> Array:
	var selected_nodes = []
	for n in get_children():
		if n is GraphNode and n.selected:
			selected_nodes.append(n)
	return selected_nodes

func remove_selection() -> void:
	for c in get_children():
		if c is GraphNode and c.selected and c.name != "Material":
			remove_node(c)

# Maybe move this to gen_graph...
func serialize_selection() -> Dictionary:
	var data = { nodes = [], connections = [] }
	var nodes = []
	for c in get_children():
		if c is GraphNode and c.selected and c.name != "Material":
			nodes.append(c)
	if nodes.empty():
		return {}
	var center = Vector2(0, 0)
	for n in nodes:
		center += n.offset+0.5*n.rect_size
	center /= nodes.size()
	for n in nodes:
		var s = n.generator.serialize()
		var p = n.offset-center
		s.node_position = { x=p.x, y=p.y }
		data.nodes.append(s)
	for c in get_connection_list():
		var from = get_node(c.from)
		var to = get_node(c.to)
		if from != null and from.selected and to != null and to.selected:
			var connection = c.duplicate(true)
			connection.from = from.generator.name
			connection.to = to.generator.name
			data.connections.append(connection)
	return data

func can_copy() -> bool:
	for c in get_children():
		if c is GraphNode and c.selected and c.name != "Material":
			return true
	return false

func cut() -> void:
	copy()
	remove_selection()

func copy() -> void:
	OS.clipboard = to_json(serialize_selection())

func paste(pos = Vector2(0, 0)) -> void:
	for c in get_children():
		if c is GraphNode:
			c.selected = false
	var data = parse_json(OS.clipboard)
	var new_nodes = create_nodes(data, scroll_offset+0.5*rect_size)
	if new_nodes != null:
		for c in new_nodes:
			c.selected = true

# Delay after graph update

func send_changed_signal() -> void:
	set_need_save(true)
	timer.start(0.1)

func do_send_changed_signal() -> void:
	emit_signal("graph_changed")

# Drag and drop

func can_drop_data(position, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and (data.has('type') or (data.has('nodes') and data.has('connections')))

func drop_data(position, data) -> void:
	# The following mitigates the SpinBox problem (captures mouse while dragging)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	create_nodes(data, offset_from_global_position(get_global_transform().xform(position)))

func on_ButtonUp_pressed() -> void:
	if generator != top_generator && generator.get_parent() is MMGenGraph:
		call_deferred("update_view", generator.get_parent())

func _on_Label_text_changed(new_text) -> void:
	generator.label = new_text

# Create subgraph

func create_subgraph() -> void:
	var generators = []
	for n in get_selected_nodes():
		generators.push_back(n.generator)
	generator.create_subgraph(generators)
	update_view(generator)

func _on_ButtonShowTree_pressed() -> void:
	var graph_tree : Popup = preload("res://addons/material_maker/widgets/graph_tree/graph_tree.tscn").instance()
	graph_tree.init("Top", top_generator)
	add_child(graph_tree)
	graph_tree.connect("item_double_clicked", self, "edit_subgraph")
	graph_tree.popup_centered()

func edit_subgraph(g : MMGenGraph) -> void:
	if !g.is_editable():
		g.toggle_editable()
	update_view(g)
