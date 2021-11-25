extends Popup


onready var list := $PanelContainer/VBoxContainer/ScrollContainer/List
onready var filter : LineEdit = $PanelContainer/VBoxContainer/Filter


var insert_position : Vector2

var qc_node : String = ""
var qc_slot : int
var qc_slot_type : int
var qc_is_output : bool

onready var library_manager = get_node("/root/MainWindow/NodeLibraryManager")


func get_current_graph():
	return get_parent().get_current_graph_edit()


func _ready() -> void:
	filter.connect("text_changed", self, "update_list")
	filter.connect("text_entered", self, "filter_entered")
	list.connect("object_selected", self, "object_selected")
	update_list()


func _draw() -> void:
	draw_rect(Rect2(0, 0, rect_size.x, rect_size.y), Color(1, 0.56, 0.56, 1), false, 2)


func filter_entered(_filter) -> void:
	list.select_first()


func add_node(node_data) -> void:
	var current_graph : GraphEdit = get_current_graph()
	var node : GraphNode = current_graph.create_nodes(node_data, insert_position)[0]
	if qc_node != "": # dragged from port
		var port_position : Vector2
		if qc_is_output:
			for new_slot in node.get_connection_output_count():
				var slot_type : int = node.get_connection_output_type(new_slot)
				if qc_slot_type == slot_type or slot_type == 42 or qc_slot_type == 42:
					current_graph.connect_node(node.name, new_slot, qc_node, qc_slot)
					port_position = node.get_connection_output_position(new_slot)
					break
		else:
			for new_slot in node.get_connection_input_count():
				var slot_type : int = node.get_connection_input_type(new_slot)
				if qc_slot_type == slot_type or slot_type == 42 or qc_slot_type == 42:
					current_graph.connect_node(qc_node, qc_slot, node.name, new_slot)
					port_position = node.get_connection_input_position(new_slot)
					break
		node.offset -= port_position/current_graph.zoom
	get_node("/root/MainWindow/NodeLibraryManager").item_created(node_data.tree_item)
	hide()


func object_selected(obj) -> void:
	add_node(obj)
	hide()


func hide() -> void:
	.hide()
	get_current_graph().grab_focus()


func show_popup(node_name : String = "", slot : int = -1, slot_type : int = -1, is_output : bool = false) -> void:
	insert_position = get_current_graph().offset_from_global_position(get_global_mouse_position())
	popup()
	qc_node = node_name
	qc_slot = slot
	qc_slot_type = slot_type
	qc_is_output = is_output
	filter.text = ""
	for b in $PanelContainer/VBoxContainer/Buttons.get_children():
		var obj = b.library_item.item
		if not obj.has("type") or ( qc_slot_type != -1 and not check_quick_connect(obj) ):
			b.disable()
		else:
			b.enable()
	update_list(filter.text)
	filter.grab_focus()
	filter.select_all()

func check_quick_connect(obj) -> bool:
	var ref_obj = obj
	if mm_loader.predefined_generators.has(obj.type):
		ref_obj = mm_loader.predefined_generators[obj.type]
	# comment and remote nodes have neither input nor output
	if ref_obj.type == "comment" or ref_obj.type == "remote":
		return false
	if qc_is_output:
		if ref_obj.has("shader_model"):
			if ! ref_obj.shader_model.has("outputs") or ref_obj.shader_model.outputs.empty():
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
			if output_ports.empty() or mm_io_types.types[output_ports[0].type].slot_type != qc_slot_type:
				return false
		elif (ref_obj.type == "image" or ref_obj.type == "text" or ref_obj.type == "buffer") and qc_slot_type != 0:
			return false
	else:
		if ref_obj.has("shader_model"):
			if ! ref_obj.shader_model.has("inputs") or ref_obj.shader_model.inputs.empty():
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
			if input_ports.empty() or mm_io_types.types[input_ports[0].type].slot_type != qc_slot_type:
				return false
		elif ref_obj.type == "image" or ref_obj.type == "text":
			return false
		elif (ref_obj.type == "debug" or ref_obj.type == "buffer" or ref_obj.type == "export" ) and qc_slot_type != 0:
			return false
	return true

func update_list(filter_text : String = "") -> void:
	filter_text = filter_text.to_lower()
	$PanelContainer/VBoxContainer/ScrollContainer.get_v_scrollbar().value = 0.0
	list.clear()
	for i in library_manager.get_items(filter_text, true):
		var obj = i.item
		if not obj.has("type"):
			continue
		if qc_slot_type != -1 and ! check_quick_connect(obj):
			continue
		var split: Array = obj.tree_item.rsplit("/", true, 1)
		match split:
			[var name]:
				list.add_item(obj, "", name, i.icon)
			[var path, var name]:
				list.add_item(obj, path, name, i.icon)

func _input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if !get_rect().has_point(event.position):
			hide()

func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()
