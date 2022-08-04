extends "res://addons/material_maker/sdf_builder/sdf2d/union.gd"

export var channel_name : String
export(int, "greyscale", "rgba") var type : int

func _ready():
	pass # Replace with function body.

func get_children_types():
	return [ "TEX" ]

func get_parameter_defs():
	return [
	]

func get_includes():
	return [ ]

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var data : Dictionary = { parameters=[] }
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, uv, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
	return data
