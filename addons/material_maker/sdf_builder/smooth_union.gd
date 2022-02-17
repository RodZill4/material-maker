extends "res://addons/material_maker/sdf_builder/union.gd"

func get_parameter_defs():
	return [
		{ name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ name="k", type="float", min=0.0, max=5.0, step=0.01, default=1.0, control="Scale1.r" }
	]

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	data.code += "float %s = 0.0;" % output_name
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		data.parameters.append_array(data2.parameters)
		data.code += data2.code
		data.code += "%s += exp2(-$n%d_k*%s);\n" % [ output_name, scene.index, data2.outputs[0].sdf2d ] 
	data.code += "%s = -log2(%s)/$n%d_k;\n" % [ output_name, output_name, scene.index ] 
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
