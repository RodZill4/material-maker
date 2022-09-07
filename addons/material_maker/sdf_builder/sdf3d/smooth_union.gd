extends "res://addons/material_maker/sdf_builder/sdf3d/union.gd"


export var op_sign : String = "-"


func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.z", name="position_z", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Rotation.x", name="angle_x", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.y", name="angle_y", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.z", name="angle_z", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0 },
		{ label="K", name="k", type="float", min=0.0, max=5.0, step=0.01, default=1.0 },
		{ label="ColorK", name="color_k", type="float", min=0.0, max=1.0, step=0.01, default=0.5 }
	]

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	data.code += "float %s = 0.0;" % output_name
	data.code += "float $(name_uv)_n%d_kk = 10.0/$k;" % [ scene.index ]
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
		if data2.has("code"):
			data.code += data2.code
			data.code += "%s += exp2(%s$(name_uv)_n%d_kk*%s);\n" % [ output_name, op_sign, scene.index, data2.outputs[0].sdf3d ] 
	data.code += "%s = %slog2(%s)/$(name_uv)_n%d_kk;\n" % [ output_name, op_sign, output_name, scene.index ] 

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> String:
	var ctxt2 = ctxt.duplicate()
	ctxt2.target = "tmp_%d" % scene.index
	ctxt2.check = false
	var color_code : String = ""
	for s in scene.children:
		var child_color_code = mm_sdf_builder.get_color_code(s, ctxt2, editor)
		if child_color_code != "":
			color_code += child_color_code
			color_code += "\ncoef_%d = 1.0/pow(1.0+max($(name_uv)_n%d, 0.0), 10000.0*pow(0.8-0.3*clamp($color_k, 0.0, 1.0), 10.0));" % [ scene.index, s.index ]
			color_code += "\nsum_%d+=tmp_%d*coef_%d;" % [ scene.index, scene.index, scene.index ]
			color_code += "\ncoefsum_%d += coef_%d;" % [ scene.index, scene.index ]
	if color_code == "":
		return ""
	color_code = ("vec4 sum_%d;\nvec4 tmp_%d;\nfloat coef_%d;\nfloat coefsum_%d = 0.0;\n" % [ scene.index, scene.index, scene.index, scene.index ])+color_code+("%s = sum_%d/coefsum_%d;" % [ ctxt.target, scene.index, scene.index ])
	return "if (_n%d < 0.001) {\n%s}\n" % [ scene.index, color_code ]
