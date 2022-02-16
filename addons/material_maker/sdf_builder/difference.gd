extends Node

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
	]

func get_includes():
	return [ "rotate" ]

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf2d=output_name, type="sdf2d" } ] }
	for p in get_parameter_defs():
		p = p.duplicate(true)
		p.name = "n%d_%s" % [ scene.index, p.name ]
		data.parameters.push_back(p)
	data.code = "vec2 %s_p = %s - vec2($n%d_position_x, $n%d_position_y);\n" % [ output_name, uv, scene.index, scene.index ]
	data.code += "%s_p = rotate(%s_p, radians($n%d_angle))/$n%d_scale;\n" % [ output_name, output_name, scene.index, scene.index ]
	data.code += "float %s = 0.0;" % output_name
	var first : bool = true
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		data.parameters.append_array(data2.parameters)
		data.code += data2.code
		if first:
			data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf2d ]
			first = false
		else:
			data.code += "%s = max(%s, -(%s));\n" % [ output_name, output_name, data2.outputs[0].sdf2d ] 
	data.code += "%s *= $n%d_scale;\n" % [ output_name, scene.index ]
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data
