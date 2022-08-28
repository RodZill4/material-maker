extends "res://addons/material_maker/sdf_builder/base.gd"

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

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf2d=output_name, type="sdf2d" } ] }
	data.code = "vec2 %s_p = %s - vec2($position_x, $position_y);\n" % [ output_name, uv ]
	data.code += "%s_p = rotate(%s_p, radians($angle))/$scale;\n" % [ output_name, output_name ]
	data.code += "float %s = 0.0;" % output_name
	var first : bool = true
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
		if data2.has("code"):
			data.code += data2.code
			if first:
				data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf2d ]
				first = false
			else:
				data.code += "%s = max(%s, -(%s));\n" % [ output_name, output_name, data2.outputs[0].sdf2d ] 
	data.code += "%s *= $scale;\n" % [ output_name ]
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> String:
	var color_code : String = ""
	for s in scene.children:
		var child_color_code = mm_sdf_builder.get_color_code(s, ctxt, editor)
		if child_color_code != "":
			color_code += child_color_code+"\n"
	if color_code == "":
		return ""
	return "if (_n%d < 0.0) {\n%s}\n" % [ scene.index, color_code ]
