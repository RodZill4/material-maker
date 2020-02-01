extends Popup

var libraries = []
var data = []
onready var itemlist : ItemList = $PanelContainer/VBoxContainer/ItemList 
onready var filter_line_edit : LineEdit = $PanelContainer/VBoxContainer/Filter
var insert_position : Vector2

func get_current_graph():
	return get_parent().get_current_tab_control()

func _ready() -> void:
	var lib_path = OS.get_executable_path().get_base_dir()+"/library/base.json"
	if !add_library(lib_path):
		add_library("res://material_maker/library/base.json")
	add_library("user://library/user.json")
	filter_line_edit.connect("text_changed" ,self,"update_list")
	filter_line_edit.connect("text_entered",self,"filter_entered")
	itemlist.connect("item_selected",self,"item_selected")
	itemlist.connect("item_activated",self,"item_selected")
	update_list()

func filter_entered(filter) -> void:
	item_selected(0)

func add_node(data) -> void:
	var node : GraphNode = get_current_graph().create_nodes(data, get_current_graph().offset_from_global_position(insert_position))[0]
	hide()
	clear()
	# if this node created by dragging to an empty space
	if quick_connect_node != null:
		var type = quick_connect_node.get_connection_output_type(quick_connect_slot)
		for new_slot in node.get_connection_input_count():
			if type == node.get_connection_input_type(new_slot):
				#connect the first two slots with the same type
				get_current_graph().connect_node(quick_connect_node.name, quick_connect_slot, node.name, new_slot)
				break 
	quick_connect_node = null

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
		clear()

func show() -> void:
	.show()
	update_list()
	filter_line_edit.grab_focus()
	var parent_rect = get_parent().get_parent().get_global_rect()
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
			var show : bool = true
			for f in filter.to_lower().split(" ", false):
				if f != "" && obj.tree_item.to_lower().find(f) == -1:
					show = false
					break
			if show:
				data.append(obj)
				itemlist.add_item(obj.tree_item, get_preview_texture(obj))

func get_preview_texture(data : Dictionary) -> ImageTexture:
	if data.has("icon") and data.has("library"):
		var image_path = data.library.left(data.library.rfind("."))+"/"+data.icon+".png"
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

func add_library(file_name : String, filter : String = "") -> bool:
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
