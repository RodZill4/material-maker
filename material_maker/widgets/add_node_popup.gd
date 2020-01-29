extends Popup

var libraries = []
var data = []
onready var itemlist : ItemList = $PanelContainer/VBoxContainer/ItemList 
onready var filter_line_edit : LineEdit = $PanelContainer/VBoxContainer/Filter

func _ready() -> void:
	
	var lib_path = OS.get_executable_path().get_base_dir()+"/library/base.json"
	if !add_library(lib_path):
		add_library("res://material_maker/library/base.json")
	add_library("user://library/user.json")
	
	
	filter_line_edit.connect("text_changed" ,self,"update_list")
	filter_line_edit.connect("text_entered",self,"filter_entered")
	itemlist.connect("item_activated",self,"item_activated")
	
	update_list()

func filter_entered(filter):
	item_activated(0)
#func get_selected_item_name() -> String:
#	return get_item_path(itemlist.get_selected())
func item_activated(index):
	if (index>=itemlist.get_item_count()):
		return
	if (itemlist.is_item_selectable(index) == false):
		item_activated(index+1)
		return
	get_parent().create_nodes(data[index],get_parent().offset_from_global_position(get_global_transform().xform(get_local_mouse_position())))
	hide()
	clear()
	pass
func show():
	.show()
	filter_line_edit.grab_focus()
func update_list(filter=""):
	clear_list()
	data.clear()
	for library in libraries:
		for obj in library:
	
			if (obj.tree_item.to_lower().find(filter)!=-1 || filter == ""):
				data.append(obj)
				itemlist.add_item(obj.tree_item.split("/")[-1],get_preview_texture(obj),obj.has("type"))


func get_preview_texture(data : Dictionary) -> ImageTexture:
	if data.has("icon") and data.has("library"):
		var image_path = data.library.left(data.library.rfind("."))+"/"+data.icon+".png"
		var t : ImageTexture
		if image_path.left(6) == "res://":
			image_path = ProjectSettings.globalize_path(image_path)
		t = ImageTexture.new()
		var image : Image = Image.new()
		if image.load(image_path) == OK:
			t.create_from_image(image)
		else:
			print("Cannot load image "+image_path)
		return t
	return null
	
	
func clear_list():
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


func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		if !get_rect().has_point(event.position):
			clear()
			hide()
			
func _unhandled_input(event):
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		clear()
		hide()
	
func clear():
	filter_line_edit.text = ""
	update_list()