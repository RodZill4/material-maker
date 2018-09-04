tool
extends GraphEdit

var editor_interface = null
var renderer = null

var save_path = null
var need_save = false

signal save_path_changed
signal graph_changed

func _ready():
	OS.low_processor_usage_mode = true
	center_view()

func _gui_input(event):
	if event is InputEventKey and event.pressed:
		var scancode_with_modifiers = event.get_scancode_with_modifiers()
		if scancode_with_modifiers == KEY_C:
			center_view()
		elif scancode_with_modifiers == KEY_DELETE:
			remove_selection()

# Misc. useful functions

func get_source(node, port):
	for c in get_connection_list():
		if c.to == node && c.to_port == port:
			return { node=c.from, slot=c.from_port }

func offset_from_global_position(global_position):
	return (scroll_offset + global_position - rect_global_position) / zoom

func add_node(node):
	add_child(node)
	node.connect("close_request", self, "remove_node", [ node ])

func connect_node(from, from_slot, to, to_slot):
	var source_list = [ from ]
	# Check if the new connection creates a cycle in the graph
	while !source_list.empty():
		var source = source_list.pop_front()
		if source == to:
			#print("cannot connect %s to %s (%s)" % [from, to, source])
			return false
		for c in get_connection_list():
			if c.to == source and source_list.find(c.from) == -1:
				source_list.append(c.from)
	var disconnect = get_source(to, to_slot)
	if disconnect != null:
		.disconnect_node(disconnect.node, disconnect.slot, to, to_slot)
	.connect_node(from, from_slot, to, to_slot)
	send_changed_signal()
	return true

func disconnect_node(from, from_slot, to, to_slot):
	.disconnect_node(from, from_slot, to, to_slot)
	send_changed_signal();

func remove_node(node):
	var node_name = node.name
	for c in get_connection_list():
		if c.from == node_name or c.to == node_name:
			disconnect_node(c.from, c.from_port, c.to, c.to_port)
			send_changed_signal()
	node.queue_free()

# Global operations on graph

func update_tab_title():
	if !get_parent().has_method("set_tab_title"):
		return
	var title = "[unnamed]"
	if save_path != null:
		title = save_path.right(save_path.rfind("/")+1)
	if need_save:
		title += " *"
	if get_parent().has_method("set_tab_title"):
		get_parent().set_tab_title(get_index(), title)

func set_need_save(ns):
	if ns != need_save:
		need_save = ns
		update_tab_title()

func set_save_path(path):
	if path != save_path:
		save_path = path
		update_tab_title()
		emit_signal("save_path_changed", self, path)

func clear_material():
	clear_connections()
	for c in get_children():
		if c is GraphNode:
			remove_child(c)
			c.free()
	send_changed_signal()

func new_material():
	clear_material()
	create_node({name="Material", type="material"})
	set_save_path(null)
	center_view()

func get_free_name(type):
	var i = 0
	while true:
		var node_name = type+"_"+str(i)
		if !has_node(node_name):
			return node_name
		i += 1

func create_nodes(data, position = null):
	if data == null:
		return
	if data.has("type"):
		var node_type = load("res://addons/material_maker/nodes/"+data.type+".tscn")
		if node_type != null:
			var node = node_type.instance()
			if data.has("name") && !has_node(data.name):
				node.name = data.name
			else:
				node.name = get_free_name(data.type)
			add_node(node)
			node.deserialize(data)
			if position != null:
				node.offset += position
			send_changed_signal()
			return node
	else:
		if typeof(data.nodes) == TYPE_ARRAY and typeof(data.connections) == TYPE_ARRAY:
			var names = {}
			for c in data.nodes:
				var node = create_nodes(c, position)
				if node != null:
					names[c.name] = node.name
					node.selected = true
			for c in data.connections:
				connect_node(names[c.from], c.from_port, "Material" if c.to == "Material" else names[c.to], c.to_port)
	return null

func load_file():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.ptex;Procedural textures file")
	dialog.connect("file_selected", self, "do_load_file")
	dialog.popup_centered()

func do_load_file(filename):
	var file = File.new()
	if file.open(filename, File.READ) != OK:
		return
	var data = parse_json(file.get_as_text())
	file.close()
	clear_material()
	for n in data.nodes:
		var node = create_nodes(n)
	for c in data.connections:
		connect_node(c.from, c.from_port, c.to, c.to_port)
	set_save_path(filename)
	set_need_save(false)
	center_view()

func save_file():
	if save_path != null:
		do_save_file(save_path)
	else:
		save_file_as()
	
func save_file_as():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.ptex;Procedural textures file")
	dialog.connect("file_selected", self, "do_save_file")
	dialog.popup_centered()

func do_save_file(filename):
	var data = { nodes = [] }
	for c in get_children():
		if c is GraphNode:
			data.nodes.append(c.serialize())
	data.connections = get_connection_list()
	var file = File.new()
	if file.open(filename, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()
	set_save_path(filename)
	set_need_save(false)

func export_textures(size = null):
	if save_path != null:
		var prefix = save_path.left(save_path.rfind("."))
		for c in get_children():
			if c is GraphNode && c.has_method("export_textures"):
				c.export_textures(prefix, size)

# Cut / copy / paste

func remove_selection():
	for c in get_children():
		if c is GraphNode and c.selected && c.name != "Material":
			remove_node(c)

func serialize_selection():
	var data = { nodes = [], connections = [] }
	var nodes = []
	for c in get_children():
		if c is GraphNode and c.selected && c.name != "Material":
			nodes.append(c)
	if nodes.empty():
		return null
	var center = Vector2(0, 0)
	for n in nodes:
		center += n.offset+0.5*n.rect_size
	center /= nodes.size()
	for n in nodes:
		var s = n.serialize()
		var p = n.offset-center
		s.node_position = { x=p.x, y=p.y }
		data.nodes.append(s)
	for c in get_connection_list():
		var from = get_node(c.from)
		var to = get_node(c.to)
		if from != null and from.selected and to != null and to.selected:
			data.connections.append(c)
	return data

func can_copy():
	for c in get_children():
		if c is GraphNode and c.selected && c.name != "Material":
			return true
	return false

func cut():
	copy()
	remove_selection()

func copy():
	OS.clipboard = to_json(serialize_selection())

func paste(pos = Vector2(0, 0)):
	for c in get_children():
		if c is GraphNode:
			c.selected = false
	var data = parse_json(OS.clipboard)
	create_nodes(data, scroll_offset+0.5*rect_size)

# Center view

func center_view():
	var center = Vector2(0, 0)
	var node_count = 0
	for c in get_children():
		if c is GraphNode:
			center += c.offset + 0.5*c.rect_size
			node_count += 1
	if node_count > 0:
		center /= node_count
		scroll_offset = center - 0.5*rect_size

# Delay after graph update

func send_changed_signal():
	set_need_save(true)
	$Timer.start()

func do_send_changed_signal():
	emit_signal("graph_changed")

# Drag and drop

func can_drop_data(position, data):
	return typeof(data) == TYPE_DICTIONARY and (data.has('type') or (data.has('nodes') and data.has('connections')))

func drop_data(position, data):
	# The following mitigates the SpinBox problem (captures mouse while dragging)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	create_nodes(data, offset_from_global_position(get_global_transform().xform(position)))
	return true
