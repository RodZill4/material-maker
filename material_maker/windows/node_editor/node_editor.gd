extends Window


@onready var parameter_list : VBoxContainer = $Sizer/TabBar/General/Parameters/Sizer
@onready var input_list : VBoxContainer = $Sizer/TabBar/General/Inputs/Sizer
@onready var output_list : VBoxContainer = $Sizer/TabBar/Outputs/Outputs/Sizer

@onready var main_code_editor : CodeEdit = $"Sizer/TabBar/Main Code"
@onready var instance_functions_editor : CodeEdit = $"Sizer/TabBar/Instance Functions"
@onready var includes_editor : LineEdit = $"Sizer/TabBar/Global Functions/Includes/Includes"
@onready var global_functions_editor : CodeEdit = $"Sizer/TabBar/Global Functions/Functions"

@onready var parser = load("res://addons/material_maker/parser/glsl_parser.gd").new()

const ParameterEditor = preload("res://material_maker/windows/node_editor/parameter.tscn")
const InputEditor = preload("res://material_maker/windows/node_editor/input.tscn")
const OutputEditor = preload("res://material_maker/windows/node_editor/output.tscn")


signal node_changed(model_data)
signal editor_window_closed


func add_item(parent, scene) -> Node:
	var object = scene.instantiate()
	parent.add_child(object)
	parent.move_child(object, parent.get_child_count()-2)
	return object

func set_model_data(data) -> void:
	if data.has("name"):
		$Sizer/TabBar/General/Name/Name.text = data.name
	if data.has("shortdesc"):
		$Sizer/TabBar/General/Name/Description.short_description = data.shortdesc
	if data.has("longdesc"):
		$Sizer/TabBar/General/Name/Description.long_description = data.longdesc
	$Sizer/TabBar/General/Name/Description.update_tooltip()
	if data.has("parameters"):
		for p in data.parameters:
			add_item(parameter_list, ParameterEditor).set_model_data(p)
		parameter_list.update_up_down_buttons()
	if data.has("inputs"):
		var group_size = 0
		for i in range(data.inputs.size()):
			var input = data.inputs[i]
			if group_size > 1 && i == data.inputs.size()-1:
				group_size = 1
			group_size = add_item(input_list, InputEditor).set_model_data(input, group_size)
		input_list.update_up_down_buttons()
		PortGroupButton.update_groups(input_list)
	if data.has("outputs"):
		var group_size = 0
		for o in range(data.outputs.size()):
			var output = data.outputs[o]
			if group_size > 1 && o == data.outputs.size()-1:
				group_size = 1
			group_size = add_item(output_list, OutputEditor).set_model_data(output, group_size)
		output_list.update_up_down_buttons()
		PortGroupButton.update_groups(output_list)
	if data.has("includes"):
		includes_editor.text = ",".join(PackedStringArray(data.includes))
	if data.has("global"):
		global_functions_editor.text = data.global
		global_functions_editor.clear_undo_history()
	if data.has("instance"):
		instance_functions_editor.text = data.instance
		instance_functions_editor.clear_undo_history()
	if data.has("code"):
		main_code_editor.text = data.code
		main_code_editor.clear_undo_history()

func get_model_data() -> Dictionary:
	var data = {
		name=$Sizer/TabBar/General/Name/Name.text,
		global=global_functions_editor.text,
		instance=instance_functions_editor.text,
		code=main_code_editor.text
	}
	if $Sizer/TabBar/General/Name/Description.short_description != "":
		data.shortdesc = $Sizer/TabBar/General/Name/Description.short_description
	if $Sizer/TabBar/General/Name/Description.long_description != "":
		data.longdesc = $Sizer/TabBar/General/Name/Description.long_description
	var includes : String = includes_editor.text.replace(" ", "")
	if includes != "":
		data.includes = includes.split(",")
	data.parameters = []
	for p in parameter_list.get_children():
		if p.has_method("get_model_data"):
			data.parameters.append(p.get_model_data())
	data.inputs = []
	for i in input_list.get_children():
		if i.has_method("get_model_data"):
			data.inputs.append(i.get_model_data())
	data.outputs = []
	for o in output_list.get_children():
		if o.has_method("get_model_data"):
			data.outputs.append(o.get_model_data())
	return data

func show_tab(tab : String):
	if tab.left(6) == "output":
		$Sizer/TabBar.current_tab = 1
	elif tab == "main":
		$Sizer/TabBar.current_tab = 2
	elif tab == "instance":
		$Sizer/TabBar.current_tab = 3
	elif tab == "globals":
		$Sizer/TabBar.current_tab = 4

func _on_AddParameter_pressed() -> void:
	add_item(parameter_list, ParameterEditor)
	parameter_list.update_up_down_buttons()

func _on_AddInput_pressed() -> void:
	add_item(input_list, InputEditor)
	input_list.update_up_down_buttons()

func _on_AddOutput_pressed() -> void:
	add_item(output_list, OutputEditor)
	output_list.update_up_down_buttons()

# Global functions

var globals_error_line = -1

func _on_Functions_text_changed():
	var text : String = global_functions_editor.text
	var error_label = $"Sizer/TabBar/Global Functions/Functions/ErrorLabel"
	if globals_error_line != -1:
		global_functions_editor.set_line_as_executing(globals_error_line, false)
		error_label.visible = false
	var result = parser.parse(global_functions_editor.text)
	if result is Dictionary and result.has("status"):
		match result.status:
			"OK":
				globals_error_line = -1
				if result.non_terminal != "translation_unit":
					error_label.visible = true
					error_label.text = "GLSL position unit expected (found %s)" % result.non_terminal
			_:
				globals_error_line = text.substr(0, result.pos).count("\n")
				global_functions_editor.set_line_as_executing(globals_error_line, true)
				error_label.visible = true
				error_label.text = "Syntax error line "+str(globals_error_line+1)+": "+result.msg

func _on_Sizer_minimum_size_changed():
	size = $Sizer.size+Vector2(4, 4)

# OK/Apply/Cancel buttons

func _on_Apply_pressed() -> void:
	emit_signal("node_changed", get_model_data())

func _on_OK_pressed() -> void:
	emit_signal("node_changed", get_model_data())
	_on_Cancel_pressed()

func _on_Cancel_pressed() -> void:
	emit_signal("editor_window_closed")
	queue_free()
