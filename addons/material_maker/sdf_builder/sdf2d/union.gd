extends Node

export var item_type : String
export var item_category : String
export var icon : Texture

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
	]

func get_includes():
	return [ "rotate" ]

func shape_code_pre(scene : Dictionary, uv : String = "$uv") -> String:
	return ""

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return ""

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	var assigned : bool = false
	data.code += "float %s;\n" % output_name
	var init_value = shape_code(scene, uv)
	if init_value != "":
		data.code += shape_code_pre(scene, uv)
		data.code += "%s = %s;\n" % [ output_name, init_value ]
		assigned = true
	if editor:
		data.code += "if (index == -%d) return %s*$scale;\n" % [ scene.index, output_name ]
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, uv, editor)
		if not data2.empty():
			data.parameters.append_array(data2.parameters)
			data.code += data2.code
			if assigned:
				data.code += "%s = min(%s, %s);\n" % [ output_name, output_name, data2.outputs[0].sdf2d ]
			else:
				data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf2d ]
				assigned = true

func mod_uv_code(_scene : Dictionary, output_name : String) -> String:
	return ""

func mod_code(output_name : String) -> String:
	return ""

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf2d=output_name, type="sdf2d" } ] }
	mm_sdf_builder.add_parameters(scene, data, get_parameter_defs())
	data.code = "vec2 %s_p = %s - vec2($position_x, $position_y);\n" % [ output_name, uv ]
	data.code += "%s_p = rotate(%s_p, radians($angle))/$scale;\n" % [ output_name, output_name ]
	data.code += mod_uv_code(scene, output_name)
	shape_and_children_code(scene, data, "%s_p" % output_name, editor)
	data.code += mod_code(output_name)
	data.code += "%s *= $scale;\n" % output_name
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data
