extends "res://addons/material_maker/sdf_builder/base.gd"


func _ready():
	pass # Replace with function body.

func get_children_types():
	return [ "TEX" ]

func get_parameter_defs():
	return [
		{ label="Color 1", name="color1", type="color", default={ r=0.0, g=0.0, b=0.0, a=1.0 } },
		{ label="Color 2", name="color2", type="color", default={ r=1.0, g=1.0, b=1.0, a=1.0 } }
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

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> Dictionary:
	var tex : String
	var ctxt2 : Dictionary = ctxt.duplicate(true)
	ctxt2.type = "float"
	if scene.children.is_empty():
		tex = "$color1"
	else:
		tex = "mix($color1, $color2, "+mm_sdf_builder.get_color_code(scene.children[0], ctxt2, editor).color+")"
	match ctxt.type:
		"color":
			tex = "("+tex+").xyz" 
		"float":
			tex = "dot(("+tex+").xyz, vec3(1.0))/3.0"
	return { color = tex }
