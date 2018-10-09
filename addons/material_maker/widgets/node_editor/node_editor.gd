tool
extends WindowDialog

var model_data = null

const ParameterEditor = preload("res://addons/material_maker/widgets/node_editor/parameter.tscn")
const InputEditor = preload("res://addons/material_maker/widgets/node_editor/input.tscn")
const OutputEditor = preload("res://addons/material_maker/widgets/node_editor/output.tscn")

signal node_changed

func add_item(parent, scene):
	var object = scene.instance()
	parent.add_child(object)
	parent.move_child(object, parent.get_child_count()-2)
	return object

func set_model_data(data):
	if data.has("name"):
		$Sizer/Tabs/General/Name/Name.text = data.name
	if data.has("parameters"):
		for p in data.parameters:
			add_item($Sizer/Tabs/General/Parameters/Sizer, ParameterEditor).set_model_data(p)
	if data.has("outputs"):
		for o in data.outputs:
			add_item($Sizer/Tabs/General/Outputs/Sizer, OutputEditor).set_model_data(o)
	if data.has("global"):
		$Sizer/Tabs/Global.text = data.global
	if data.has("instance"):
		$Sizer/Tabs/Instance.text = data.instance

func get_model_data():
	var data = {
		name=$Sizer/Tabs/General/Name/Name.text,
		global=$Sizer/Tabs/Global.text,
		instance=$Sizer/Tabs/Instance.text,
	}
	data.parameters = []
	for p in $Sizer/Tabs/General/Parameters/Sizer.get_children():
		if p.has_method("get_model_data"):
			data.parameters.append(p.get_model_data())
	data.outputs = []
	for o in $Sizer/Tabs/General/Outputs/Sizer.get_children():
		if o.has_method("get_model_data"):
			data.outputs.append(o.get_model_data())
	return data

func _on_AddParameter_pressed():
	add_item($Sizer/Tabs/General/Parameters/Sizer, ParameterEditor)

func _on_AddInput_pressed():
	add_item($Sizer/Tabs/General/Inputs/Sizer, InputEditor)

func _on_AddOutput_pressed():
	add_item($Sizer/Tabs/General/Outputs/Sizer, OutputEditor)

func _on_OK_pressed():
	emit_signal("node_changed", get_model_data())
	queue_free()

func _on_Cancel_pressed():
	queue_free()
