extends Node

export var item_type : String
export var item_category : String
export var icon : Texture

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

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf3d=output_name, type="sdf3d" } ] }
	data.code = "vec3 %s_p = %s - vec3($position_x, $position_y, $position_z);\n" % [ output_name, uv ]
	data.code += mm_sdf_builder.generate_rotate_3d("%s_p" % output_name, scene)
	data.code += "%s_p /= $scale;\n" % [ output_name ]
	data.code += "float %s = 0.0;" % output_name
	var first : bool = true
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		if not data2.empty():
			data.parameters.append_array(data2.parameters)
			data.code += data2.code
			if first:
				data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf3d ]
				first = false
			else:
				data.code += "%s = max(%s, -(%s));\n" % [ output_name, output_name, data2.outputs[0].sdf3d ] 
	data.code += "%s *= $scale;\n" % [ output_name ]
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data
