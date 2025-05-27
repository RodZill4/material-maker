extends "res://addons/material_maker/sdf_builder/sdf3d/boolean/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.z", name="position_z", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Rotation.x", name="angle_x", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.y", name="angle_y", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.z", name="angle_z", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0 },
		{ label="K", name="k", type="float", min=0.0, max=1.0, step=0.01, default=0.5 },
	]

func get_includes():
	return [ "rotate" ]

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	data.code += "float %s = 42.0;" % output_name
	var count : int = 0
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
		if data2.has("code"):
			data.code += data2.code
			if count == 0:
				data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf3d ]
			elif count == 1:
				data.code += "%s *= $k;\n" % [ output_name ]
				data.code += "%s += %s*(1.0-$k);\n" % [ output_name, data2.outputs[0].sdf3d ]
			count += 1
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
