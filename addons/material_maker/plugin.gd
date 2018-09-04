tool
extends EditorPlugin

var mm_button = null
var material_maker = null

func _enter_tree():
	mm_button = Button.new()
	mm_button.connect("pressed", self, "open_material_maker")
	mm_button.text = "Material Maker"
	add_control_to_container(CONTAINER_TOOLBAR, mm_button)

func _exit_tree():
	if mm_button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, mm_button)
		mm_button.queue_free()
	if material_maker != null:
		material_maker.hide()
		material_maker.queue_free()
		material_maker = null

func _get_state():
	var s = { mm_button=mm_button, material_maker=material_maker }
	return s

func _set_state(s):
	mm_button = s.mm_button
	material_maker = s.material_maker

func open_material_maker():
	if material_maker == null:
		material_maker = preload("res://addons/material_maker/window_dialog.tscn").instance()
		var panel = material_maker.get_node("MainWindow")
		panel.editor_interface = get_editor_interface()
		panel.connect("quit", self, "close_material_maker")
		add_child(material_maker)
	material_maker.popup_centered()

func close_material_maker():
	if material_maker != null:
		material_maker.hide()
		material_maker.queue_free()
		material_maker = null
