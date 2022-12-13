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

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> Dictionary:
	return get_color_code_smooth_union(scene, ctxt, editor)
