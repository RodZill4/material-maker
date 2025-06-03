extends Popup


@onready var filter : LineEdit = $PanelContainer/VBoxContainer/Filter


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


func filter_entered(_filter) -> void:
	_on_list_item_activated(0)


func add_node(node_data) -> void:
	var current_graph : GraphEdit = get_current_graph()
	current_graph.undoredo.start_group()
	var nodes : Array = current_graph.create_nodes(node_data, insert_position)
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
	get_window().content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
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
	filter.grab_focus()


func check_quick_connect(obj) -> bool:
	var ref_obj = obj
	if mm_loader.predefined_generators.has(obj.type):
		ref_obj = mm_loader.predefined_generators[obj.type]
	# comment and remote nodes have neither input nor output
	if ! ref_obj.has("type") or ref_obj.type == "comment" or ref_obj.type == "remote":
		return false
	if qc_is_output:
		if ref_obj.has("shader_model"):
			if ! ref_obj.shader_model.has("outputs") or ref_obj.shader_model.outputs.is_empty():
				return false
			else:
				var found : bool = false
				for outputs in ref_obj.shader_model.outputs.size():
					if mm_io_types.types[ref_obj.shader_model.outputs[outputs].type].slot_type == qc_slot_type:
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
				if mm_io_types.types[output_ports[outputs].type].slot_type == qc_slot_type:
					found = true
					break
			if !found:
				return false
			if output_ports.is_empty() or mm_io_types.types[output_ports[0].type].slot_type != qc_slot_type:
				return false
		elif (ref_obj.type == "image" or ref_obj.type == "text" or ref_obj.type == "buffer" or ref_obj.type == "iterate_buffer") and qc_slot_type != 0:
			return false
		elif (ref_obj.type == "debug" or ref_obj.type == "export" or ref_obj.type == "sdf"):
			return false
	else:
		if ref_obj.has("shader_model"):
			if ! ref_obj.shader_model.has("inputs") or ref_obj.shader_model.inputs.is_empty():
				return false
			else:
				var found : bool = false
				for input in ref_obj.shader_model.inputs.size():
					if mm_io_types.types[ref_obj.shader_model.inputs[input].type].slot_type == qc_slot_type:
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
				if mm_io_types.types[input_ports[input].type].slot_type == qc_slot_type:
					found = true
					break
			if !found:
				return false
			if input_ports.is_empty() or mm_io_types.types[input_ports[0].type].slot_type != qc_slot_type:
				return false
		elif ref_obj.type == "image" or ref_obj.type == "text" or ref_obj.type == "sdf":
			return false
		elif (ref_obj.type == "debug" or ref_obj.type == "buffer" or ref_obj.type == "iterate_buffer" or ref_obj.type == "export") and qc_slot_type != 0:
			return false
	return true

func update_list(filter_text : String = "") -> void:
	filter_text = filter_text.to_lower()

	%List.clear()
	var idx := 0
	var items: Array = library_manager.get_items(filter_text, true)
	items.sort_custom(func(a,b): return a.idx < b.idx if a.quality == b.quality else a.quality > b.quality)
	for i in items:
		var obj = i.item
		if not obj.has("type"):
			continue
		if qc_slot_type != -1 and ! check_quick_connect(obj):
			continue
		var section = obj.tree_item.get_slice("/", 0)
		var color : Color = get_node("/root/MainWindow/NodeLibraryManager").get_section_color(section)
		color = color.lerp(get_theme_color("font_color", "Label"), 0.5)
		#print(i)
		var _name = obj.display_name
		_name = obj.tree_item# + "("+str(i.quality)+")" + " ("+str(i.idx)+")"
		#if obj.has("shortdesc")

		%List.add_item(_name, i.icon)
		%List.set_item_custom_fg_color(idx, color)
		%List.set_item_metadata(idx, i)
		%List.set_item_tooltip_enabled(idx, false)

		idx += 1

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


func get_list_drag_data(m_position):
	var data = %List.get_item_metadata(%List.get_item_at_position(m_position))
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
