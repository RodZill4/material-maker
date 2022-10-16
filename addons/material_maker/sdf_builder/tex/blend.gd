extends "res://addons/material_maker/sdf_builder/base.gd"


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

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false):
	var tex : String
	var ctxt2 : Dictionary = ctxt.duplicate(true)
	ctxt2.type = "rgba"
	if scene.children.empty():
		tex = "$color1"
	else:
		tex = mm_sdf_builder.get_color_code(scene.children[0], ctxt2, editor)
		if scene.children.size() > 1:
			var tex2 : String = mm_sdf_builder.get_color_code(scene.children[1], ctxt2, editor)
			var mask : String = "0.5"
			if scene.children.size() > 2:
				ctxt2.type = "float"
				mask = mm_sdf_builder.get_color_code(scene.children[2], ctxt2, editor)
			tex = "mix("+tex+", "+tex2+", "+mask+")"
	match ctxt.type:
		"rgba":
			return tex
		"color":
			return "("+tex+").xyz" 
		"float":
			return "dot(("+tex+").xyz, vec3(1.0))/3.0"
	return ""
