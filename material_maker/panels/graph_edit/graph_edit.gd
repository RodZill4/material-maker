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

var sections = []
var section_themes = []

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

func connect_node(from, from_slot, to, to_slot):
	var from_node : MMGraphNodeMinimal = get_node(from)
	var to_node : MMGraphNodeMinimal = get_node(to)
	var connect_count = 1
	var connected : bool = false
	var out_ports = from_node.generator.get_output_defs()
	var in_ports = to_node.generator.get_input_defs()
	if out_ports[from_slot].has("group_size") and in_ports[to_slot].has("group_size") and out_ports[from_slot].group_size == in_ports[to_slot].group_size:
		connect_count = out_ports[from_slot].group_size
	for i in range(connect_count):
		if generator.connect_children(from_node.generator, from_slot+i, to_node.generator, to_slot+i):
			var disconnect = get_source(to, to_slot+i)
			if !disconnect.empty():
				.disconnect_node(disconnect.node, disconnect.slot, to, to_slot+i)
			.connect_node(from, from_slot+i, to, to_slot+i)
			connected = true
	if connected:
		send_changed_signal()
		for n in [ from_node, to_node ]:
			if n.has_method("on_connections_changed"):
				n.on_connections_changed()

func disconnect_node(from, from_slot, to, to_slot) -> void:
	var from_node : MMGraphNodeMinimal = get_node(from)
	var to_node : MMGraphNodeMinimal = get_node(to)
	if generator.disconnect_children(from_node.generator, from_slot, to_node.generator, to_slot):
		.disconnect_node(from, from_slot, to, to_slot)
		send_changed_signal()
		for n in [ from_node, to_node ]:
			if n.has_method("on_connections_changed"):
				n.on_connections_changed()

func on_connections_changed(removed_connections : Array, added_connections : Array) -> void:
	for c in removed_connections:
		.disconnect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
	for c in added_connections:
		.connect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)

func remove_node(node) -> void:
	for i in PREVIEW_COUNT:
		if current_preview[i] != null and node.generator == current_preview[i].generator:
			set_current_preview(i, null)
		if locked_preview[i] != null and node.generator == locked_preview[i].generator:
			set_current_preview(i, null, 0, true)
	if generator.remove_generator(node.generator):
		var node_name = node.name
		for c in get_connection_list():
			if c.from == node_name or c.to == node_name:
				disconnect_node(c.from, c.from_port, c.to, c.to_port)
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
	if generator != null:
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
		node.offset = g.position
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

func create_nodes(data, position : Vector2 = Vector2(0, 0)) -> Array:
	if !data is Dictionary:
		return []
	if data.has("type"):
		data = { nodes=[data], connections=[] }
	if data.has("nodes") and typeof(data.nodes) == TYPE_ARRAY and data.has("connections") and typeof(data.connections) == TYPE_ARRAY:
		var new_stuff = mm_loader.add_to_gen_graph(generator, data.nodes, data.connections)
		var actions : Array = []
		for g in new_stuff.generators:
			g.position += position
			actions.append({ action="add_node", node=g.name })
		for c in new_stuff.connections:
			actions.append({ action="add_connection", connection=c })
		$UndoRedo.add_action("Add nodes and connections", actions)
		return update_graph(new_stuff.generators, new_stuff.connections)
	return []

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
	for c in get_children():
		if c is GraphNode and c.selected and c.name != "Material" and c.name != "Brush":
			remove_node(c)

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
	var data = OS.clipboard
	if data.left(4) == "http":
		var http_request = HTTPRequest.new()
		add_child(http_request)
		var error = http_request.request(data)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		data = yield(http_request, "request_completed")[3].get_string_from_utf8()
		http_request.queue_free()
	var graph = parse_json(data)
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
	if generator != top_generator && generator.get_parent() is MMGenGraph:
		call_deferred("update_view", generator.get_parent())

func _on_Label_text_changed(new_text) -> void:
	generator.set_type_name(new_text)

# Create subgraph

func create_subgraph() -> void:
	var generators = []
	for n in get_selected_nodes():
		generators.push_back(n.generator)
	var subgraph = generator.create_subgraph(generators)
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
		set_current_preview(0, node)
		highlight_connections()

func _on_GraphEdit_node_unselected(_node):
	highlight_connections()

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
	# Check if the connector was actually dragged
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


func find_graph_with_label(label: String) -> GraphNode:
	for c in get_children():
		if c is GraphNode and c.generator is MMGenGraph && c.generator.get_type_name() == label:
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
	for c in get_connection_list():
		if c.to == node.name and c.to_port == port_index:
			var from_node = get_node(c.from)
			if from_node.generator is MMGenReroute:
				var source = null
				for c2 in get_connection_list():
					if c2.to == c.from:
						source = {from=c2.from,from_port=c2.from_port}
						disconnect_node(c2.from, c2.from_port, c2.to, c2.to_port)
				if source != null:
					for c2 in get_connection_list():
						if c2.from == c.from:
							disconnect_node(c2.from, c2.from_port, c2.to, c2.to_port)
							connect_node(source.from, source.from_port, c2.to, c2.to_port)
					remove_node(from_node)
				return
			break
	var scale = node.get_global_transform().get_scale()
	var port_position = node.offset+node.get_connection_input_position(port_index)/scale
	var reroute_position = port_position+Vector2(-74, -12)
	var reroute_node = create_nodes({nodes=[{name="reroute",type="reroute",node_position={x=reroute_position.x,y=reroute_position.y}}],connections=[]})[0]
	for c2 in get_connection_list():
		if c2.to == node.name and c2.to_port == port_index:
			disconnect_node(c2.from, c2.from_port, c2.to, c2.to_port)
			connect_node(c2.from, c2.from_port, reroute_node.name, 0)
			break
	connect_node(reroute_node.name, 0, node.name, port_index)

func add_reroute_to_output(node : MMGraphNodeMinimal, port_index : int) -> void:
	var reroutes : bool = false
	var destinations = []
	for c in get_connection_list():
		if c.from == node.name and c.from_port == port_index:
			var to_node = get_node(c.to)
			if to_node.generator is MMGenReroute:
				reroutes = true
				for c2 in get_connection_list():
					if c2.from == c.to:
						disconnect_node(c2.from, c2.from_port, c2.to, c2.to_port)
						connect_node(node.name, port_index, c2.to, c2.to_port)
				remove_node(to_node)
			else:
				destinations.push_back({to=c.to, to_port=c.to_port})
	if !reroutes:
		var scale = node.get_global_transform().get_scale()
		var port_position = node.offset+node.get_connection_output_position(port_index)/scale
		var reroute_position = port_position+Vector2(50, -12)
		var reroute_node = create_nodes({nodes=[{name="reroute",type="reroute",node_position={x=reroute_position.x,y=reroute_position.y}}],connections=[]})[0]
		connect_node(node.name, port_index, reroute_node.name, 0)
		for d in destinations:
			connect_node(reroute_node.name, 0, d.to, d.to_port)
