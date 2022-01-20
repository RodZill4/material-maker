extends GraphEdit
class_name MMGraphEdit


class Preview:
	var generator
	var output_index : int
	
	func _init(g, i : int = 0):
		generator = g
		output_index = i


export(String, MULTILINE) var shader_context_defs : String = ""

var node_factory = null

var save_path = null setget set_save_path
var need_save : bool = false
var need_save_crash_recovery : bool = false

var top_generator = null
var generator = null

const PREVIEW_COUNT = 2
var current_preview : Array = [ null, null ]
var locked_preview : Array = [ null, null ]

onready var node_popup = get_node("/root/MainWindow/AddNodePopup")
onready var library_manager = get_node("/root/MainWindow/NodeLibraryManager")
onready var timer : Timer = $Timer

onready var subgraph_ui : HBoxContainer = $GraphUI/SubGraphUI
onready var button_transmits_seed : Button = $GraphUI/SubGraphUI/ButtonTransmitsSeed

onready var undoredo = $UndoRedo
var undoredo_move_node_selection_changed : bool = true

signal save_path_changed
signal graph_changed
signal view_updated
signal preview_changed



func _ready() -> void:
	OS.low_processor_usage_mode = true
	center_view()
	for t in range(41):
		add_valid_connection_type(t, 42)
		add_valid_connection_type(42, t)

func get_project_type() -> String:
	return "material"

func get_graph_edit():
	return self

func do_zoom(factor : float):
	accept_event()
	var old_zoom : float = zoom
	zoom *= factor
	var position = offset_from_global_position(get_global_transform().xform(get_local_mouse_position()))
	call_deferred("set_scroll_ofs", scroll_offset+((zoom/old_zoom)-1.0)*old_zoom*position)

var port_click_node : GraphNode
var port_click_port_index : int = -1

func process_port_click(pressed : bool):
	for c in get_children():
		if c is GraphNode:
			var rect : Rect2 = c.get_global_rect()
			var pos = get_global_mouse_position()-rect.position
			rect = Rect2(rect.position, rect.size*c.get_global_transform().get_scale())
			var output_count : int = c.get_connection_output_count()
			if rect.has_point(get_global_mouse_position()) and output_count > 0:
				var scale = c.get_global_transform().get_scale()
				var output_1 : Vector2 = c.get_connection_output_position(0)-5*scale
				var output_2 : Vector2 = c.get_connection_output_position(output_count-1)+5*scale
				var in_output : bool = Rect2(output_1, output_2-output_1).has_point(pos)
				if in_output:
					for i in range(output_count):
						if (c.get_connection_output_position(i)-pos).length() < 5*scale.x:
							if pressed:
								port_click_node = c
								port_click_port_index = i
							elif port_click_node == c and port_click_port_index == i:
								set_current_preview(1 if Input.is_key_pressed(KEY_SHIFT) else 0, port_click_node, port_click_port_index, Input.is_key_pressed(KEY_CONTROL))
								port_click_port_index = -1
							return

func _gui_input(event) -> void:
	if (
		event.is_action_pressed("ui_library_popup")
		and not Input.is_key_pressed(KEY_CONTROL)
		and get_global_rect().has_point(get_global_mouse_position())
	):
		# Only popup the UI library if Ctrl is not pressed to avoid conflicting
		# with the Ctrl + Space shortcut.
		node_popup.rect_global_position = get_global_mouse_position()
		node_popup.show_popup()
	elif event.is_action_pressed("ui_hierarchy_up"):
		on_ButtonUp_pressed()
	elif event.is_action_pressed("ui_hierarchy_down"):
		var selected_nodes = get_selected_nodes()
		if selected_nodes.size() == 1 and selected_nodes[0].generator is MMGenGraph:
			update_view(selected_nodes[0].generator)
	elif event is InputEventMouseButton:
		# reverted to default GraphEdit behavior
		if false and event.button_index == BUTTON_WHEEL_UP and event.is_pressed():
			if event.control:
				event.control = false
			elif !event.shift:
				event.control = true
				do_zoom(1.1)
		elif false and event.button_index == BUTTON_WHEEL_DOWN and event.is_pressed():
			if event.control:
				event.control = false
			elif !event.shift:
				event.control = true
				do_zoom(1.0/1.1)
		elif event.button_index == BUTTON_RIGHT and event.is_pressed():
			for c in get_children():
				if ! c is GraphNode:
					continue
				var rect = c.get_global_rect()
				rect = Rect2(rect.position, rect.size*c.get_global_transform().get_scale())
				if rect.has_point(get_global_mouse_position()):
					if c.has_method("get_input_slot"):
						var slot = c.get_input_slot(get_global_mouse_position()-c.rect_global_position)
						if slot >= 0:
							# Tell the node its connector was clicked
							if c.has_method("on_clicked_input"):
								c.on_clicked_input(slot, Input.is_key_pressed(KEY_SHIFT))
								return
					if c.has_method("get_output_slot"):
						var slot = c.get_output_slot(get_global_mouse_position()-c.rect_global_position)
						if slot >= 0:
							# Tell the node its connector was clicked
							if c.has_method("on_clicked_output"):
								c.on_clicked_output(slot, Input.is_key_pressed(KEY_SHIFT))
								return
			# Only popup the UI library if Ctrl is not pressed to avoid conflicting
			# with the Ctrl + Space shortcut.
			node_popup.rect_global_position = get_global_mouse_position()
			node_popup.show_popup()
		else:
			if event.button_index == BUTTON_LEFT:
				process_port_click(event.is_pressed())
			call_deferred("check_previews")
	elif event is InputEventKey and event.pressed:
		var scancode_with_modifiers = event.get_scancode_with_modifiers()
		if scancode_with_modifiers == KEY_DELETE or scancode_with_modifiers == KEY_BACKSPACE:
			remove_selection()
	elif event is InputEventMouseMotion:
		for c in get_children():
			if c.has_method("get_slot_tooltip"):
				var rect = c.get_global_rect()
				rect = Rect2(rect.position, rect.size*c.get_global_transform().get_scale())
				if rect.has_point(get_global_mouse_position()):
					hint_tooltip = c.get_slot_tooltip(get_global_mouse_position()-c.rect_global_position)
				else:
					c.clear_connection_labels()

# Misc. useful functions
func get_source(node, port) -> Dictionary:
	for c in get_connection_list():
		if c.to == node and c.to_port == port:
			return { node=c.from, slot=c.from_port }
	return {}

func offset_from_global_position(global_position) -> Vector2:
	return (scroll_offset + global_position - rect_global_position) / zoom

func add_node(node) -> void:
	add_child(node)
	move_child(node, 0)
	node.connect("close_request", self, "remove_node", [ node ])

func connect_node(from : String, from_slot : int, to : String, to_slot : int):
	var from_node : MMGraphNodeMinimal = get_node(from)
	var to_node : MMGraphNodeMinimal = get_node(to)
	var connect_count = 1
	var connected : bool = false
	var out_ports = from_node.generator.get_output_defs()
	var in_ports = to_node.generator.get_input_defs()
	if out_ports[from_slot].has("group_size") and in_ports[to_slot].has("group_size") and out_ports[from_slot].group_size == in_ports[to_slot].group_size:
		connect_count = out_ports[from_slot].group_size
	var connect_list : Array = []
	var disconnect_list : Array = []
	for i in range(connect_count):
		if generator.connect_children(from_node.generator, from_slot+i, to_node.generator, to_slot+i):
			var disconnect = get_source(to, to_slot+i)
			if !disconnect.empty():
				.disconnect_node(disconnect.node, disconnect.slot, to, to_slot+i)
				disconnect_list.push_back({from=get_node(disconnect.node).generator.name, from_port=disconnect.slot, to=get_node(to).generator.name, to_port=to_slot+i})
			.connect_node(from, from_slot+i, to, to_slot+i)
			connect_list.push_back({from=get_node(from).generator.name, from_port=from_slot+i, to=get_node(to).generator.name, to_port=to_slot+i})
			connected = true
	if connected:
		var generator_hier_name : String = generator.get_hier_name()
		var undo_actions = [
			{ type="remove_connections", parent=generator_hier_name, connections=connect_list },
			{ type="add_to_graph", parent=generator_hier_name, generators=[], connections=disconnect_list }
		]
		var redo_actions = [
			{ type="remove_connections", parent=generator_hier_name, connections=disconnect_list },
			{ type="add_to_graph", parent=generator_hier_name, generators=[], connections=connect_list }
		]
		undoredo.add("Connect nodes", undo_actions, redo_actions)
		send_changed_signal()
		for n in [ from_node, to_node ]:
			if n.has_method("on_connections_changed"):
				n.on_connections_changed()

func do_disconnect_node(from : String, from_slot : int, to : String, to_slot : int) -> bool:
	var from_node : MMGraphNodeMinimal = get_node(from)
	var to_node : MMGraphNodeMinimal = get_node(to)
	var from_gen = from_node.generator
	var to_gen = to_node.generator
	if generator.disconnect_children(from_gen, from_slot, to_gen, to_slot):
		.disconnect_node(from, from_slot, to, to_slot)
		send_changed_signal()
		for n in [ from_node, to_node ]:
			if n.has_method("on_connections_changed"):
				n.on_connections_changed()
		return true
	return false

func disconnect_node(from : String, from_slot : int, to : String, to_slot : int) -> void:
	var from_gen = get_node(from).generator
	var to_gen = get_node(to).generator
	if do_disconnect_node(from, from_slot, to, to_slot):
		var generator_hier_name : String = generator.get_hier_name()
		var connection = {from=from_gen.name, from_port=from_slot, to=to_gen.name, to_port=to_slot}
		var undo_actions = [
			{ type="add_to_graph", parent=generator_hier_name, generators=[], connections=[connection] }
		]
		var redo_actions = [
			{ type="remove_connections", parent=generator_hier_name, connections=[connection] }
		]
		undoredo.add("Disconnect nodes", undo_actions, redo_actions)

func on_connections_changed(removed_connections : Array, added_connections : Array) -> void:
	for c in removed_connections:
		.disconnect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
	for c in added_connections:
		.connect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)

func remove_node(node) -> void:
	var prev = generator.serialize()
	do_remove_node(node)
	var next = generator.serialize()
	undoredo_create_step("Delete node", generator.get_hier_name(), prev, next)

func do_remove_node(node) -> void:
	for i in PREVIEW_COUNT:
		if current_preview[i] != null and node.generator == current_preview[i].generator:
			set_current_preview(i, null)
		if locked_preview[i] != null and node.generator == locked_preview[i].generator:
			set_current_preview(i, null, 0, true)
	if generator.remove_generator(node.generator):
		var node_name = node.name
		for c in get_connection_list():
			if c.from == node_name or c.to == node_name:
				do_disconnect_node(c.from, c.from_port, c.to, c.to_port)
		remove_child(node)
		node.queue_free()
		send_changed_signal()

# Global operations on graph

func update_tab_title() -> void:
	if !get_parent().has_method("set_tab_title"):
		#print("no set_tab_title method")
		return
	var title = "[unnamed]"
	if save_path != null:
		title = save_path.right(save_path.rfind("/")+1)
	if need_save:
		title += " *"
	if get_parent().has_method("set_tab_title"):
		get_parent().set_tab_title(get_index(), title)

func set_need_save(ns = true) -> void:
	if ns != need_save:
		need_save = ns
		update_tab_title()
	if save_path != null:
		if ns:
			need_save_crash_recovery = true
		else:
			need_save_crash_recovery = false

func set_save_path(path) -> void:
	if path != save_path:
		remove_crash_recovery_file()
		need_save_crash_recovery = false
		save_path = path
		update_tab_title()
		emit_signal("save_path_changed", self, path)

func clear_view() -> void:
	clear_connections()
	for c in get_children():
		if c is GraphNode:
			remove_child(c)
			c.free()

# crash_recovery

func crash_recovery_save() -> void:
	if !need_save_crash_recovery:
		return
	var data = top_generator.serialize()
	var file = File.new()
	if file.open(save_path+".mmcr", File.WRITE) == OK:
		file.store_string(JSON.print(data))
		file.close()
		need_save_crash_recovery = false

func remove_crash_recovery_file() -> void:
	if save_path != null:
		var dir = Directory.new()
		dir.remove(save_path+".mmcr")

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
	if generator != null and is_instance_valid(generator):
		generator.disconnect("connections_changed", self, "on_connections_changed")
	clear_view()
	generator = g
	if generator != null:
		generator.connect("connections_changed", self, "on_connections_changed")
	update_graph(generator.get_children(), generator.connections)
	subgraph_ui.visible = generator != top_generator
	subgraph_ui.get_node("Label").text = generator.label
	$GraphUI/SubGraphUI/Description.short_description = generator.shortdesc
	$GraphUI/SubGraphUI/Description.long_description = generator.longdesc
	$GraphUI/SubGraphUI/Description.update_tooltip()
	center_view()
	if generator.get_parent() is MMGenGraph:
		button_transmits_seed.visible = true
		button_transmits_seed.pressed = generator.transmits_seed
	else:
		button_transmits_seed.visible = false
	emit_signal("view_updated", generator)


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
		var node = node_factory.create_node(g)
		if node != null:
			node.name = "node_"+g.name
			add_node(node)
			node.generator = g
		node.do_set_position(g.position)
		rv.push_back(node)
	for c in connections:
		.connect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
	return rv

func new_material(init_nodes = {nodes=[{name="Material", type="material","parameters":{"size":11}}], connections=[]}) -> void:
	clear_material()
	top_generator = mm_loader.create_gen(init_nodes)
	if top_generator != null:
		add_child(top_generator)
		move_child(top_generator, 0)
		update_view(top_generator)
		center_view()
		set_save_path(null)
		set_need_save(false)

func get_free_name(type) -> String:
	var i = 0
	while true:
		var node_name = type+"_"+str(i)
		if !has_node(node_name):
			return node_name
		i += 1
	return ""

func do_create_nodes(data, position : Vector2 = Vector2(0, 0)) -> Array:
	if !data is Dictionary:
		return []
	if data.has("type"):
		data = { nodes=[data], connections=[] }
	if data.has("nodes") and typeof(data.nodes) == TYPE_ARRAY and data.has("connections") and typeof(data.connections) == TYPE_ARRAY:
		var new_stuff = mm_loader.add_to_gen_graph(generator, data.nodes, data.connections, position)
		var return_value = update_graph(new_stuff.generators, new_stuff.connections)
		return return_value
	return []

func create_nodes(data, position : Vector2 = Vector2(0, 0)) -> Array:
	var prev = generator.serialize()
	var nodes = do_create_nodes(data, position)
	if !nodes.empty():
		var next = generator.serialize()
		undoredo_create_step("Add and connect nodes", generator.get_hier_name(), prev, next)
	return nodes

func create_gen_from_type(gen_name) -> void:
	create_nodes({ type=gen_name, parameters={} }, scroll_offset+0.5*rect_size)

func set_new_generator(new_generator) -> void:
	clear_material()
	top_generator = new_generator
	add_child(top_generator)
	move_child(top_generator, 0)
	update_view(top_generator)
	center_view()
	set_need_save(false)

func find_buffers(g) -> int:
	if g is MMGenBuffer:
		return 1
	var rv = 0
	for c in g.get_children():
		rv += find_buffers(c)
	return rv

func load_file(filename) -> bool:
	var rescued = false
	var new_generator = null
	var file = File.new()
	if filename != null and file.file_exists(filename+".mmcr"):
		var dialog = preload("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instance()
		dialog.dialog_text = "Rescue file for "+filename.get_file()+" was found.\nLoad it?"
		dialog.get_ok().text = "Rescue"
		dialog.add_cancel("Load "+filename.get_file())
		add_child(dialog)
		var result = dialog.ask()
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == "ok":
			new_generator = mm_loader.load_gen(filename+".mmcr")
	if new_generator != null:
		rescued = true
	else:
		new_generator = mm_loader.load_gen(filename)
	if new_generator != null:
		set_save_path(filename)
		set_new_generator(new_generator)
		if rescued:
			set_need_save(true)
		#print("Material has %d buffers" % find_buffers(new_generator))
		return true
	else:
		var dialog : AcceptDialog = AcceptDialog.new()
		add_child(dialog)
		dialog.window_title = "Load failed!"
		dialog.dialog_text = "Failed to load "+filename
		dialog.connect("popup_hide", dialog, "queue_free")
		dialog.popup_centered()
		return false

# Save

func save() -> bool:
	var status = false
	if save_path != null:
		status = save_file(save_path)
	else:
		status = save_as()
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
	return status

func save_as() -> bool:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.ptex;Procedural Textures File")
	var main_window = get_node("/root/MainWindow")
	if main_window.config_cache.has_section_key("path", "project"):
		dialog.current_dir = main_window.config_cache.get_value("path", "project")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		if save_file(files[0]):
			main_window.add_recent(save_path)
			main_window.config_cache.set_value("path", "project", save_path.get_base_dir())
			return true
	return false

func save_file(filename) -> bool:
	mm_loader.current_project_path = filename.get_base_dir()
	var data = top_generator.serialize()
	mm_loader.current_project_path = ""
	var file = File.new()
	if file.open(filename, File.WRITE) == OK:
		file.store_string(JSON.print(data, "\t", true))
		file.close()
	else:
		return false
	set_save_path(filename)
	set_need_save(false)
	remove_crash_recovery_file()
	return true

# Export

func get_material_node() -> MMGenMaterial:
	for g in top_generator.get_children():
		if g.has_method("get_export_profiles"):
			return g
	return null

func export_material(export_prefix, profile) -> void:
	for g in top_generator.get_children():
		if g.has_method("export_material"):
			var result = g.export_material(export_prefix, profile)
			while result is GDScriptFunctionState:
				result = yield(result, "completed")


# Cut / copy / paste / duplicate

func get_selected_nodes() -> Array:
	var selected_nodes = []
	for n in get_children():
		if n is GraphNode and n.selected:
			selected_nodes.append(n)
	return selected_nodes

func remove_selection() -> void:
	var prev = generator.serialize()
	for c in get_children():
		if c is GraphNode and c.selected and c.name != "Material" and c.name != "Brush":
			do_remove_node(c)
	var next = generator.serialize()
	undoredo_create_step("Delete nodes", generator.get_hier_name(), prev, next)

# Maybe move this to gen_graph...
func serialize_selection(nodes = []) -> Dictionary:
	var data = { nodes = [], connections = [] }
	if nodes.empty():
		for c in get_children():
			if c is GraphNode and c.selected and c.name != "Material" and c.name != "Brush":
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
		if c is GraphNode and c.selected and c.name != "Material" and c.name != "Brush":
			return true
	return false

func cut() -> void:
	copy()
	remove_selection()

func copy() -> void:
	OS.clipboard = to_json(serialize_selection())

func do_paste(data) -> void:
	var position = scroll_offset+0.5*rect_size
	if Rect2(Vector2(0, 0), rect_size).has_point(get_local_mouse_position()):
		position = offset_from_global_position(get_global_transform().xform(get_local_mouse_position()))
	for c in get_children():
		if c is GraphNode:
			c.selected = false
	var new_nodes = create_nodes(data, position)
	if new_nodes != null:
		for c in new_nodes:
			c.selected = true

func paste() -> void:
	var data = OS.clipboard.strip_edges()
	var graph = null
	if data.is_valid_html_color():
		var color = Color(data)
		graph = {type="uniform", color={ r=color.r, g=color.g, b=color.b, a=color.a }}
	elif data.left(4) == "http":
		var http_request = HTTPRequest.new()
		add_child(http_request)
		var error = http_request.request(data)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		data = yield(http_request, "request_completed")[3].get_string_from_utf8()
		http_request.queue_free()
		graph = parse_json(data)
	else:
		graph = parse_json(data)
	if graph != null:
		if graph is Dictionary and graph.has("type") and graph.type == "graph":
			var main_window = get_node("/root/MainWindow")
			var graph_edit = main_window.new_panel()
			var new_generator = mm_loader.create_gen(graph)
			if new_generator:
				graph_edit.set_new_generator(new_generator)
				main_window.hierarchy.update_from_graph_edit(graph_edit)
		else:
			do_paste(graph)
	else:
		print(data)

func duplicate_selected() -> void:
	do_paste(serialize_selection())

func select_all() -> void:
	for c in get_children():
		if c is GraphNode:
			c.selected = true

func select_none() -> void:
	for c in get_children():
		if c is GraphNode:
			c.selected = false

func select_invert() -> void:
	for c in get_children():
		if c is GraphNode:
			c.selected = not c.selected

# Delay after graph update

func send_changed_signal() -> void:
	set_need_save(true)
	timer.stop()
	timer.start(0.2)

func do_send_changed_signal() -> void:
	emit_signal("graph_changed")

# Drag and drop

func can_drop_data(_position, data) -> bool:
	return typeof(data) == TYPE_COLOR or typeof(data) == TYPE_DICTIONARY and (data.has('type') or (data.has('nodes') and data.has('connections')))

func drop_data(position, data) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.has("tree_item"):
		get_node("/root/MainWindow/NodeLibraryManager").item_created(data.tree_item)
	# The following mitigates the SpinBox problem (captures mouse while dragging)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if typeof(data) == TYPE_COLOR:
		do_paste({type="uniform", color={ r=data.r, g=data.g, b=data.b, a=data.a }})
	elif typeof(data) == TYPE_DICTIONARY and data.has("type") and data.type == "Gradient" and data.has("points"):
		do_paste({type="colorize", gradient=data})
	else:
		create_nodes(data, offset_from_global_position(get_global_transform().xform(position)))

func on_ButtonUp_pressed() -> void:
	if generator != top_generator and generator.get_parent() is MMGenGraph:
		call_deferred("update_view", generator.get_parent())

func _on_Label_text_changed(new_text) -> void:
	generator.set_type_name(new_text)

# Create subgraph

func create_subgraph() -> void:
	var generators = []
	for n in get_selected_nodes():
		generators.push_back(n.generator)
	var prev = generator.serialize()
	var subgraph = generator.create_subgraph(generators)
	var next = generator.serialize()
	undoredo_create_step("Create subgraph", generator.get_hier_name(), prev, next)
	if subgraph != null:
		update_view(subgraph)


func _on_ButtonShowTree_pressed() -> void:
	var graph_tree : Popup = preload("res://material_maker/widgets/graph_tree/graph_tree.tscn").instance()
	add_child(graph_tree)
	graph_tree.init("Top", top_generator)
	graph_tree.connect("item_double_clicked", self, "edit_subgraph")
	graph_tree.connect("popup_hide", graph_tree, "queue_free")
	graph_tree.popup_centered()

func edit_subgraph(g : MMGenGraph) -> void:
	if !g.is_editable():
		g.toggle_editable()
	update_view(g)

func _on_ButtonTransmitsSeed_toggled(button_pressed) -> void:
	if button_pressed != generator.transmits_seed:
		generator.transmits_seed = button_pressed

# Node selection

var highlighting_connections : bool = false

func highlight_connections() -> void:
	if highlighting_connections:
		return
	highlighting_connections = true
	while Input.is_mouse_button_pressed(BUTTON_LEFT):
		yield(get_tree(), "idle_frame")
	for c in get_connection_list():
		set_connection_activity(c.from, c.from_port, c.to, c.to_port, 1.0 if get_node(c.from).selected or get_node(c.to).selected else 0.0)
	highlighting_connections = false

func _on_GraphEdit_node_selected(node : GraphNode) -> void:
	if node.comment:
		for c in get_children():
			if c is GraphNode and c != node and node.get_rect().encloses(c.get_rect()):
				c.selected = true
	else:
		highlight_connections()
		yield(get_tree(), "idle_frame")
		if current_preview[0] != null:
			for n in get_selected_nodes():
				if n.generator == current_preview[0].generator:
					return
		set_current_preview(0, node)
	undoredo_move_node_selection_changed = true

func _on_GraphEdit_node_unselected(_node):
	highlight_connections()
	undoredo_move_node_selection_changed = true

func get_current_preview(slot : int = 0):
	if locked_preview[slot] != null:
		return locked_preview[slot]
	return current_preview[slot]

func set_current_preview(slot : int, node, output_index : int = 0, locked = false) -> void:
	var preview = null
	var old_preview = null
	var old_locked_preview = null
	if node != null:
		preview = Preview.new(node.generator, output_index)
	if locked:
		if node != null and locked_preview[slot] != null and locked_preview[slot].generator != node.generator:
			old_locked_preview = locked_preview[slot].generator
		if locked_preview[slot] != null and preview != null and locked_preview[slot].generator == preview.generator and locked_preview[slot].output_index == preview.output_index:
			locked_preview[slot] = null
		else:
			locked_preview[slot] = preview
	else:
		if node != null and current_preview[slot] != null and current_preview[slot].generator != node.generator:
			old_preview = current_preview[slot].generator
		current_preview[slot] = preview
	emit_signal("preview_changed", self)
	if node != null:
		node.update()
	if old_preview != null or old_locked_preview != null:
		for c in get_children():
			if c is GraphNode and (c.generator == old_preview or c.generator == old_locked_preview):
				c.update()

func request_popup(node_name : String , slot_index : int, _release_position : Vector2, connect_output : bool) -> void:
	# Check if the connector was actually  dragged
	var node : GraphNode = get_node(node_name)
	if node == null:
		return
	# Request the popup
	node_popup.rect_global_position = get_global_mouse_position()
	var slot_type
	if connect_output:
		slot_type = mm_io_types.types[node.generator.get_input_defs()[slot_index].type].slot_type
	else:
		slot_type = mm_io_types.types[node.generator.get_output_defs()[slot_index].type].slot_type
	node_popup.show_popup(node_name, slot_index, slot_type, connect_output)

func check_previews() -> void:
	var preview_changed : bool = false
	for i in PREVIEW_COUNT:
		if current_preview[i] != null and ! is_instance_valid(current_preview[i].generator):
			current_preview[i] = null
			preview_changed = true
		if locked_preview[i] != null and ! is_instance_valid(locked_preview[i].generator):
			locked_preview[i] = null
			preview_changed = true
	if preview_changed:
		emit_signal("preview_changed", self)

func on_drop_image_file(file_name : String) -> void:
	do_paste({type="image", image=file_name})


func _on_Description_descriptions_changed(short_description, long_description):
	generator.shortdesc = short_description
	generator.longdesc = long_description


# Undo/Redo

func get_node_from_hier_name(hier_path : String, return_closest = false):
	var node : Node = top_generator
	if hier_path != "":
		for n in hier_path.split("/"):
			if not node.has_node(n):
				if return_closest:
					return node
				else:
					return null
			node = node.get_node(n)
	return node

func undoredo_pre():
	return generator.get_hier_name()

func undoredo_post(pre_returnvalue) -> void:
	var current_node = get_node_from_hier_name(pre_returnvalue)
	if current_node == null:
		current_node = get_node_from_hier_name(pre_returnvalue, true)
		update_view(current_node)

func undoredo_command(command : Dictionary) -> void:
	match command.type:
		"add_to_graph":
			var parent_generator = get_node_from_hier_name(command.parent)
			var position : Vector2 = command.position if command.has("position") else Vector2(0, 0)
			var generators = command.generators if command.has("generators") else []
			var connections = command.connections if command.has("connections") else []
			var new_stuff = mm_loader.add_to_gen_graph(parent_generator, generators, connections, position)
			if generator == parent_generator:
				var actions : Array = []
				for g in new_stuff.generators:
					actions.append({ action="add_node", node=g.name })
				for c in new_stuff.connections:
					actions.append({ action="add_connection", connection=c })
				update_graph(new_stuff.generators, new_stuff.connections)
		"remove_connections":
			var parent_generator = get_node_from_hier_name(command.parent)
			for c in command.connections:
				parent_generator.disconnect_children_by_name(c.from, c.from_port, c.to, c.to_port)
			if generator == parent_generator:
				for c in command.connections:
					.disconnect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
		"remove_generators":
			var parent_generator = get_node_from_hier_name(command.parent)
			for n in command.generators:
				var g = parent_generator.get_node(n)
				if generator == parent_generator:
					if has_node("node_"+g.name):
						do_remove_node(get_node("node_"+g.name))
					else:
						print("Cannot find node_"+g.name)
						for c in get_children():
							print(c.name)
				else:
					parent_generator.remove_generator(g)
		"update_generator":
			var parent_generator = get_node_from_hier_name(command.parent)
			var g = parent_generator.get_node(command.name)
			if g != null:
				g.deserialize(command.data)
				var updated_generators = [ g ]
				match g.get_type_name():
					"Inputs", "Outputs":
						updated_generators.push_back(parent_generator)
				for ug in updated_generators:
					if generator == ug.get_parent():
						if has_node("node_"+ug.name):
							var node = get_node("node_"+ug.name)
							if node.has_method("update_node"):
								node.update_node()
		"setparams":
			var g = get_node_from_hier_name(command.node)
			for p in command.params.keys():
				g.set_parameter(p, MMType.deserialize_value(command.params[p]))
		"setseed":
			var g = get_node_from_hier_name(command.node)
			g.set_seed(command.seed)
			if g.get_parent() == generator:
				if has_node("node_"+g.name):
					var node = get_node("node_"+g.name)
					node.update()
		"setseedlocked":
			var g = get_node_from_hier_name(command.node)
			if command.seedlocked != g.is_seed_locked():
				g.toggle_lock_seed()
			if g.get_parent() == generator:
				if has_node("node_"+g.name):
					var node = get_node("node_"+g.name)
					node.update()
		"setminimized":
			var g = get_node_from_hier_name(command.node)
			g.minimized = command.minimized
			if g.get_parent() == generator:
				if has_node("node_"+g.name):
					var node = get_node("node_"+g.name)
					node.update_node()
		"move_generators":
			var parent_generator = get_node_from_hier_name(command.parent)
			for k in command.positions.keys():
				if parent_generator == generator:
					get_node("node_"+k).do_set_position(command.positions[k])
				else:
					parent_generator.get_node(k).set_position(command.positions[k])
		_:
			print("Unknown undo/redo command:")
			print(command)

func undoredo_move_node(node_name : String, old_pos : Vector2, new_pos : Vector2):
	if old_pos == new_pos:
		return
	var undo_action = { type="move_generators", parent=generator.get_hier_name(), positions={ node_name:old_pos } }
	var redo_action = { type="move_generators", parent=generator.get_hier_name(), positions={ node_name:new_pos } }
	undoredo.add("Move nodes", [undo_action], [redo_action], true)

func set_node_parameters(generator, parameters : Dictionary):
	var hier_name = generator.get_hier_name()
	var prev_params : Dictionary = {}
	for p in parameters.keys():
		var prev_value = MMType.serialize_value(generator.get_parameter(p))
		if parameters[p] != prev_value:
			generator.set_parameter(p, MMType.deserialize_value(parameters[p]))
		prev_params[p] = prev_value
	if ! prev_params.empty():
		var undo_action = { type="setparams", node=generator.get_hier_name(), params=prev_params }
		var redo_action = { type="setparams", node=generator.get_hier_name(), params=parameters }
		undoredo.add("Set parameters values", [undo_action], [redo_action], true)

func undoredo_merge(action_name, undo_actions, redo_actions, last_action):
	match action_name:
		"Move nodes":
			if action_name == last_action.name and ! undoredo_move_node_selection_changed:
				var a = undo_actions[0]
				for p in a.positions.keys():
					if ! last_action.undo_actions[0].positions.has(p):
						last_action.undo_actions[0].positions[p] = a.positions[p]
				a = redo_actions[0]
				for p in a.positions.keys():
					if ! last_action.redo_actions[0].positions.has(p):
						last_action.redo_actions[0].positions[p] = a.positions[p]
				return true
			print("undo/redo for move nodes reset")
			undoredo_move_node_selection_changed = false
	return false

func simplify_graph(graph):
	var new_nodes = {}
	for n in graph.nodes:
		new_nodes[n.name] = n
	graph.nodes = new_nodes
	var new_connections = {}
	for c in graph.connections:
		if ! new_connections.has(c.to):
			new_connections[c.to] = {}
		new_connections[c.to][c.to_port] = { from=c.from, from_port=c.from_port }
	graph.connections = new_connections
	return graph

func undoredo_step_actions(parent_path : String, prev : Dictionary, next : Dictionary, top : bool = true) -> Dictionary:
	if prev.type != next.type:
		return {}
	var undo_actions : Array = []
	var redo_actions : Array = []
	match prev.type:
		"graph":
			prev = simplify_graph(prev)
			next = simplify_graph(next)
			# Check all instances in prev
			var undo_add_nodes : Array = []
			var redo_add_nodes : Array = []
			var undo_update_nodes : Array = []
			var redo_update_nodes : Array = []
			var undo_remove_nodes : Array = []
			var redo_remove_nodes : Array = []
			for pin in prev.nodes.keys():
				if next.nodes.has(pin):
					var pi = prev.nodes[pin]
					var ni = next.nodes[pin]
					if pi.hash() != ni.hash():
						var child_path = pin if parent_path == "" else parent_path+"/"+pin
						var step_actions = undoredo_step_actions(child_path, pi, ni, false)
						if step_actions.empty():
							undo_remove_nodes.push_back(pin)
							undo_add_nodes.push_back(pi)
							redo_remove_nodes.push_back(pin)
							redo_add_nodes.push_back(ni)
						else:
							undo_update_nodes.append_array(step_actions.undo_actions)
							redo_update_nodes.append_array(step_actions.redo_actions)
				else:
					undo_add_nodes.push_back(prev.nodes[pin])
					redo_remove_nodes.push_back(pin)
			for nin in next.nodes.keys():
				if ! prev.nodes.has(nin):
					undo_remove_nodes.push_back(nin)
					redo_add_nodes.push_back(next.nodes[nin])
			# Check all connections in prev
			var undo_add_connections : Array = []
			var redo_add_connections : Array = []
			var undo_remove_connections : Array = []
			var redo_remove_connections : Array = []
			for pcn in prev.connections.keys():
				var pc = prev.connections[pcn]
				if next.connections.has(pcn):
					var nc = next.connections[pcn]
					for pcpn in pc.keys():
						var pcp = pc[pcpn]
						if nc.has(pcpn):
							var ncp = nc[pcpn]
							if pcp.from != ncp.from or pcp.from_port != ncp.from_port:
								undo_add_connections.push_back({ from=pcp.from, from_port=pcp.from_port, to=pcn, to_port=pcpn})
								redo_remove_connections.push_back({ from=pcp.from, from_port=pcp.from_port, to=pcn, to_port=pcpn})
								undo_remove_connections.push_back({ from=ncp.from, from_port=ncp.from_port, to=pcn, to_port=pcpn})
								redo_add_connections.push_back({ from=ncp.from, from_port=ncp.from_port, to=pcn, to_port=pcpn})
						else:
							undo_add_connections.push_back({ from=pcp.from, from_port=pcp.from_port, to=pcn, to_port=pcpn})
							redo_remove_connections.push_back({ from=pcp.from, from_port=pcp.from_port, to=pcn, to_port=pcpn})
				else:
					for pcpn in pc.keys():
						var pcp = pc[pcpn]
						undo_add_connections.push_back({ from=pcp.from, from_port=pcp.from_port, to=pcn, to_port=pcpn})
						redo_remove_connections.push_back({ from=pcp.from, from_port=pcp.from_port, to=pcn, to_port=pcpn})
			# Check all connections in next
			for ncn in next.connections.keys():
				var nc = next.connections[ncn]
				if prev.connections.has(ncn):
					var pc = next.connections[ncn]
					for ncpn in nc.keys():
						var ncp = nc[ncpn]
						if ! pc.has(ncpn):
							undo_remove_connections.push_back({ from=ncp.from, from_port=ncp.from_port, to=ncn, to_port=ncpn})
							redo_add_connections.push_back({ from=ncp.from, from_port=ncp.from_port, to=ncn, to_port=ncpn})
				else:
					for ncpn in nc.keys():
						var ncp = nc[ncpn]
						undo_remove_connections.push_back({ from=ncp.from, from_port=ncp.from_port, to=ncn, to_port=ncpn})
						redo_add_connections.push_back({ from=ncp.from, from_port=ncp.from_port, to=ncn, to_port=ncpn})
			if ! undo_remove_connections.empty():
				undo_actions.push_back({ type="remove_connections", parent=parent_path, connections=undo_remove_connections })
			if ! redo_remove_connections.empty():
				redo_actions.push_back({ type="remove_connections", parent=parent_path, connections=redo_remove_connections })
			if ! undo_remove_nodes.empty():
				undo_actions.push_back({ type="remove_generators", parent=parent_path, generators=undo_remove_nodes })
			if ! redo_remove_nodes.empty():
				redo_actions.push_back({ type="remove_generators", parent=parent_path, generators=redo_remove_nodes })
			if ! undo_update_nodes.empty():
				undo_actions.append_array(undo_update_nodes)
			if ! redo_update_nodes.empty():
				redo_actions.append_array(redo_update_nodes)
			if ! undo_add_nodes.empty() or ! undo_add_connections.empty():
				undo_actions.push_back({ type="add_to_graph", parent=parent_path, generators=undo_add_nodes, connections=undo_add_connections })
			if ! redo_add_nodes.empty() or ! redo_add_connections.empty():
				redo_actions.push_back({ type="add_to_graph", parent=parent_path, generators=redo_add_nodes, connections=redo_add_connections })
		"remote","ios":
			var generator_path = parent_path.left(parent_path.rfind("/"))
			undo_actions.push_back({ type="update_generator", parent=generator_path, name=next.name, data=prev })
			redo_actions.push_back({ type="update_generator", parent=generator_path, name=prev.name, data=next })
		_:
			print("ERROR: Unsupported node type %s in undoredo_step_actions" % prev.type)
			return {}
	if top:
		print("Undo actions:")
		print(undo_actions)
		print("Redo actions:")
		print(redo_actions)
	return { undo_actions=undo_actions, redo_actions=redo_actions }

func undoredo_create_step(action_name : String, parent_path : String, prev : Dictionary, next : Dictionary) -> void:
	if prev.type != next.type:
		print("Incorrect call for undoredo_create_step")
		return
	var step_actions = undoredo_step_actions(parent_path, prev, next)
	if ! step_actions.undo_actions.empty() and ! step_actions.redo_actions.empty():
		undoredo.add(action_name, step_actions.undo_actions, step_actions.redo_actions, false)

# Node change propagation

func find_graph_with_label(label: String) -> GraphNode:
	for c in get_children():
		if c is GraphNode and c.generator is MMGenGraph and c.generator.get_type_name() == label:
			return c
	return null

func get_propagation_targets(source : MMGenGraph, parent : MMGenGraph = null) -> Array:
	if parent == null:
		parent = top_generator
	var rv : Array = []
	for c in parent.get_children():
		if c is MMGenGraph and c != source:
			if c.get_type_name() == source.get_type_name():
				rv.push_back(c)
			else:
				rv.append_array(get_propagation_targets(source, c))
	return rv

func propagate_node_changes(source : MMGenGraph) -> void:
	for c in get_propagation_targets(source):
		c.apply_diff_from(source)
	
	var main_window = get_node("/root/MainWindow")
	main_window.hierarchy.update_from_graph_edit(self)
	update_view(generator)

# Adding/removing reroute nodes

func add_reroute_to_input(node : MMGraphNodeMinimal, port_index : int) -> void:
	var prev = generator.serialize()
	var new_connections = []
	var removed : bool = false
	for c in get_connection_list():
		if c.to == node.name and c.to_port == port_index:
			var from_node = get_node(c.from)
			if from_node.generator is MMGenReroute:
				var source = null
				for c2 in get_connection_list():
					if c2.to == c.from:
						source = {from=c2.from,from_port=c2.from_port}
						do_disconnect_node(c2.from, c2.from_port, c2.to, c2.to_port)
				if source != null:
					for c2 in get_connection_list():
						if c2.from == c.from:
							do_disconnect_node(c2.from, c2.from_port, c2.to, c2.to_port)
							new_connections.push_back({from=get_node(source.from).generator.name, from_port=source.from_port, to=get_node(c2.to).generator.name, to_port=c2.to_port})
							#connect_node(source.from, source.from_port, c2.to, c2.to_port)
					do_remove_node(from_node)
					if !new_connections.empty():
						do_create_nodes({nodes=[], connections=new_connections})
				removed = true
			break
	if ! removed:
		var scale = node.get_global_transform().get_scale()
		var port_position = node.offset+node.get_connection_input_position(port_index)/scale
		var reroute_position = port_position+Vector2(-74, -12)
		var reroute_node = {name="reroute",type="reroute",node_position={x=reroute_position.x,y=reroute_position.y}}
		for c2 in get_connection_list():
			if c2.to == node.name and c2.to_port == port_index:
				do_disconnect_node(c2.from, c2.from_port, c2.to, c2.to_port)
				new_connections.push_back({from=get_node(c2.from).generator.name, from_port=c2.from_port, to="reroute", to_port=0})
		new_connections.push_back({from="reroute", from_port=0, to=node.generator.name, to_port=port_index})
		do_create_nodes({nodes=[reroute_node], connections=new_connections})
	var next = generator.serialize()
	undoredo_create_step("Reroute input", generator.get_hier_name(), prev, next)

func add_reroute_to_output(node : MMGraphNodeMinimal, port_index : int) -> void:
	var prev = generator.serialize()
	var reroutes : bool = false
	var destinations = []
	for c in get_connection_list():
		if c.from == node.name and c.from_port == port_index:
			var to_node = get_node(c.to)
			if to_node.generator is MMGenReroute:
				reroutes = true
				var reroute_connections = []
				for c2 in get_connection_list():
					if c2.from == c.to:
						do_disconnect_node(c2.from, c2.from_port, c2.to, c2.to_port)
						reroute_connections.push_back({ from=node.generator.name, from_port=port_index, to=get_node(c2.to).generator.name, to_port=c2.to_port })
				if !reroute_connections.empty():
					do_create_nodes({nodes=[], connections=reroute_connections})
				do_remove_node(to_node)
			else:
				destinations.push_back(c.duplicate())
	if !reroutes:
		var scale = node.get_global_transform().get_scale()
		var port_position = node.offset+node.get_connection_output_position(port_index)/scale
		var reroute_position = port_position+Vector2(50, -12)
		var reroute_node = {name="reroute",type="reroute",node_position={x=reroute_position.x,y=reroute_position.y}}
		var reroute_connections = [ { from=node.generator.name, from_port=port_index, to="reroute", to_port=0 }]
		for d in destinations:
			do_disconnect_node(d.from, d.from_port, d.to, d.to_port)
			reroute_connections.push_back({ from="reroute", from_port=0, to=get_node(d.to).generator.name, to_port=d.to_port })
		do_create_nodes({nodes=[ reroute_node ],connections=reroute_connections})
	var next = generator.serialize()
	undoredo_create_step("Reroute output", generator.get_hier_name(), prev, next)
