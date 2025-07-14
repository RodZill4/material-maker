extends GraphEdit
class_name MMGraphEdit


class Preview:
	var generator
	var output_index : int
	var node : Node

	func _init(g, i : int = 0, n = null):
		generator = g
		output_index = i
		node = n

@export var shader_context_defs : String = "" # (String, MULTILINE)

var node_factory = null

var save_path := "": set = set_save_path
var need_save : bool = false
var save_crash_recovery_path = ""
var need_save_crash_recovery : bool = false

var top_generator = null
var generator = null

const PREVIEW_COUNT = 2
var current_preview : Array = [ null, null ]
var locked_preview : Array = [ null, null ]

@onready var node_popup : Popup = get_node("/root/MainWindow/AddNodePopup")
@onready var timer : Timer = $Timer

@onready var subgraph_ui : HBoxContainer = $GraphUI/SubGraphUI
@onready var button_transmits_seed : Button = $GraphUI/SubGraphUI/ButtonTransmitsSeed

@onready var undoredo = $UndoRedo
var undoredo_move_node_selection_changed : bool = true

enum ConnectionStyle {DIRECT, BEZIER, ROUNDED, MANHATTAN, DIAGONAL}
var connection_line_style : int = ConnectionStyle.BEZIER

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

func _exit_tree():
	remove_crash_recovery_file()


func get_project_type() -> String:
	return "material"


func get_graph_edit():
	return self


func do_zoom(factor : float):
	accept_event()
	var old_zoom : float = zoom
	zoom *= factor
	var global_mouse_position = offset_from_global_position(get_global_transform() * get_local_mouse_position())
	await get_tree().process_frame
	scroll_offset += (zoom/old_zoom-1.0)*old_zoom*global_mouse_position

var port_click_node : GraphNode
var port_click_port_index : int = -1

func get_nodes_under_mouse() -> Array:
	var array : Array = []
	for c in get_children():
		if c is GraphNode:
			var rect : Rect2 = get_padded_node_rect(c)
			if rect.has_point(get_global_mouse_position()):
				array.push_back(c)
	return array

func process_port_click(pressed : bool):
	for c in get_nodes_under_mouse():
		#var rect : Rect2 = c.get_global_rect()
		var pos : Vector2 = c.get_local_mouse_position()#get_global_mouse_position()-rect.position
		var transform_scale : Vector2 = Vector2(1, 1) # c.get_global_transform().get_scale()
		#rect = Rect2(rect.position, rect.size*transform_scale)
		var output_count : int = c.get_output_port_count()
		if output_count > 0:
			var output_1 : Vector2 = c.get_output_port_position(0)-8*transform_scale
			var output_2 : Vector2 = c.get_output_port_position(output_count-1)+8*transform_scale
			var in_output : bool = Rect2(output_1, output_2-output_1).has_point(pos)
			if in_output:
				for i in range(output_count):
					if (c.get_output_port_position(i)-pos).length() < 5*transform_scale.x:
						if pressed:
							port_click_node = c
							port_click_port_index = i
						elif port_click_node == c and port_click_port_index == i:
							var is_shift_pressed : bool = Input.is_key_pressed(KEY_SHIFT)
							var is_control_pressed : bool = Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
							set_current_preview(1 if is_shift_pressed else 0, port_click_node, port_click_port_index, is_control_pressed)
							port_click_port_index = -1
						return

func _gui_input(event) -> void:
	if (
		event.is_action_pressed("ui_library_popup")
		and not Input.is_key_pressed(KEY_CTRL)
		and get_global_rect().has_point(get_global_mouse_position())
	):
		# Only popup the UI library if Ctrl is not pressed to avoid conflicting
		# with the Ctrl + Space shortcut.
		accept_event()
		node_popup.position = Vector2i(get_screen_transform()*get_local_mouse_position())
		node_popup.show_popup()
	elif event.is_action_pressed("ui_hierarchy_up"):
		on_ButtonUp_pressed()
	elif event.is_action_pressed("ui_hierarchy_down"):
		var selected_nodes = get_selected_nodes()
		if selected_nodes.size() == 1 and selected_nodes[0].generator is MMGenGraph:
			update_view(selected_nodes[0].generator)
	elif event is InputEventMouseButton:
		# reverted to default GraphEdit behavior
		if false and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			if event.control:
				event.control = false
			elif !event.shift_pressed:
				event.control = true
				do_zoom(1.1)
		elif false and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			if event.control:
				event.control = false
			elif !event.shift_pressed:
				event.control = true
				do_zoom(1.0/1.1)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			for c in get_children():
				if ! c is GraphNode:
					continue
				var rect = get_padded_node_rect(c)
				if rect.has_point(get_global_mouse_position()):
					print("Node: "+c.name)
					if c.has_method("get_slot_from_position"):
						var slot = c.get_slot_from_position(get_global_mouse_position())
						match slot.type:
							"input":
								# Tell the node its connector was clicked
								if c.has_method("on_clicked_input"):
									c.on_clicked_input(slot.index, Input.is_key_pressed(KEY_SHIFT))
									return
							"output":
								# Tell the node its connector was clicked
								if c.has_method("on_clicked_output"):
									c.on_clicked_output(slot.index, Input.is_key_pressed(KEY_SHIFT))
									return
			# Only popup the UI library if Ctrl is not pressed to avoid conflicting
			# with the Ctrl + Space shortcut.
			node_popup.position = Vector2i(get_screen_transform()*get_local_mouse_position())
			node_popup.show_popup()
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.double_click:
					if get_nodes_under_mouse().is_empty():
						on_ButtonUp_pressed()
				else:
					process_port_click(event.is_pressed())
			call_deferred("check_previews")
	elif event is InputEventKey:
		if event.pressed:
			var scancode_with_modifiers = event.get_keycode_with_modifiers()
			match scancode_with_modifiers:
				KEY_H:
					minimize_selection()
				KEY_DELETE,KEY_BACKSPACE,KEY_X:
					remove_selection()
				KEY_LEFT:
					scroll_offset.x -= 0.5*size.x
					accept_event()
				KEY_RIGHT:
					scroll_offset.x += 0.5*size.x
					accept_event()
				KEY_UP:
					scroll_offset.y -= 0.5*size.y
					accept_event()
				KEY_DOWN:
					scroll_offset.y += 0.5*size.y
					accept_event()
		match event.get_keycode():
			KEY_SHIFT, KEY_CTRL, KEY_ALT:
				var found_tip : bool = false
				for c in get_children():
					if c.has_method("set_slot_tip_text"):
						var rect = get_padded_node_rect(c)
						if rect.has_point(get_global_mouse_position()):
							found_tip = found_tip or c.set_slot_tip_text(get_global_mouse_position()-c.global_position)
	elif event is InputEventMouseMotion:
		var found_tip : bool = false
		for c in get_children():
			if c.has_method("get_slot_tooltip"):
				var rect = get_padded_node_rect(c)
				if rect.has_point(get_global_mouse_position()):
					var mouse_pos : Vector2 = get_global_mouse_position()
					var slot : Dictionary = c.get_slot_from_position(mouse_pos)
					tooltip_text = c.get_slot_tooltip(mouse_pos, slot)
					found_tip = found_tip or c.set_slot_tip_text(mouse_pos, slot)
					break
				else:
					c.clear_connection_labels()
		if !found_tip:
			var rect = get_global_rect()
			if rect.has_point(get_global_mouse_position()):
				mm_globals.set_tip_text("Space/#RMB: Nodes menu, Arrow keys: Pan, Mouse wheel: Zoom", 3)

func get_padded_node_rect(graph_node:GraphNode) -> Rect2:
	var rect : Rect2 = graph_node.get_global_rect()
	var padding := 8 * graph_node.get_global_transform().get_scale().x
	rect.position.x -= padding
	rect.size.x += padding*2
	return Rect2(rect.position, rect.size)


# Misc. useful functions
func get_source(node, port) -> Dictionary:
	for c in get_connection_list():
		if c.to_node == node and c.to_port == port:
			return { node=c.from_node, slot=c.from_port }
	return {}

func offset_from_global_position(global_pos) -> Vector2:
	return (scroll_offset + global_pos - global_position) / zoom

func add_node(node) -> void:
	add_child(node)
	move_child(node, 0)
	node.connect("delete_request", Callable(self, "remove_node").bind(node))

func do_connect_node(from : String, from_slot : int, to : String, to_slot : int) -> bool:
	var from_node : MMGraphNodeMinimal = get_node(from)
	var to_node : MMGraphNodeMinimal = get_node(to)
	var from_gen = from_node.generator
	var to_gen = to_node.generator
	if generator.connect_children(from_gen, from_slot, to_gen, to_slot):
		super.connect_node(from, from_slot, to, to_slot)
		send_changed_signal()
		for n in [ from_node, to_node ]:
			if n.has_method("on_connections_changed"):
				n.on_connections_changed()
		return true
	return false

func on_connect_node(from : String, from_slot : int, to : String, to_slot : int):
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
			var disconnect_source = get_source(to, to_slot+i)
			if !disconnect_source.is_empty():
				super.disconnect_node(disconnect_source.node, disconnect_source.slot, to, to_slot+i)
				disconnect_list.push_back({from=get_node(NodePath(disconnect_source.node)).generator.name, from_port=disconnect_source.slot, to=get_node(NodePath(to)).generator.name, to_port=to_slot+i})
			super.connect_node(from, from_slot+i, to, to_slot+i)
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
		super.disconnect_node(from, from_slot, to, to_slot)
		send_changed_signal()
		for n in [ from_node, to_node ]:
			if n.has_method("on_connections_changed"):
				n.on_connections_changed()
		return true
	return false

func on_disconnect_node(from : String, from_slot : int, to : String, to_slot : int) -> void:
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
		super.disconnect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
	for c in added_connections:
		super.connect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)

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
			if c.from_node == node_name or c.to_node == node_name:
				do_disconnect_node(c.from_node, c.from_port, c.to_node, c.to_port)
		remove_child(node)
		node.queue_free()
		send_changed_signal()

# Global operations on graph

func update_tab_title() -> void:
	if !get_parent().has_method("set_tab_title"):
		#print("no set_tab_title method")
		return
	var title = "[unnamed]"
	if not save_path.is_empty():
		title = save_path.right(-(save_path.rfind("/")+1))
	if need_save:
		title += " *"
	if get_parent().has_method("set_tab_title"):
		get_parent().set_tab_title(get_index(), title)

func set_need_save(ns = true) -> void:
	if ns != need_save:
		need_save = ns
		update_tab_title()
	need_save_crash_recovery = true

func set_save_path(path: String) -> void:
	if path != save_path:
		remove_crash_recovery_file()
		need_save_crash_recovery = false
		save_path = path
		save_crash_recovery_path = save_path+".mmcr"
		update_tab_title()
		emit_signal("save_path_changed", self, path)

func clear_view() -> void:
	clear_connections()
	for c in get_children():
		if c is GraphElement:
			remove_child(c)
			c.free()

# crash_recovery

func crash_recovery_save() -> void:
	if !need_save_crash_recovery:
		return
	# don't save if there's only a single node
	if top_generator.get_child_count() < 2:
		return
	if save_crash_recovery_path == "":
		if not DirAccess.dir_exists_absolute("user://unsaved_projects"):
			DirAccess.make_dir_recursive_absolute("user://unsaved_projects")
		var i : int = 0
		while true:
			save_crash_recovery_path = "user://unsaved_projects/unsaved_%03d.mmcr" % i
			if not FileAccess.file_exists(save_crash_recovery_path):
				break
			i += 1
	var data = top_generator.serialize()
	var file : FileAccess = FileAccess.open(save_crash_recovery_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		need_save_crash_recovery = false

func remove_crash_recovery_file() -> void:
	if save_crash_recovery_path != "":
		DirAccess.remove_absolute(save_crash_recovery_path)

# Center view

func center_view() -> void:
	var center = Vector2(0, 0)
	var node_count = 0
	for c in get_children():
		if c is GraphNode:
			center += c.position_offset + 0.5*c.size
			node_count += 1
	if node_count > 0:
		center /= node_count
		scroll_offset = center - 0.5*size

func update_view(g) -> void:
	if generator != null and is_instance_valid(generator):
		generator.disconnect("connections_changed", Callable(self, "on_connections_changed"))
	clear_view()
	generator = g
	if generator != null:
		generator.connect("connections_changed", Callable(self, "on_connections_changed"))
	update_graph(generator.get_children(), generator.connections)
	subgraph_ui.visible = generator != top_generator
	subgraph_ui.get_node("Label").text = generator.label
	$GraphUI/SubGraphUI/Description.short_description = generator.shortdesc
	$GraphUI/SubGraphUI/Description.long_description = generator.longdesc
	$GraphUI/SubGraphUI/Description.update_tooltip()
	center_view()
	if generator.get_parent() is MMGenGraph:
		button_transmits_seed.visible = true
		button_transmits_seed.button_pressed = generator.transmits_seed
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
		node.move_to_front()
		rv.push_back(node)
	for c in connections:
		super.connect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
	return rv

func new_material(init_nodes = {nodes=[{name="Material", type="material",parameters={size=11}}], connections=[]}) -> void:
	clear_material()
	top_generator = await mm_loader.create_gen(init_nodes)
	if top_generator != null:
		add_child(top_generator)
		move_child(top_generator, 0)
		update_view(top_generator)
		center_view()
		set_save_path("")
		set_need_save(false)

func get_free_name(type) -> String:
	var i = 0
	while true:
		var node_name = type+"_"+str(i)
		if !has_node(node_name):
			return node_name
		i += 1
	return ""

func do_create_nodes(data, nodes_position : Vector2 = Vector2(0, 0)) -> Array:
	if !data is Dictionary:
		return []
	if data.has("type"):
		data = { nodes=[data], connections=[] }
	if data.has("nodes") and typeof(data.nodes) == TYPE_ARRAY and data.has("connections") and typeof(data.connections) == TYPE_ARRAY:
		var new_stuff = await mm_loader.add_to_gen_graph(generator, data.nodes, data.connections, nodes_position)
		var return_value = update_graph(new_stuff.generators, new_stuff.connections)
		return return_value
	return []

func create_nodes(data, nodes_position : Vector2 = Vector2(0, 0)) -> Array:
	var prev = generator.serialize().duplicate(true)
	var nodes = await do_create_nodes(data, nodes_position)
	if !nodes.is_empty():
		var next = generator.serialize()
		undoredo_create_step("Add and connect nodes", generator.get_hier_name(), prev, next)
	return nodes

func create_gen_from_type(gen_name) -> void:
	await create_nodes({ type=gen_name, parameters={} }, scroll_offset+0.5*size)

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
	var recovery_path = filename+".mmcr"
	if filename != null and FileAccess.file_exists(recovery_path):
		var dialog = preload("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instantiate()
		dialog.dialog_text = "Rescue file for "+filename.get_file()+" was found.\nLoad it?"
		dialog.get_ok_button().text = "Rescue"
		dialog.add_button("Load "+filename.get_file(), true, "load")
		add_child(dialog)
		var result = await dialog.ask()
		if result == "ok":
			new_generator = await mm_loader.load_gen(recovery_path)
	if new_generator != null:
		rescued = true
	else:
		new_generator = await mm_loader.load_gen(filename)
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
		var content_scale_factor = (mm_globals.main_window
				.get_window().content_scale_factor)
		dialog.content_scale_factor = content_scale_factor
		dialog.title = "Load failed!"
		dialog.dialog_text = "Failed to load "+filename
		dialog.min_size = dialog.get_contents_minimum_size() * content_scale_factor
		dialog.connect("popup_hide", Callable(dialog, "queue_free"))
		dialog.popup_centered()
		return false

func load_from_data(filename, data) -> bool:
	var test_json_conv = JSON.new()
	test_json_conv.parse(data)
	var json = test_json_conv.get_data()
	if json != null:
		var new_generator = await mm_loader.create_gen(json)
		if new_generator != null:
			set_save_path(filename)
			set_new_generator(new_generator)
			return true
	return false

func load_from_recovery(filename) -> bool:
	save_crash_recovery_path = filename
	var new_generator = await mm_loader.load_gen(save_crash_recovery_path)
	if new_generator != null:
		set_new_generator(new_generator)
		set_need_save(true)
		return true
	return false

# Save

func save() -> bool:
	var status = false
	if save_path != "":
		status = save_file(save_path)
	else:
		status = await save_as()
	return status

func save_as() -> bool:
	if OS.get_name() == "HTML5":
		var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instantiate()
		add_child(dialog)
		var status = await dialog.enter_text("Save", "Select a file name", save_path.get_file() if save_path != null else "")
		if status.ok:
			if save_file(status.text.get_file().get_basename()+".ptex"):
				top_generator.emit_signal("hierarchy_changed")
	else:
		var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
		dialog.min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		dialog.add_filter("*.ptex;Procedural Textures File")
		var main_window = mm_globals.main_window
		if mm_globals.config.has_section_key("path", "project"):
			dialog.current_dir = mm_globals.config.get_value("path", "project")
		var files = await dialog.select_files()
		if files.size() == 1:
			if save_file(files[0]):
				main_window.add_recent(save_path)
				mm_globals.config.set_value("path", "project", save_path.get_base_dir())
				top_generator.emit_signal("hierarchy_changed")
				return true
	return false

func save_file(filename:String) -> bool:
	mm_loader.current_project_path = filename.get_base_dir()
	var data = top_generator.serialize()
	mm_loader.current_project_path = ""
	var e: Error
	if OS.get_name() == "HTML5":
		JavaScriptBridge.download_buffer(JSON.stringify(data, "\t", true).to_ascii_buffer(), filename)
	else:
		var file : FileAccess = FileAccess.open(filename, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(data, "\t", true))
			e = file.get_error()
		else:
			e = FileAccess.get_open_error()
	if e != OK:
		var message = "Could not save in \"%s\" \n\nERROR: %s" % [filename, error_string(e)]
		mm_globals.main_window.accept_dialog(message, false, true)
		return false
	set_save_path(filename)
	set_need_save(false)
	mm_globals.set_tip_text("Project saved on \"%s\"" % filename, 5, 1)
	remove_crash_recovery_file()
	return true

# Export

func get_material_node() -> MMGenMaterial:
	if top_generator != null:
		for g in top_generator.get_children():
			if g.has_method("get_export_profiles"):
				return g
	return null

func export_material(export_prefix, profile) -> void:
	for g in top_generator.get_children():
		if g.has_method("export_material"):
			await g.export_material(export_prefix, profile)


# Cut / copy / paste / duplicate

func get_selected_nodes() -> Array:
	var selected_nodes = []
	for n in get_children():
		if n is GraphElement and n.selected:
			selected_nodes.append(n)
	return selected_nodes

func remove_selection() -> void:
	var prev = generator.serialize()
	for c in get_children():
		if c is GraphElement and c.selected and c.name != "Material" and c.name != "Brush":
			do_remove_node(c)
	var next = generator.serialize()
	undoredo_create_step("Delete nodes", generator.get_hier_name(), prev, next)

func minimize_selection() -> void:
	for c in get_children():
		if c is GraphElement and c.selected:
			if c.has_method("on_minimize_pressed"):
				c.on_minimize_pressed()

# Maybe move this to gen_graph...
func serialize_selection(nodes = [], with_inputs : bool = false) -> Dictionary:
	var data = { nodes = [], connections = [] }
	if nodes.is_empty():
		for c in get_children():
			if c is GraphElement and c.selected and c.name != "Material" and c.name != "Brush":
				nodes.append(c)
	if nodes.is_empty():
		return {}
	var center = Vector2(0, 0)
	for n in nodes:
		center += n.position_offset+0.5*n.size
	center /= nodes.size()
	for n in nodes:
		var s = n.generator.serialize()
		var p = n.position_offset-center
		s.node_position = { x=p.x, y=p.y }
		data.nodes.append(s)
	for c in get_connection_list():
		var from = get_node(NodePath(c.from_node))
		var to = get_node(NodePath(c.to_node))
		if from != null and (from.selected or with_inputs) and to != null and to.selected:
			var connection = c.duplicate(true)
			connection.from = from.generator.name
			connection.to = to.generator.name
			data.connections.append(connection)
	return data

func can_copy() -> bool:
	for c in get_children():
		if c is GraphElement and c.selected and c.name != "Material" and c.name != "Brush":
			return true
	return false

func cut() -> void:
	copy()
	remove_selection()

func copy() -> void:
	DisplayServer.clipboard_set(JSON.stringify(serialize_selection()))

func do_paste(data) -> void:
	var node_position = scroll_offset+0.5*size
	if Rect2(Vector2(0, 0), size).has_point(get_local_mouse_position()):
		node_position = offset_from_global_position(get_global_mouse_position())
	for c in get_children():
		if c is GraphElement:
			c.selected = false
	var new_nodes = await create_nodes(data, node_position)
	if new_nodes != null:
		for c in new_nodes:
			c.selected = true

func paste() -> void:
	var data : String = DisplayServer.clipboard_get().strip_edges()
	var parsed_data = await mm_globals.parse_paste_data(data)
	if parsed_data.graph != null:
		var graph = parsed_data.graph
		if graph is Dictionary and graph.has("type") and graph.type == "graph":
			var main_window = mm_globals.main_window
			var graph_edit = main_window.new_graph_panel()
			var new_generator = await mm_loader.create_gen(graph)
			if new_generator:
				graph_edit.set_new_generator(new_generator)
				main_window.hierarchy.update_from_graph_edit(graph_edit)
		else:
			do_paste(graph)
	else:
		print(data)

func duplicate_selected() -> void:
	do_paste(serialize_selection())

func duplicate_selected_with_inputs() -> void:
	do_paste(serialize_selection([], true))

func select_all() -> void:
	for c in get_children():
		if c is GraphElement:
			c.selected = true

func select_none() -> void:
	for c in get_children():
		if c is GraphElement:
			c.selected = false

func select_invert() -> void:
	for c in get_children():
		if c is GraphElement:
			c.selected = not c.selected

# Delay after graph update

func send_changed_signal() -> void:
	set_need_save(true)
	timer.start(0.2)

func do_send_changed_signal() -> void:
	emit_signal("graph_changed")

# Drag and drop

func _can_drop_data(_position, data) -> bool:
	return (
		(typeof(data) == TYPE_OBJECT and data is MMCurve)
		or typeof(data) == TYPE_COLOR
		or typeof(data) == TYPE_DICTIONARY
		and (data.has('type')
		or (data.has('nodes')
		and data.has('connections')))
		)

func _drop_data(node_position, data) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.has("tree_item"):
		get_node("/root/MainWindow/NodeLibraryManager").item_created(data.tree_item)
	# The following mitigates the SpinBox problem (captures mouse while dragging)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if typeof(data) == TYPE_COLOR:
		do_paste({type="uniform", color={ r=data.r, g=data.g, b=data.b, a=data.a }})
	elif typeof(data) == TYPE_DICTIONARY and data.has("type") and data.type == "Gradient" and data.has("points"):
		do_paste({type="colorize", gradient=data})
	elif typeof(data) == TYPE_OBJECT and data is MMCurve:
		do_paste({type="tonality", curve=data})
	else:
		create_nodes(data, offset_from_global_position(get_global_transform() * node_position))

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
	var graph_tree : Popup = preload("res://material_maker/widgets/graph_tree/graph_tree.tscn").instantiate()
	add_child(graph_tree)
	graph_tree.init("Top", top_generator)
	graph_tree.connect("item_icon_double_clicked", Callable(self, "edit_subgraph"))
	graph_tree.connect("popup_hide", Callable(graph_tree, "queue_free"))
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
	while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		await get_tree().process_frame
	for c in get_connection_list():
		set_connection_activity(c.from_node, c.from_port, c.to_node, c.to_port, 1.0 if get_node(NodePath(c.from_node)).selected or get_node(NodePath(c.to_node)).selected else 0.0)
	highlighting_connections = false

func _on_GraphEdit_node_selected(node : GraphElement) -> void:
	if node is MMGraphComment:
		print("Selecting enclosed nodes...")
		for c in get_children():
			if c is GraphNode and c != node:
				if node.get_rect().encloses(c.get_rect()):
					c.selected = true
	elif node is MMGraphCommentLine:
		pass
	else:
		highlight_connections()
		await get_tree().process_frame
		if current_preview[0] != null:
			for n in get_selected_nodes():
				if n.generator == current_preview[0].generator:
					return
		if node.get_output_port_count():
			if Input.is_key_pressed(KEY_SHIFT):
				set_current_preview(1, node)
			else:
				set_current_preview(0, node)
	undoredo_move_node_selection_changed = true
	mm_globals.main_window.update_menus()

func _on_GraphEdit_node_unselected(_node):
	highlight_connections()
	undoredo_move_node_selection_changed = true
	mm_globals.main_window.update_menus()


func get_current_preview(slot : int = 0) -> Preview:
	if locked_preview[slot] != null:
		return locked_preview[slot]
	return current_preview[slot]


func set_current_preview(slot: int, node: GraphNode, output_index: int = 0, locked := false, force_unlock := false) -> void:
	var preview = null
	var old_preview = null
	var old_locked_preview = null
	if is_instance_valid(node):
		preview = Preview.new(node.generator, output_index, node)
	if locked:
		if is_instance_valid(node) and locked_preview[slot] != null and locked_preview[slot].generator != node.generator:
			old_locked_preview = locked_preview[slot].generator
		if locked_preview[slot] != null and preview != null and locked_preview[slot].generator == preview.generator and locked_preview[slot].output_index == preview.output_index:
			locked_preview[slot] = null
		else:
			locked_preview[slot] = preview
	else:
		if is_instance_valid(node) and current_preview[slot] != null and current_preview[slot].generator != node.generator:
			old_preview = current_preview[slot].generator
		if force_unlock:
			locked_preview[slot] = null
		current_preview[slot] = preview

	preview_changed.emit(self)

	if is_instance_valid(node):
		node.queue_redraw()
	if old_preview != null or old_locked_preview != null:
		for c in get_children():
			if c is GraphNode and (c.generator == old_preview or c.generator == old_locked_preview):
				c.queue_redraw()


func request_popup(node_name : String , slot_index : int, _release_position : Vector2, connect_output : bool) -> void:
	# Check if the connector was actually  dragged
	var node : GraphNode = get_node(node_name)
	if node == null:
		return
	# Request the popup
	node_popup.position = get_screen_transform()*get_local_mouse_position()
	var slot_type
	if connect_output:
		slot_type = mm_io_types.types[node.generator.get_input_defs()[slot_index].type].slot_type
	else:
		slot_type = mm_io_types.types[node.generator.get_output_defs()[slot_index].type].slot_type
	node_popup.show_popup(node_name, slot_index, slot_type, connect_output)

func check_previews() -> void:
	var preview_has_changed : bool = false
	for i in PREVIEW_COUNT:
		if current_preview[i] != null and ! is_instance_valid(current_preview[i].generator):
			current_preview[i] = null
			preview_has_changed = true
		if locked_preview[i] != null and ! is_instance_valid(locked_preview[i].generator):
			locked_preview[i] = null
			preview_has_changed = true
	if preview_has_changed:
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
			var node_position : Vector2 = command.position if command.has("position") else Vector2(0, 0)
			var generators = command.generators if command.has("generators") else []
			var connections = command.connections if command.has("connections") else []
			var new_stuff = await mm_loader.add_to_gen_graph(parent_generator, generators, connections, node_position)
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
					super.disconnect_node("node_"+c.from, c.from_port, "node_"+c.to, c.to_port)
		"remove_generators":
			var parent_generator = get_node_from_hier_name(command.parent)
			for n in command.generators:
				var g = parent_generator.get_node(NodePath(n))
				if generator == parent_generator:
					if has_node("node_"+g.name):
						do_remove_node(get_node(NodePath("node_"+g.name)))
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
		"setgenericsize":
			var g = get_node_from_hier_name(command.node)
			g.set_generic_size(command.size)
			if g.get_parent() == generator:
				if has_node("node_"+g.name):
					var node = get_node("node_"+g.name)
					node.update_node()
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
		"resize_comment":
			var g = get_node_from_hier_name(command.node)
			g.size = command.size
			if g.get_parent() == generator:
				if has_node("node_"+g.name):
					var node = get_node("node_"+g.name)
					node.update_node()
		"comment_color_change":
			var g = get_node_from_hier_name(command.node)
			g.color = command.color
			if g.get_parent() == generator:
				if has_node("node_"+g.name):
					var node = get_node("node_"+g.name)
					node.update_node()
		_:
			print("Unknown undo/redo command:")
			print(command)

func undoredo_move_node(node_name : String, old_pos : Vector2, new_pos : Vector2):
	if old_pos == new_pos:
		return
	var undo_action = { type="move_generators", parent=generator.get_hier_name(), positions={ node_name:old_pos } }
	var redo_action = { type="move_generators", parent=generator.get_hier_name(), positions={ node_name:new_pos } }
	undoredo.add("Move nodes", [undo_action], [redo_action], true)

func set_node_parameters(node, parameters : Dictionary):
	var hier_name = node.get_hier_name()
	var prev_params : Dictionary = {}
	for p in parameters.keys():
		var prev_value = MMType.serialize_value(node.get_parameter(p))
		if parameters[p] != prev_value:
			node.set_parameter(p, MMType.deserialize_value(parameters[p]))
		prev_params[p] = prev_value
	if ! prev_params.is_empty():
		var undo_action = { type="setparams", node=hier_name, params=prev_params }
		var redo_action = { type="setparams", node=hier_name, params=parameters }
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
			#print("undo/redo for move nodes reset")
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
						if step_actions.is_empty():
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
			if ! undo_remove_connections.is_empty():
				undo_actions.push_back({ type="remove_connections", parent=parent_path, connections=undo_remove_connections })
			if ! redo_remove_connections.is_empty():
				redo_actions.push_back({ type="remove_connections", parent=parent_path, connections=redo_remove_connections })
			if ! undo_remove_nodes.is_empty():
				undo_actions.push_back({ type="remove_generators", parent=parent_path, generators=undo_remove_nodes })
			if ! redo_remove_nodes.is_empty():
				redo_actions.push_back({ type="remove_generators", parent=parent_path, generators=redo_remove_nodes })
			if ! undo_update_nodes.is_empty():
				undo_actions.append_array(undo_update_nodes)
			if ! redo_update_nodes.is_empty():
				redo_actions.append_array(redo_update_nodes)
			if ! undo_add_nodes.is_empty() or ! undo_add_connections.is_empty():
				undo_actions.push_back({ type="add_to_graph", parent=parent_path, generators=undo_add_nodes, connections=undo_add_connections })
			if ! redo_add_nodes.is_empty() or ! redo_add_connections.is_empty():
				redo_actions.push_back({ type="add_to_graph", parent=parent_path, generators=redo_add_nodes, connections=redo_add_connections })
		"remote","ios":
			var generator_path = parent_path.left(parent_path.rfind("/"))
			undo_actions.push_back({ type="update_generator", parent=generator_path, name=next.name, data=prev })
			redo_actions.push_back({ type="update_generator", parent=generator_path, name=prev.name, data=next })
		_:
			print("ERROR: Unsupported node type %s in undoredo_step_actions" % prev.type)
			return {}
	if false and top:
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
	if step_actions.has("undo_actions") && step_actions.has("redo_actions") && ! step_actions.undo_actions.is_empty() and ! step_actions.redo_actions.is_empty():
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

	var main_window = mm_globals.main_window
	main_window.hierarchy.update_from_graph_edit(self)
	update_view(generator)

# Adding/removing reroute nodes

func add_reroute_to_input(node : MMGraphNodeMinimal, port_index : int) -> void:
	var prev = generator.serialize()
	var new_connections = []
	var removed : bool = false
	for c in get_connection_list():
		if c.to_node == node.name and c.to_port == port_index:
			var from_node = get_node(NodePath(c.from_node))
			if from_node.generator is MMGenReroute:
				var source = null
				for c2 in get_connection_list():
					if c2.to_node == c.from_node:
						source = {from=c2.from_node,from_port=c2.from_port}
						do_disconnect_node(c2.from_node, c2.from_port, c2.to_node, c2.to_port)
				if source != null:
					for c2 in get_connection_list():
						if c2.from_node == c.from_node:
							do_disconnect_node(c2.from_node, c2.from_port, c2.to_node, c2.to_port)
							new_connections.push_back({from=get_node(NodePath(source.from)).generator.name, from_port=source.from_port, to=get_node(NodePath(c2.to_node)).generator.name, to_port=c2.to_port})
							#connect_node(source.from, source.from_port, c2.to_node, c2.to_port)
					do_remove_node(from_node)
					if !new_connections.is_empty():
						do_create_nodes({nodes=[], connections=new_connections})
				removed = true
			break
	if ! removed:
		var global_scale = Vector2(1, 1) # node.get_global_transform().get_scale()
		var port_position = node.position_offset+node.get_input_port_position(port_index)/global_scale
		var reroute_position = port_position+Vector2(-74, -12)
		var reroute_node = {name="reroute",type="reroute",node_position={x=reroute_position.x,y=reroute_position.y}}
		for c2 in get_connection_list():
			if c2.to_node == node.name and c2.to_port == port_index:
				do_disconnect_node(c2.from_node, c2.from_port, c2.to_node, c2.to_port)
				new_connections.push_back({from=get_node(NodePath(c2.from_node)).generator.name, from_port=c2.from_port, to="reroute", to_port=0})
		new_connections.push_back({from="reroute", from_port=0, to=node.generator.name, to_port=port_index})
		do_create_nodes({nodes=[reroute_node], connections=new_connections})
	var next = generator.serialize()
	undoredo_create_step("Reroute input", generator.get_hier_name(), prev, next)

func add_reroute_to_output(node : MMGraphNodeMinimal, port_index : int) -> void:
	var prev = generator.serialize()
	var reroutes : bool = false
	var destinations = []
	for c in get_connection_list():
		if c.from_node == node.name and c.from_port == port_index:
			var to_node = get_node(NodePath(c.to_node))
			if to_node.generator is MMGenReroute:
				reroutes = true
				var reroute_connections = []
				for c2 in get_connection_list():
					if c2.from_node == c.to_node:
						do_disconnect_node(c2.from_node, c2.from_port, c2.to_node, c2.to_port)
						reroute_connections.push_back({ from=node.generator.name, from_port=port_index, to=get_node(NodePath(c2.to_node)).generator.name, to_port=c2.to_port })
				if !reroute_connections.is_empty():
					do_create_nodes({nodes=[], connections=reroute_connections})
				do_remove_node(to_node)
			else:
				destinations.push_back(c.duplicate())
	if !reroutes:
		var global_scale = Vector2(1, 1) # node.get_global_transform().get_scale()
		var port_position = node.position_offset+node.get_output_port_position(port_index)/global_scale
		var reroute_position = port_position+Vector2(50, -12)
		var reroute_node = {name="reroute",type="reroute",node_position={x=reroute_position.x,y=reroute_position.y}}
		var reroute_connections = [ { from=node.generator.name, from_port=port_index, to="reroute", to_port=0 }]
		for d in destinations:
			do_disconnect_node(d.from_node, d.from_port, d.to_node, d.to_port)
			reroute_connections.push_back({ from="reroute", from_port=0, to=get_node(NodePath(d.to_node)).generator.name, to_port=d.to_port })
		do_create_nodes({nodes=[ reroute_node ],connections=reroute_connections})
	var next = generator.serialize()
	undoredo_create_step("Reroute output", generator.get_hier_name(), prev, next)

func _get_connection_line(from: Vector2, to: Vector2) -> PackedVector2Array:
	var off : float = 15.0 * connection_lines_curvature * 0.5 * zoom
	var points : PackedVector2Array = PackedVector2Array()
	match connection_line_style:
		ConnectionStyle.DIRECT:
			return PackedVector2Array([from,to])

		ConnectionStyle.BEZIER:
		# default behavior, adapted from:
		# github.com/godotengine/godot/blob/4.4/scene/gui/graph_edit.cpp#L1282
			var x_diff = to.x - from.x
			var cp_offset = x_diff * connection_lines_curvature
			if x_diff < 0:
				cp_offset *= -1

			var curve : Curve2D = Curve2D.new()
			curve.add_point(from)
			curve.set_point_out(0, Vector2(cp_offset, 0))
			curve.add_point(to)
			curve.set_point_in(1, Vector2(-cp_offset, 0))
			
			if connection_lines_curvature > 0:
				return curve.tessellate(5, 2.0)
			else:
				return curve.tessellate(1)

		ConnectionStyle.MANHATTAN:
			if abs(from.x - to.x) < 0.5 or abs(from.y - to.y) < 0.5:
				return PackedVector2Array([from,to])
			var mid : Vector2 = (from + to) / 2.0
			var ma : Vector2 = Vector2(max(mid.x, from.x + off), mid.y)
			var mb : Vector2 = Vector2(min(mid.x, to.x - off), mid.y)
			var f1 : Vector2 = Vector2(max(mid.x, from.x + off), from.y)
			var t1 : Vector2 = Vector2(mb.x, to.y)

			points.append(from)
			points.append(f1)
			points.append(ma)
			points.append(mb)
			points.append(t1)
			points.append(to)
			return points

		ConnectionStyle.ROUNDED:
			if abs(from.x - to.x) < 0.5 or abs(from.y - to.y) < 0.5:
				return PackedVector2Array([from,to])
			var mid : Vector2 = (from + to) / 2.0
			var mb : Vector2 = mid
			points.append(from)

			const pts : float = 12.0 # corner arc resolution
			var max_radius : float = 75.0 # max. arc radius when from < to
			var inv_max_radius : float = 25.0 # max. arc radius when from > to

			var round_fac : float = clamp(connection_lines_curvature * 0.5, 0.0, 1.0)
			max_radius = max(max_radius * round_fac, 4.0)
			inv_max_radius = max(inv_max_radius * round_fac , 2.0)

			var r : float = min(min(abs(to.y - from.y) * 0.25,
					abs(from.x - to.x) * 0.25), max_radius)
			
			if from.x < to.x:
				for i : float in range(pts):
					var x : float = lerp(mid.x - r, mid.x, i/pts)
					var y : float = lerp(from.y, from.y + r * sign(to.y - from.y), i/pts)
					points.append(lerp(Vector2(x, from.y), Vector2(mid.x, y), i/pts))

				for i : float in range(pts):
					var x : float = lerp(mid.x, mid.x + r, i/pts)
					var y : float = lerp(to.y + r * sign(from.y - to.y), to.y, i/pts)
					points.append(lerp(Vector2(mid.x, y),Vector2(x , to.y), i/pts))
			else:
				r = min(r, inv_max_radius)
				for i : float in range(pts):
					var x : float = lerp(from.x, from.x + r, i/pts)
					var y : float = lerp(from.y, from.y + r * sign(to.y - from.y), i/pts)
					points.append(lerp(Vector2(x , from.y), Vector2(from.x + r, y), i/pts))

				var last : Vector2 = points[points.size() - 1]
				mb.x = last.x
				var voff : float = last.y + 0.01 * sign(mid.y - last.y)
				mb.y = min(mid.y + r, voff) if from.y > to.y else max(mid.y - r, voff)
				points.append(mb)

				if from.y < to.y:
					var t1 : Vector2 = Vector2(points[points.size() - 1].x, mb.y)
					for i : float in range(pts):
						var x : float = lerp(t1.x, t1.x - r, i/pts)
						var y : float = lerp(t1.y, t1.y + r, i/pts)
						points.append(lerp(Vector2(t1.x, y),Vector2(x , t1.y + r), i/pts))

					var t2 : Vector2 = Vector2(to.x, mb.y + r)
					r = min(abs(t2.y - to.y) * 0.5, r)
					for i : float in range(1, pts):
						var x : float = lerp(t2.x, t2.x - r, i/pts)
						var y : float = lerp(t2.y, t2.y + r, i/pts)
						points.append(lerp(Vector2(x, t2.y),Vector2(t2.x - r, y), i/pts))

					var t3 : Vector2 = Vector2(to.x - r, to.y - r)

					for i : float in range(pts):
						var x : float = lerp(t3.x, t3.x + r, i/pts)
						var y : float = lerp(t3.y, t3.y + r, i/pts)
						points.append(lerp(Vector2(t3.x, y),Vector2(x , t3.y + r), i/pts))
				else:
					var t4 : Vector2 = points[points.size() - 1]

					r = min(abs(t4.y - to.y) * 0.5, r)
					for i : float in range(pts):
						var x : float = lerp(t4.x, t4.x - r, i/pts)
						var y : float = lerp(t4.y, t4.y - r, i/pts)
						points.append(lerp(Vector2(t4.x, y),Vector2(x, t4.y - r),i/pts))
					var t5 : Vector2 = Vector2(to.x, t4.y - r)

					r = min(abs(t5.y - to.y) * 0.5, r)
					for i : float in range(pts):
						var x : float = lerp(t5.x, t5.x - r, i/pts)
						var y : float = lerp(t5.y, t5.y - r, i/pts)
						points.append(lerp(Vector2(x, t5.y),Vector2(t5.x - r ,y), i/pts))

					var t6 : Vector2 = Vector2(to.x - r, to.y + r)
					for i : float in range(pts):
						var x : float = lerp(t6.x, t6.x + r, i/pts)
						var y : float = lerp(t6.y, t6.y - r, i/pts)
						points.append(lerp(Vector2(t6.x, y),Vector2(x , t6.y - r), i/pts))
			points.append(to)
			return points

		ConnectionStyle.DIAGONAL:
			if to.x > from.x:
				off += (to.x-from.x) * 0.1

			var mid : Vector2 = (from + to) / 2.0
			var ma : Vector2 = Vector2(max(mid.x, from.x + off), mid.y)
			var mb : Vector2 = Vector2(min(mid.x, to.x - off), mid.y)
			var f1 : Vector2 = Vector2(from.x + off, from.y)
			var t1 : Vector2 = Vector2(to.x - off, to.y)

			points.append(from)
			points.append(f1)
			points.append((f1 + ma) * 0.5)
			points.append((t1 + mb) * 0.5)
			points.append(t1)
			points.append(to)
			return points
		_:
			return points
