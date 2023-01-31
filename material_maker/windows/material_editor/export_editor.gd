extends WindowDialog


onready var export_target : OptionButton = $MarginContainer/VBoxContainer/Export/Option
onready var export_external_button : Button = $MarginContainer/VBoxContainer/Export/External
onready var export_extension_edit : LineEdit = $MarginContainer/VBoxContainer/Export/ExtensionEdit

onready var export_files : ItemList = $MarginContainer/VBoxContainer/Tabs/Files/Files
onready var export_file_name : LineEdit = $MarginContainer/VBoxContainer/Tabs/Files/File/Common/name
onready var export_file_prompt_overwrite : CheckBox = $MarginContainer/VBoxContainer/Tabs/Files/File/Common/prompt_overwrite
onready var export_file_conditions : LineEdit = $MarginContainer/VBoxContainer/Tabs/Files/File/Common/conditions
onready var export_file_label_expression : Label = $MarginContainer/VBoxContainer/Tabs/Files/File/Common/LabelExpression
onready var export_file_expression : LineEdit = $MarginContainer/VBoxContainer/Tabs/Files/File/Common/expression
onready var export_file_type : OptionButton = $MarginContainer/VBoxContainer/Tabs/Files/File/Common/type
onready var export_file_template : TextEdit = $MarginContainer/VBoxContainer/Tabs/Files/File/template
onready var export_custom_script : TextEdit = $"MarginContainer/VBoxContainer/Tabs/Custom Script"

var data : Dictionary = {}
var exports : Dictionary = {}


const GEN_MATERIAL = preload("res://addons/material_maker/engine/gen_material.gd")


signal node_changed(model_data)
signal editor_window_closed


# Called when the node enters the scene tree for the first time.
func _ready():
	export_file_expression.parent_dialog = self

func update_export_list() -> void:
	export_target.clear()
	for e in exports.keys():
		export_target.add_item(e)

func get_export_index(export_name : String) -> int:
	for i in range(export_target.get_item_count()):
		if export_name == export_target.get_item_text(i):
			return i
	return -1

func select_export(i : int) -> void:
	if export_target.get_item_count() <= i:
		export_files.clear()
		select_file(-1)
		return
	export_target.selected = i
	var e : String = export_target.get_item_text(i)
	export_external_button.pressed = exports[e].has("external") and exports[e].external
	export_extension_edit.text = exports[e].export_extension if exports[e].has("export_extension") else ""
	export_custom_script.text = exports[e].custom if exports[e].has("custom") else ""
	update_files(e)

func update_files(e : String):
	export_files.clear()
	if ! exports[e].files.empty():
		for f in exports[e].files:
			export_files.add_item(f.file_name)
		select_file(0)
	export_files.add_item("Add file...")

func select_file(i : int) -> void:
	if i < 0:
		export_file_name.text = ""
		export_file_prompt_overwrite.pressed = false
		export_file_conditions.text = ""
		export_file_label_expression.visible = false
		export_file_expression.visible = false
		export_file_template.visible = false
		return
	var e : String = export_target.get_item_text(export_target.selected)
	if i == exports[e].files.size():
		exports[e].files.push_back({ file_name="$(path_prefix)_foo.png", type="texture", output=0 })
		export_files.add_item("Add file...")
		export_files.set_item_text(i, "$(path_prefix)_foo.png")
		select_file(i)
	else:
		export_files.select(i)
		var f = exports[e].files[i]
		export_file_name.text = f.file_name if f.has("file_name") else ""
		export_file_prompt_overwrite.pressed = f.prompt_overwrite if f.has("prompt_overwrite") else false
		export_file_conditions.text = f.conditions if f.has("conditions") else ""
		export_file_label_expression.visible = (f.type == "texture")
		export_file_expression.visible = (f.type == "texture")
		export_file_template.visible = (f.type == "template" || f.type == "buffer_templates")
		match f.type:
			"texture":
				export_file_type.select(0)
				export_file_expression.text = str(f.output) if f.has("output") else f.expression
			"template","buffer_templates":
				export_file_type.select(1 if f.type == "template" else 3)
				var file_export_context = {}
				if f.has("file_params"):
					for p in f.file_params.keys():
						file_export_context["$(file_param:"+p+")"] = f.file_params[p]
					f.erase("file_params")
				var template : String = GEN_MATERIAL.process_template(GEN_MATERIAL.get_template_text(f.template), file_export_context)
				if template != f.template:
					f.template = template
				export_file_template.text = template
				export_file_template.clear_undo_history()
			"buffers":
				export_file_type.select(2)

func _on_Create_Export_pressed():
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
	add_child(dialog)
	var status = dialog.enter_text("Export", "Enter the export target name", "")
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	if status.ok and get_export_index(status.text) == -1:
		exports[status.text] = { files=[] }
		update_export_list()
		select_export(get_export_index(status.text))

func _on_Load_Export_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILES
	dialog.window_title = "Load export target from file"
	dialog.add_filter("*.mme;Material Maker Export target")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		var last_export_name : String = ""
		for i in files.size():
			var file : File = File.new()
			if file.open(files[0], File.READ) != OK:
				return
			var export_data = parse_json(file.get_as_text())
			if export_data.has("name") and export_data.has("files"):
				export_data.external = true
				exports[export_data.name] = export_data
				last_export_name = export_data.name
		if last_export_name != "":
			update_export_list()
			select_export(get_export_index(last_export_name))

func _on_Save_Export_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.window_title = "Save export target to file"
	dialog.add_filter("*.mme;Material Maker Export target")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		var export_name : String = export_target.get_item_text(export_target.selected)
		var export_data : Dictionary = exports[export_name].duplicate()
		if data.has("template_name"):
			export_data.material = data.template_name
		var file : File = File.new()
		if file.open(files[0], File.WRITE) != OK:
			return
		file.store_string(JSON.print(export_data))

func _on_Rename_Export_pressed():
	var old_export_index = export_target.selected
	if old_export_index < 0:
		return
	var old_export : String = export_target.get_item_text(old_export_index)
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
	add_child(dialog)
	var status = dialog.enter_text("Export", "Enter the export target name", old_export)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	if status.ok and get_export_index(status.text) == -1:
		if get_export_index(status.text) != -1:
			return
		exports[status.text] = exports[old_export]
		exports[status.text].name = status.text
		exports.erase(old_export)
		update_export_list()
		select_export(get_export_index(status.text))

func _on_External_toggled(button_pressed):
	var export_index : int= export_target.selected
	var export_name : String = export_target.get_item_text(export_index)
	if button_pressed:
		exports[export_name].external = true
	else:
		exports[export_name].erase("external")

func _on_Duplicate_Export_pressed():
	var old_export_index = export_target.selected
	if old_export_index < 0:
		return
	var old_export : String = export_target.get_item_text(old_export_index)
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
	add_child(dialog)
	var status = dialog.enter_text("Export", "Enter the export target name", old_export)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	if status.ok and get_export_index(status.text) == -1:
		if get_export_index(status.text) != -1:
			return
		exports[status.text] = exports[old_export].duplicate(true)
		update_export_list()
		select_export(get_export_index(status.text))

func _on_Delete_Export_pressed():
	var export_name : String = export_target.get_item_text(export_target.selected)
	exports.erase(export_name)
	update_export_list()
	select_export(0)

func _on_ExportExtensionEdit_text_entered(new_text):
	var e : String = export_target.get_item_text(export_target.selected)
	exports[e].export_extension = new_text

func _on_ExportExtensionEdit_focus_exited():
	_on_ExportExtensionEdit_text_entered(export_extension_edit.text)

func _on_Custom_Script_focus_exited():
	var e : String = export_target.get_item_text(export_target.selected)
	exports[e].custom = export_custom_script.text

func _on_Files_gui_input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_DELETE:
		if ! export_files.get_selected_items().empty():
			var current_export = export_target.get_item_text(export_target.selected)
			exports[current_export].files.remove(export_files.get_selected_items()[0])
			update_files(current_export)
			export_files.unselect_all()

func _on_name_text_entered(new_text):
	if export_files.get_selected_items().empty():
		return
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].file_name = new_text
	export_files.set_item_text(i, new_text)

func _on_name_focus_exited():
	_on_name_text_entered(export_file_name.text)

func _on_prompt_overwrite_toggled(button_pressed):
	if export_files.get_selected_items().empty():
		return
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].prompt_overwrite = button_pressed

func _on_conditions_text_entered(new_text):
	if export_files.get_selected_items().empty():
		return
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].conditions = new_text

func _on_conditions_focus_exited():
	_on_conditions_text_entered(export_file_conditions.text)

func _on_type_item_selected(index):
	if export_files.get_selected_items().empty():
		return
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	match index:
		0:
			exports[e].files[i].type = "texture"
			exports[e].files[i].output = 0
			exports[e].files[i].erase("template")
		1:
			exports[e].files[i].type = "template"
			exports[e].files[i].template = ""
			exports[e].files[i].erase("output")
		2:
			exports[e].files[i].type = "buffers"
			exports[e].files[i].erase("template")
			exports[e].files[i].erase("output")
		3:
			exports[e].files[i].type = "buffer_templates"
			exports[e].files[i].template = ""
			exports[e].files[i].erase("output")
	select_file(i)

func _on_expression_value_changed(value):
	if export_files.get_selected_items().empty():
		return
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].output = int(value)

func get_expression_from_output(text : String) -> String:
	if text.is_valid_integer():
		var index = text.to_int()
		if data.has("outputs") and data.outputs.size() > index:
			var output = data.outputs[index]
			return output[output.type]
		return ""
	return text

func _on_expression_text_entered(new_text : String):
	if export_files.get_selected_items().empty():
		return
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	if new_text.is_valid_integer():
		exports[e].files[i].output = new_text.to_int()
		exports[e].files[i].erase("expression")
	else:
		exports[e].files[i].expression = new_text
		exports[e].files[i].erase("output")

func _on_expression_focus_exited():
	_on_expression_text_entered(export_file_expression.text)


func _on_template_focus_exited():
	if export_files.get_selected_items().empty():
		return
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].template = export_file_template.text


func set_model_data(d) -> void:
	data = d.duplicate(true)
	if ! data.has("template_name"):
		export_external_button.visible = false
	if data.has("exports"):
		exports = data.exports
		update_export_list()
		select_export(0)

func get_model_data() -> Dictionary:
	data.erase("template_name")
	data.exports = exports
	return data


func _on_MarginContainer_minimum_size_changed():
	rect_min_size = $MarginContainer.get_minimum_size()


# OK/Apply/Cancel buttons

func _on_Apply_pressed() -> void:
	emit_signal("node_changed", get_model_data())

func _on_OK_pressed() -> void:
	_on_Apply_pressed()
	_on_Cancel_pressed()

func _on_Cancel_pressed() -> void:
	emit_signal("editor_window_closed")
	queue_free()
