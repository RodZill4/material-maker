extends "res://material_maker/windows/node_editor/node_editor.gd"

onready var preview_editor : TextEdit = $Sizer/Tabs/Preview
onready var export_target : OptionButton = $Sizer/Tabs/Export/Export/Option
onready var export_files : ItemList = $Sizer/Tabs/Export/Edit/Files

var exports : Dictionary = {}

const GEN_MATERIAL = preload("res://addons/material_maker/engine/gen_material.gd")

func _ready():
	preview_editor.add_color_region("//", "", Color(0, 0.5, 0), true)

func update_export_list() -> void:
	export_target.clear()
	for e in exports.keys():
		export_target.add_item(e)

func get_export_index(export_name : String) -> int:
	for i in range(export_target.get_item_count()):
		if export_name == export_target.get_item_text(i):
			return i
	return -1

func _on_Create_pressed():
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
	add_child(dialog)
	var status = dialog.enter_text("Export", "Enter the export target name", "")
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	if status.ok and get_export_index(status.text) == -1:
		exports[status.text] = { files=[] }
		update_export_list()
		select_export(get_export_index(status.text))

func _on_ExtensionEdit_text_entered(new_text):
	var e : String = export_target.get_item_text(export_target.selected)
	exports[e].export_extension = new_text

func select_export(i : int) -> void:
	export_target.selected = i
	var e : String = export_target.get_item_text(i)
	$Sizer/Tabs/Export/Export/ExtensionEdit.text = exports[e].export_extension if exports[e].has("export_extension") else ""
	export_files.clear()
	if ! exports[e].files.empty():
		for f in exports[e].files:
			export_files.add_item(f.file_name)
		select_file(0)
	export_files.add_item("Add file...")

func select_file(i : int) -> void:
	var e : String = export_target.get_item_text(export_target.selected)
	if i == exports[e].files.size():
		exports[e].files.push_back({ file_name="$(path_prefix)_foo.png", type="texture", output=0 })
		export_files.add_item("Add file...")
		export_files.set_item_text(i, "$(path_prefix)_foo.png")
		select_file(i)
	else:
		export_files.select(i)
		var f = exports[e].files[i]
		$Sizer/Tabs/Export/Edit/File/Common/name.text = f.file_name if f.has("file_name") else ""
		$Sizer/Tabs/Export/Edit/File/Common/conditions.text = f.conditions if f.has("conditions") else ""
		$Sizer/Tabs/Export/Edit/File/Common/LabelOutput.visible = (f.type == "texture")
		$Sizer/Tabs/Export/Edit/File/Common/output.visible = (f.type == "texture")
		$Sizer/Tabs/Export/Edit/File/template.visible = (f.type == "template")
		match f.type:
			"texture":
				$Sizer/Tabs/Export/Edit/File/Common/type.select(0)
				$Sizer/Tabs/Export/Edit/File/Common/output.value = f.output
			"template":
				$Sizer/Tabs/Export/Edit/File/Common/type.select(1)
				var file_export_context = {}
				if f.has("file_params"):
					for p in f.file_params.keys():
						file_export_context["$(file_param:"+p+")"] = f.file_params[p]
					f.erase("file_params")
				var template : String = GEN_MATERIAL.process_template(GEN_MATERIAL.get_template_text(f.template), file_export_context)
				if template != f.template:
					f.template = template
				$Sizer/Tabs/Export/Edit/File/template.text = template

func _on_name_text_entered(new_text):
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].file_name = new_text
	export_files.set_item_text(i, new_text)

func _on_conditions_text_entered(new_text):
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].conditions = new_text

func _on_type_item_selected(index):
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
	select_file(i)

func _on_output_value_changed(value):
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].output = int(value)

func _on_template_focus_exited():
	var e : String = export_target.get_item_text(export_target.selected)
	var i = export_files.get_selected_items()[0]
	exports[e].files[i].template = $Sizer/Tabs/Export/Edit/File/template.text


func set_model_data(data) -> void:
	.set_model_data(data)
	if data.has("preview_shader"):
		$Sizer/Tabs/Preview.text = data.preview_shader
	if data.has("exports"):
		exports = data.exports.duplicate()
		update_export_list()
		select_export(0)

func get_model_data() -> Dictionary:
	var data = .get_model_data()
	data.preview_shader = $Sizer/Tabs/Preview.text
	data.exports = exports
	return data








