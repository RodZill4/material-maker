class_name AddNodePopup
extends Popup


@onready var filter : LineEdit = %Filter

var item_sort_mode : SortMenu.Sorting = mm_globals.get_config("add_node_popup_sort")

var insert_position : Vector2

var qc_node : String = ""
var qc_slot : int
var qc_slot_type : int
var qc_is_output : bool

@onready var library_manager = get_node("/root/MainWindow/NodeLibraryManager")

func get_current_graph():
	return get_parent().get_current_graph_edit()

func _ready() -> void:
	filter.connect("text_changed", Callable(self, "update_list"))
	filter.connect("text_submitted", Callable(self, "filter_entered"))
	%List.set_drag_forwarding(get_list_drag_data, Callable(), Callable())
	update_list()


func focus_filter() -> void:
	filter.grab_focus()
	filter.edit()


func filter_entered(_filter) -> void:
	_on_list_item_activated(0)
	mm_steam.unlock_achievement("ACH_TREASURE_HUNTER")


func add_node(node_data) -> void:
	var current_graph : GraphEdit = get_current_graph()
	current_graph.undoredo.start_group()
	var nodes : Array = await current_graph.create_nodes(node_data, insert_position)
	if not nodes.is_empty():
		var node : GraphNode = nodes[0] as GraphNode
		if node != null:
			if qc_node != "": # dragged from port
				var port_position : Vector2
				if qc_is_output:
					for new_slot in node.get_output_port_count():
						var slot_type : int = node.get_output_port_type(new_slot)
						if qc_slot_type == slot_type or slot_type == 42 or qc_slot_type == 42:
							current_graph.on_connect_node(node.name, new_slot, qc_node, qc_slot)
							port_position = node.get_output_port_position(new_slot)
							break
				else:
					for new_slot in node.get_input_port_count():
						var slot_type : int = node.get_input_port_type(new_slot)
						if qc_slot_type == slot_type or slot_type == 42 or qc_slot_type == 42:
							current_graph.on_connect_node(qc_node, qc_slot, node.name, new_slot)
							port_position = node.get_input_port_position(new_slot)
							break
				node.position_offset -= port_position/current_graph.zoom
	current_graph.undoredo.end_group()
	get_node("/root/MainWindow/NodeLibraryManager").item_created(node_data.tree_item)
	todo_renamed_hide()


func todo_renamed_hide() -> void:
	super.hide()
	get_current_graph().grab_focus()


func show_popup(node_name : String = "", slot : int = -1, slot_type : int = -1, is_output : bool = false) -> void:
	if not get_tree().root.gui_embed_subwindows:
		get_window().content_scale_factor = get_tree().root.content_scale_factor
	var current_graph = get_current_graph()
	insert_position = current_graph.offset_from_global_position(current_graph.get_global_mouse_position())
	popup()
	qc_node = node_name
	qc_slot = slot
	qc_slot_type = slot_type
	qc_is_output = is_output
	for b in $PanelContainer/VBoxContainer/Buttons.get_children():
		if b.library_item == null:
			b.disable()
			continue
		var obj = b.library_item.item
		if not obj.has("type") or ( qc_slot_type != -1 and not check_quick_connect(obj) ):
			b.disable()
		else:
			b.enable()
	if filter.text != "":
		filter.text = ""
	update_list(filter.text)
	focus_filter.call_deferred()


func check_quick_connect(obj : Dictionary) -> bool:
	var ref_obj : Dictionary = obj
	if mm_loader.predefined_generators.has(obj.type):
		ref_obj = mm_loader.predefined_generators[obj.type]
	# comment and remote nodes have neither input nor output
	if ! ref_obj.has("type") or ref_obj.type == "comment" or ref_obj.type == "comment_line" or ref_obj.type == "remote":
		return false
	if qc_is_output:
		if ref_obj.has("shader_model"):
			if ! ref_obj.shader_model.has("outputs") or ref_obj.shader_model.outputs.is_empty():
				return false
			else:
				var found : bool = false
				for outputs in ref_obj.shader_model.outputs.size():
					if qc_slot_type == 42 or mm_io_types.types[ref_obj.shader_model.outputs[outputs].type].slot_type == qc_slot_type:
						found = true
						break
				if !found:
					return false
		elif ref_obj.has("nodes"):
			var output_ports = []
			for n in ref_obj.nodes:
				if n.name == "gen_outputs":
					if n.has("ports"):
						output_ports = n.ports
					break
			var found : bool = false
			for outputs in output_ports.size():
				if qc_slot_type == 42 or mm_io_types.types[output_ports[outputs].type].slot_type == qc_slot_type:
					found = true
					break
			if !found:
				return false
			if output_ports.is_empty() or mm_io_types.types[output_ports[0].type].slot_type != qc_slot_type and qc_slot_type != 42:
				return false
		elif (ref_obj.type == "image" or ref_obj.type == "text" or ref_obj.type == "buffer" or ref_obj.type == "iterate_buffer") and qc_slot_type != 0 and qc_slot_type != 42:
			return false
		elif (ref_obj.type == "debug" or ref_obj.type == "export" or ref_obj.type == "sdf") or (ref_obj.type == "portal" and ref_obj.io == MMGenPortal.Portal.IN):
			return false
	else:
		if ref_obj.has("shader_model"):
			if ! ref_obj.shader_model.has("inputs") or ref_obj.shader_model.inputs.is_empty():
				return false
			else:
				var found : bool = false
				for input in ref_obj.shader_model.inputs.size():
					if qc_slot_type == 42 or mm_io_types.types[ref_obj.shader_model.inputs[input].type].slot_type == qc_slot_type:
						found = true
						break
				if !found:
					return false
		elif ref_obj.has("nodes"):
			var input_ports = []
			for n in ref_obj.nodes:
				if n.name == "gen_inputs":
					if n.has("ports"):
						input_ports = n.ports
					break
			var found : bool = false
			for input in input_ports.size():
				if qc_slot_type == 42 or mm_io_types.types[input_ports[input].type].slot_type == qc_slot_type:
					found = true
					break
			if !found:
				return false
			if input_ports.is_empty() or mm_io_types.types[input_ports[0].type].slot_type != qc_slot_type and qc_slot_type != 42:
				return false
		elif ref_obj.type == "image" or ref_obj.type == "text" or ref_obj.type == "sdf" or ref_obj.type == "meshmap" or (ref_obj.type == "portal" and ref_obj.io == MMGenPortal.Portal.OUT):
			return false
		elif (ref_obj.type == "debug" or ref_obj.type == "buffer" or ref_obj.type == "iterate_buffer" or ref_obj.type == "export") and qc_slot_type != 0 and qc_slot_type != 42:
			return false
	return true

func update_list(filter_text : String = "") -> void:
	filter_text = filter_text.to_lower()
	%List.clear()
	var idx : int = 0

	var items : Array = library_manager.get_items(filter_text, true)
	items.sort_custom(SortMenu.sort_function(item_sort_mode, library_manager.item_usage))

	# Add sub-node items
	idx = sub_node_create_items(idx, filter_text)

	for i in items:
		var obj : Dictionary = i.item
		if not obj.has("type"):
			continue
		if qc_slot_type != -1 and ! check_quick_connect(obj):
			continue
		var section : String = obj.tree_item.get_slice("/", 0)
		var color : Color = library_manager.get_section_color(section)
		color = color.lerp(get_theme_color("font_color", "Label"), 0.5)
		var _name : String = obj.display_name
		_name = obj.tree_item# + "("+str(i.quality)+")" + " ("+str(i.idx)+")"

		%List.add_item(_name, i.icon)
		%List.set_item_custom_fg_color(idx, color)
		%List.set_item_metadata(idx, i)
		%List.set_item_tooltip_enabled(idx, false)

		idx += 1

	if %List.item_count:
		%List.select(0)

	%List.ensure_current_is_visible()

func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		todo_renamed_hide()


func _on_filter_gui_input(event: InputEvent) -> void:
	if event.is_action("ui_down"):
		%List.grab_focus()
		%List.select(1)


func _on_list_gui_input(event: InputEvent) -> void:
	if event.is_action("ui_up"):
		if not %List.item_count or %List.is_selected(0):
			%Filter.grab_focus()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var idx: int = %List.get_item_at_position(%List.get_local_mouse_position(), true)
		if idx != -1:
			_on_list_item_activated(idx)


func get_list_drag_data(m_position : Vector2):
	var idx : int = %List.get_item_at_position(m_position)
	var data = %List.get_item_metadata(idx)
	sub_node_disable_item_drag(data, idx)
	var texture_rect : TextureRect = TextureRect.new()
	texture_rect.texture = data.icon
	texture_rect.scale = Vector2(0.35, 0.35)
	%List.set_drag_preview(texture_rect)
	return data.item.tree_item


func _on_list_item_activated(index: int) -> void:
	var data = %List.get_item_metadata(index)
	if not data == null:
		add_node(data.item)
		todo_renamed_hide()

func _on_sort_menu_pressed() -> void:
	var panel : SortMenu = preload("res://material_maker/windows/add_node_popup/sort_menu.tscn").instantiate()
	panel.hide()
	add_child(panel)
	panel.sorting_changed.connect(update_list.bind(filter.text))
	panel.popup_hide.connect(panel.queue_free)
	if get_tree().root.gui_embed_subwindows:
		panel.content_scale_factor = 1.0
		panel.position = Vector2i(get_mouse_position()) + position
		panel.size = panel.get_contents_minimum_size()
		panel.show()
	else:
		panel.popup(Rect2(panel.get_mouse_position() * content_scale_factor, panel.size))


#region sub-node items

## Cache mapping node(tree path) to its associated parameter list
var node_params_cache : Dictionary[String, Array]

func sub_node_create_items(idx : int, filter_text : String) ->  int:
	var config_items : PackedStringArray = mm_globals.get_config("sub_node_items")
	if config_items.is_empty():
		return idx
	for item in config_items:
		idx = sub_node_add_items(idx, filter_text, item)
	return idx

func sub_node_add_items(idx : int, filter_text : String, tree : String) -> int:
	var data : Dictionary = library_manager.get_item(tree)
	var mmg : String = ""
	for k in ["name", "type"]:
		if data.item.has(k) and data.item[k].length() > mmg.length():
			mmg = data.item[k] + ".mmg"
	if mmg.is_empty():
		return idx

	filter_text = filter_text.strip_edges().to_lower()

	var base_item : Dictionary = library_manager.get_item(tree)
	if (qc_slot_type != -1 and not check_quick_connect(base_item.item)):
		return idx

	var nodes_path : String = OS.get_executable_path().get_base_dir() + "/nodes"
	if OS.has_feature("editor"):
		nodes_path = MMPaths.STD_GENDEF_PATH

	var node_params : Array
	if mmg not in node_params_cache:
		var f : FileAccess = FileAccess.open(nodes_path + "/" + mmg, FileAccess.READ)
		var node : Dictionary = JSON.parse_string(f.get_as_text())
		if node == null:
			return idx

		if (node.has("type") and node.type == "graph"):
			printerr("Sub-nodes are not supported for Nodegroup: %s" % tree)
			return idx

		node_params = node.shader_model.parameters
		node_params_cache[mmg] = node.shader_model.parameters
	else:
		node_params = node_params_cache[mmg]

	var node_ops : Array 
	var op_str : String

	# find the first enum parameter
	for p in node_params:
		if p.type == "enum":
			node_ops = p.values
			op_str = p.name.replace("#", "1")
			break

	var color : Color = library_manager.get_section_color(tree.get_slice("/", 0))
	color = color.lerp(get_theme_color("font_color", "Label"), 0.6)

	for op_id in node_ops.size():
		var op : Dictionary = node_ops[op_id]

		var include : bool = true
		if filter_text:
			include = (op.name.to_lower().begins_with(filter_text)
					or filter_text in op.name.to_lower())

			if not include:
				var has_op : bool = false
				var has_tree : bool = false
				for word in filter_text.split(" "):
					if word in op.name.to_lower():
						has_op = true
					if word in tree.split("/")[-1].to_lower():
						has_tree = true
				include = has_op and has_tree

			if include:
				var node : Dictionary = base_item.duplicate(true)
				node.item.parameters[op_str] = op_id

				%List.add_item(tree + "/" + op.name, node.icon)
				%List.set_item_metadata(idx, node)
				%List.set_item_custom_fg_color(idx, color)
				%List.set_item_tooltip_enabled(idx, false)
				idx += 1

	return idx

func sub_node_disable_item_drag(data, idx) -> void:
	# quick buttons stores tree_item paths based on entries in the library
	# and sub-nodes paths are virtual thus don't have a proper reference
	for b in $PanelContainer/VBoxContainer/Buttons.get_children():
		if %List.get_item_text(idx) != data.item.tree_item:
			b.temp_disable()

func sub_node_restore_item_drag() -> void:
	for b in $PanelContainer/VBoxContainer/Buttons.get_children():
		b.temp_restore()

#endregion

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_END:
			sub_node_restore_item_drag()
