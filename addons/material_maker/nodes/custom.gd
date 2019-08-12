tool
extends "res://addons/material_maker/nodes/node_generic.gd"

func _on_Edit_pressed():
	var edit_window = load("res://addons/material_maker/widgets/node_editor/node_editor.tscn").instance()
	get_parent().add_child(edit_window)
	if model_data != null:
		edit_window.set_model_data(model_data)
	edit_window.connect("node_changed", self, "update_node")
	edit_window.popup_centered()

func _on_Load_pressed():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.mmn;Material Maker Node")
	dialog.connect("file_selected", self, "do_load_node")
	dialog.popup_centered()

func do_load_node(file_name):
	set_model(file_name)

func _on_Save_pressed():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.mmn;Material Maker Node")
	dialog.connect("file_selected", self, "do_save_node")
	dialog.popup_centered()

func do_save_node(file_name):
	var file = File.new()
	if file.open(file_name, File.WRITE) == OK:
		file.store_string(to_json(model_data))
		file.close()
		model = file_name

func deserialize(data):
	if data.has("model_data"):
		update_node(data.model_data)
	.deserialize(data)
	
func serialize():
	var file = model
	model = "custom"
	var return_value = .serialize()
	model = file
	return_value.model_data = model_data
	return return_value
