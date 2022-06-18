extends ColorRect

export var default_library_item : String

var library_item
var disabled : bool = false

onready var library_manager = get_node("/root/MainWindow/NodeLibraryManager")


signal object_selected(obj)


func _ready():
	# Wait main window initialization
	yield(get_tree(), "idle_frame")
	if mm_globals.config.has_section_key("library", "quick_button_%d" % get_index()):
		default_library_item = mm_globals.config.get_value("library", "quick_button_%d" % get_index())
	set_library_item(default_library_item)

func can_drop_data(_position, _data):
	return true

func set_library_item(li : String):
	library_item = library_manager.get_item(li)
	if library_item != null:
		material.set_shader_param("tex", library_item.icon)
		hint_tooltip = library_item.item.tree_item

func drop_data(_position, data):
	set_library_item(data)
	mm_globals.config.set_value("library", "quick_button_%d" % get_index(), data)

func _on_gui_input(event):
	if !disabled and event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			emit_signal("object_selected", library_item.item)

func enable() -> void:
	disabled = false
	material.set_shader_param("disabled", false)

func disable() -> void:
	disabled = true
	material.set_shader_param("disabled", true)

func _on_QuickButton_mouse_entered():
	if ! disabled:
		material.set_shader_param("brightness", 1.0)

func _on_QuickButton_mouse_exited():
	if ! disabled:
		material.set_shader_param("brightness", 0.8)
