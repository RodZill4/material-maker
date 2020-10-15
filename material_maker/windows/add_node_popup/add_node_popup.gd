extends Popup

var libraries = []
var data = []
onready var itemlist : ItemList = $PanelContainer/VBoxContainer/ItemList 
onready var filter_line_edit : LineEdit = $PanelContainer/VBoxContainer/Filter
var quick_connect : int = -1
var insert_position : Vector2

func get_current_graph():
	return get_parent().get_current_graph_edit()

func _ready() -> void:
	var lib_path = OS.get_executable_path().get_base_dir()+"/library/base.json"
	if !add_library(lib_path):
		add_library("res://material_maker/library/base.json")
	add_library("user://library/user.json")
	filter_line_edit.connect("text_changed", self, "update_list")
	filter_line_edit.connect("text_entered", self, "filter_entered")
	itemlist.connect("item_selected", self, "item_selected")
	itemlist.connect("item_activated", self, "item_selected")
	update_list()

func filter_entered(_filter) -> void:
	item_selected(0)

func add_node(node_data) -> void:
	var node : GraphNode = get_current_graph().create_nodes(node_data, get_current_graph().offset_from_global_position(insert_position))[0]
	# if this node created by dragging to an empty space
	if quick_connect_node != null:
#		var type = quick_connect_node.get_connection_output_type(quick_connect_slot)
		for new_slot in node.get_connection_input_count():
			#if type == node.get_connection_input_type(new_slot):
				#connect the first two slots with the same type
			get_current_graph().connect_node(quick_connect_node.name, quick_connect_slot, node.name, new_slot)
			break 
	quick_connect_node = null
	hide()

func item_selected(index) -> void:
	# checks if mouse left | enter pressed. it prevents
	# adding nodes just by using arrow keys as it selects the item 
	if Input.is_mouse_button_pressed(BUTTON_LEFT) || Input.is_key_pressed(KEY_ENTER):
		if (index>=itemlist.get_item_count()):
			return
		if (itemlist.is_item_selectable(index) == false):
			item_selected(index+1)
			return
		add_node(data[index])
		hide()

func hide() -> void:
	.hide()
	
	# clearing the quick connect data after hiding to prevent unintended autoconnection
	quick_connect_node = null
	
	# grabbing the focus for the graph again as creating popup removes the focus.
	get_current_graph().grab_focus()
	
	clear()

func show_popup(qc : int = -1) -> void:
	show()
	quick_connect = qc
	update_list()
	filter_line_edit.grab_focus()
	var parent_rect = get_current_graph().get_global_rect()
	var clipped = parent_rect.clip(get_global_rect())
	var offset =  (get_rect().size-clipped.size)
	insert_position = rect_position
	rect_position = rect_position - offset

func update_list(filter : String = "") -> void:
	clear_list()
	data.clear()
	for library in libraries:
		for obj in library:
			if !obj.has("type"):
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
				data.append(obj)
				itemlist.add_item(obj.tree_item, get_preview_texture(obj))

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

func clear_list() -> void:
	itemlist.clear()

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

# Quickly connecting when tried to connect to empty
var quick_connect_node : GraphNode
var quick_connect_slot = 0

func set_quick_connect(from, from_slot) -> void:
	quick_connect_node = get_current_graph().get_node(from)
	quick_connect_slot = from_slot

func _input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		if !get_rect().has_point(event.position):
			clear()
			hide()

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		clear()
		hide()

func clear() -> void:
	filter_line_edit.text = ""

func _on_itemlist_focus_entered() -> void:
	# if itemlist received focus and no item is yet selected
	# select the first item
	if itemlist.get_selected_items().size() == 0:
		itemlist.select(0)
