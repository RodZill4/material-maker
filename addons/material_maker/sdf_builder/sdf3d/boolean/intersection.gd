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
	]

func get_includes():
	return [ "rotate" ]

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	data.code += "float %s = 42.0;" % output_name
	var first : bool = true
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		if data2.has("code"):
			data.parameters.append_array(data2.parameters)
			data.code += data2.code
			if first:
				data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf3d ]
				first = false
			else:
				data.code += "%s = max(%s, %s);\n" % [ output_name, output_name, data2.outputs[0].sdf3d ] 
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
