tool
extends WindowDialog

var model_data = null

onready var main_code_editor : TextEdit = $"Sizer/Tabs/Main Code"
onready var instance_functions_editor : TextEdit = $"Sizer/Tabs/Instance Functions"
onready var global_functions_editor : TextEdit = $"Sizer/Tabs/Global Functions"

const ParameterEditor = preload("res://addons/material_maker/widgets/node_editor/parameter.tscn")
const InputEditor = preload("res://addons/material_maker/widgets/node_editor/input.tscn")
const OutputEditor = preload("res://addons/material_maker/widgets/node_editor/output.tscn")

signal node_changed

func _ready() -> void:
	main_code_editor.add_color_region("//", "", Color(0, 0.5, 0), true)
	instance_functions_editor.add_color_region("//", "", Color(0, 0.5, 0), true)
	global_functions_editor.add_color_region("//", "", Color(0, 0.5, 0), true)

func add_item(parent, scene) -> Node:
	var object = scene.instance()
	parent.add_child(object)
	parent.move_child(object, parent.get_child_count()-2)
	return object

func set_model_data(data) -> void:
	if data.has("name"):
		$Sizer/Tabs/General/Name/Name.text = data.name
	if data.has("parameters"):
		for p in data.parameters:
			add_item($Sizer/Tabs/General/Parameters/Sizer, ParameterEditor).set_model_data(p)
	if data.has("inputs"):
		for i in data.inputs:
			add_item($Sizer/Tabs/General/Inputs/Sizer, InputEditor).set_model_data(i)
	if data.has("outputs"):
		for o in data.outputs:
			add_item($Sizer/Tabs/Outputs/Outputs/Sizer, OutputEditor).set_model_data(o)
	if data.has("global"):
		global_functions_editor.text = data.global
	if data.has("instance"):
		instance_functions_editor.text = data.instance
	if data.has("code"):
		main_code_editor.text = data.code

func get_model_data() -> Dictionary:
	var data = {
		name=$Sizer/Tabs/General/Name/Name.text,
		global=global_functions_editor.text,
		instance=instance_functions_editor.text,
		code=main_code_editor.text
	}
	data.parameters = []
	for p in $Sizer/Tabs/General/Parameters/Sizer.get_children():
		if p.has_method("get_model_data"):
			data.parameters.append(p.get_model_data())
	data.inputs = []
	for i in $Sizer/Tabs/General/Inputs/Sizer.get_children():
		if i.has_method("get_model_data"):
			data.inputs.append(i.get_model_data())
	data.outputs = []
	for o in $Sizer/Tabs/Outputs/Outputs/Sizer.get_children():
		if o.has_method("get_model_data"):
			data.outputs.append(o.get_model_data())
	return data

func _on_AddParameter_pressed() -> void:
	add_item($Sizer/Tabs/General/Parameters/Sizer, ParameterEditor)

func _on_AddInput_pressed() -> void:
	add_item($Sizer/Tabs/General/Inputs/Sizer, InputEditor)

func _on_AddOutput_pressed() -> void:
	add_item($Sizer/Tabs/Outputs/Outputs/Sizer, OutputEditor)

func _on_Apply_pressed() -> void:
	emit_signal("node_changed", get_model_data())

func _on_OK_pressed() -> void:
	emit_signal("node_changed", get_model_data())
	queue_free()

func _on_Cancel_pressed() -> void:
	queue_free()
