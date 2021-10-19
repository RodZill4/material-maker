extends ColorRect

export var default_library_item : String

var library_item

onready var library_manager = get_node("/root/MainWindow/NodeLibraryManager")


signal object_selected(obj)


func _ready():
	# Wait main window initialization
	yield(get_tree(), "idle_frame")
	var main_window = get_node("/root/MainWindow")
	if main_window.config_cache.has_section_key("library", "quick_button_%d" % get_index()):
		default_library_item = main_window.config_cache.get_value("library", "quick_button_%d" % get_index())
	set_library_item(default_library_item)

func can_drop_data(position, data):
	return true

func set_library_item(li : String):
	library_item = library_manager.get_item(li)
	if library_item != null:
		material.set_shader_param("tex", library_item.icon)
		hint_tooltip = library_item.item.tree_item

func drop_data(position, data):
	set_library_item(data)
	var main_window = get_node("/root/MainWindow")
	main_window.config_cache.set_value("library", "quick_button_%d" % get_index(), data)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			emit_signal("object_selected", library_item.item)


func _on_QuickButton_mouse_entered():
	material.set_shader_param("brightness", 1.0)

func _on_QuickButton_mouse_exited():
	material.set_shader_param("brightness", 0.8)
