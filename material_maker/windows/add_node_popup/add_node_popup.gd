extends Popup


onready var list := $PanelContainer/VBoxContainer/ScrollContainer/List
onready var filter : LineEdit = $PanelContainer/VBoxContainer/Filter


var libraries = []


var qc_node : String = ""
var qc_slot : int
var qc_slot_type : int
var qc_is_output : bool


func get_current_graph():
	return get_parent().get_current_tab_control()


func _ready() -> void:
	var lib_path = OS.get_executable_path().get_base_dir()+"/library/base.json"
	if !add_library(lib_path):
		add_library("res://material_maker/library/base.json")
	add_library("user://library/user.json")
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
	var node : GraphNode = current_graph.create_nodes(node_data, get_current_graph().offset_from_global_position(rect_position))[0]
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
	hide()


func object_selected(obj) -> void:
	add_node(obj)
	hide()


func hide() -> void:
	.hide()
	get_current_graph().grab_focus()


func show_popup(node_name : String = "", slot : int = -1, slot_type : int = -1, is_output : bool = false) -> void:
	popup()
	qc_node = node_name
	qc_slot = slot
	qc_slot_type = slot_type
	qc_is_output = is_output
	filter.text = ""
	update_list(filter.text)
	filter.grab_focus()
	filter.select_all()


func update_list(filter_text : String = "") -> void:
	$PanelContainer/VBoxContainer/ScrollContainer.get_v_scrollbar().value = 0.0
	list.clear()
	for library in libraries:
		for obj in library:
			if not obj.has("type"):
				continue
			if qc_slot_type != -1:
				var ref_obj = obj
				if mm_loader.predefined_generators.has(obj.type):
					ref_obj = mm_loader.predefined_generators[obj.type]
				# comment and remote nodes have neither input nor output
				if ref_obj.type == "comment" or ref_obj.type == "remote":
					continue
				if qc_is_output:
					if ref_obj.has("shader_model"):
						if ! ref_obj.shader_model.has("outputs") or ref_obj.shader_model.outputs.empty():
							continue
						else:
							var found : bool = false
							for i in ref_obj.shader_model.outputs.size():
								if mm_io_types.types[ref_obj.shader_model.outputs[i].type].slot_type == qc_slot_type:
									found = true
									break
							if !found:
								continue
					elif ref_obj.has("nodes"):
						var output_ports = []
						for n in ref_obj.nodes:
							if n.name == "gen_outputs":
								if n.has("ports"):
									output_ports = n.ports
								break
						var found : bool = false
						for i in output_ports.size():
							if mm_io_types.types[output_ports[i].type].slot_type == qc_slot_type:
								found = true
								break
						if !found:
							continue
						if output_ports.empty() or mm_io_types.types[output_ports[0].type].slot_type != qc_slot_type:
							continue
					elif (ref_obj.type == "image" or ref_obj.type == "text" or ref_obj.type == "buffer") and qc_slot_type != 0:
						continue
				else:
					if ref_obj.has("shader_model"):
						if ! ref_obj.shader_model.has("inputs") or ref_obj.shader_model.inputs.empty():
							continue
						else:
							var found : bool = false
							for i in ref_obj.shader_model.inputs.size():
								if mm_io_types.types[ref_obj.shader_model.inputs[i].type].slot_type == qc_slot_type:
									found = true
									break
							if !found:
								continue
					elif ref_obj.has("nodes"):
						var input_ports = []
						for n in ref_obj.nodes:
							if n.name == "gen_inputs":
								if n.has("ports"):
									input_ports = n.ports
								break
						var found : bool = false
						for i in input_ports.size():
							if mm_io_types.types[input_ports[i].type].slot_type == qc_slot_type:
								found = true
								break
						if !found:
							continue
						if input_ports.empty() or mm_io_types.types[input_ports[0].type].slot_type != qc_slot_type:
							continue
					elif ref_obj.type == "image" or ref_obj.type == "text":
						continue
					elif (ref_obj.type == "debug" or ref_obj.type == "buffer" or ref_obj.type == "export" ) and qc_slot_type != 0:
						continue
			var show : bool = true
			for f in filter_text.to_lower().split(" ", false):
				if f != "" and obj.tree_item.to_lower().find(f) == -1:
					show = false
					break
			if show:
				var icon := get_preview_texture(obj)
				var split: Array = obj.tree_item.rsplit("/", true, 1)
				match split:
					[var name]:
						list.add_item(obj, "", name, icon)
					[var path, var name]:
						list.add_item(obj, path, name, icon)


func get_preview_texture(icon_data : Dictionary) -> ImageTexture:
	if icon_data.has("icon") and icon_data.has("library"):
		var image_path = icon_data.library.left(icon_data.library.rfind("."))+"/"+icon_data.icon+".png"
		var t : ImageTexture
		if image_path.left(6) == "res://":
			image_path = ProjectSettings.globalize_path(image_path)
		t = ImageTexture.new()
		var image : Image = Image.new()
		if image.load(image_path) == OK:
			image.resize(16, 16)
			t.create_from_image(image)
		else:
			print("Cannot load image "+image_path)
		return t
	return null


func add_library(file_name : String, _filter : String = "") -> bool:
	var file = File.new()
	if file.open(file_name, File.READ) != OK:
		return false
	var lib = parse_json(file.get_as_text())
	file.close()
	if lib != null and lib.has("lib"):
		for m in lib.lib:
			m.library = file_name
		libraries.push_back(lib.lib)
		return true
	return false


func _input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if !get_rect().has_point(event.position):
			hide()


func _unhandled_input(event) -> void:
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		hide()
