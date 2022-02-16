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

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "float $(name_uv)_n%d = 0.0;" % scene.index

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	data.code += shape_code(scene, uv)
	if editor:
		data.code += "if (index == -%d) return %s;\n" % [ scene.index, output_name ]
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		data.parameters.append_array(data2.parameters)
		data.code += data2.code
		data.code += "%s = min(%s, %s);\n" % [ output_name, output_name, data2.outputs[0].sdf2d ] 
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf2d=output_name, type="sdf2d" } ] }
	for p in get_parameter_defs():
		p = p.duplicate(true)
		p.name = "n%d_%s" % [ scene.index, p.name ]
		data.parameters.push_back(p)
	data.code = "vec2 %s_p = %s - vec2($n%d_position_x, $n%d_position_y);\n" % [ output_name, uv, scene.index, scene.index ]
	data.code += "%s_p = rotate(%s_p, radians($n%d_angle))/$n%d_scale;\n" % [ output_name, output_name, scene.index, scene.index ]
	shape_and_children_code(scene, data, "%s_p" % output_name, editor)
	data.code += "%s *= $n%d_scale;\n" % [ output_name, scene.index ]
	return data
