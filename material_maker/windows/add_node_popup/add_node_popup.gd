extends Popup


onready var list := $PanelContainer/VBoxContainer/ScrollContainer/List
onready var filter : LineEdit = $PanelContainer/VBoxContainer/Filter

var libraries = []
var quick_connect : int = -1
var insert_position : Vector2


func get_current_graph():
	return get_parent().get_current_graph_edit()


func _ready() -> void:
	var lib_path = OS.get_executable_path().get_base_dir()+"/library/base.json"
	if !add_library(lib_path):
		add_library("res://material_maker/library/base.json")
	add_library("user://library/user.json")
	filter.connect("text_changed", self, "update_list")
	filter.connect("text_entered", self, "filter_entered")
	list.connect("object_selected", self, "object_selected")
	update_list()


func filter_entered(_filter) -> void:
	list.select_first()


func add_node(node_data) -> void:
	var node : GraphNode = get_current_graph().create_nodes(node_data, get_current_graph().offset_from_global_position(insert_position))[0]
	if quick_connect_node != null: # dragged from port
#		var type = quick_connect_node.get_connection_output_type(quick_connect_slot)
		for new_slot in node.get_connection_input_count():
			#if type == node.get_connection_input_type(new_slot):
				#connect the first two slots with the same type
			get_current_graph().connect_node(quick_connect_node.name, quick_connect_slot, node.name, new_slot)
			break 
	hide()


func object_selected(obj) -> void:
	add_node(obj)
	hide()


func hide() -> void:
	.hide()
	quick_connect_node = null
	get_current_graph().grab_focus()


func show_popup(qc : int = -1) -> void:
	popup()
	insert_position = rect_position
	quick_connect = qc
	update_list(filter.text if qc == -1 else "")
	filter.grab_focus()
	filter.select_all()


func update_list(filter : String = "") -> void:
	$PanelContainer/VBoxContainer/ScrollContainer.get_v_scrollbar().value = 0.0
	list.clear()
	for library in libraries:
		for obj in library:
			if not obj.has("type"):
				continue
			if quick_connect != -1:
				var ref_obj = obj
				if mm_loader.predefined_generators.has(obj.type):
					ref_obj = mm_loader.predefined_generators[obj.type]
				if ref_obj.has("shader_model"):
					if ! ref_obj.shader_model.has("inputs") or ref_obj.shader_model.inputs.empty():
						continue
					elif mm_io_types.types[ref_obj.shader_model.inputs[0].type].slot_type != quick_connect:
						continue
				elif ref_obj.has("nodes"):
					var input_ports = []
					for n in ref_obj.nodes:
						if n.name == "gen_inputs":
							if n.has("ports"):
								input_ports = n.ports
							break
					if input_ports.empty() or mm_io_types.types[input_ports[0].type].slot_type != quick_connect:
						continue
				elif ref_obj.type == "comment" or ref_obj.type == "image" or ref_obj.type == "remote" or ref_obj.type == "text":
					continue
				elif (ref_obj.type == "debug" or ref_obj.type == "buffer" or ref_obj.type == "export" ) and quick_connect != 0:
					continue
			var show : bool = true
			for f in filter.to_lower().split(" ", false):
				if f != "" && obj.tree_item.to_lower().find(f) == -1:
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


# Quickly connecting == dragging from port
var quick_connect_node : GraphNode
var quick_connect_slot = 0

func set_quick_connect(from, from_slot) -> void:
	quick_connect_node = get_current_graph().get_node(from)
	quick_connect_slot = from_slot


func _input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if !get_rect().has_point(event.position):
			hide()


func _unhandled_input(event) -> void:
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		hide()

