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

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return ""

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	var assigned : bool = false
	data.code += "float %s;\n" % output_name
	var init_value = shape_code(scene, uv)
	if init_value != "":
		data.code += "%s = %s;\n" % [ output_name, init_value ]
		assigned = true
	if editor:
		data.code += "if (index == -%d) return %s*$scale;\n" % [ scene.index, output_name ]
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		if not data2.empty():
			data.parameters.append_array(data2.parameters)
			data.code += data2.code
			if assigned:
				data.code += "%s = min(%s, %s);\n" % [ output_name, output_name, data2.outputs[0].sdf3d ]
			else:
				data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf3d ]
				assigned = true
	if ! assigned:
		data.code += "%s = 1000000.0;\n" % [ output_name ]

func mod_uv_code(_scene : Dictionary, output_name : String) -> String:
	return ""

func mod_code(output_name : String) -> String:
	return ""

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf3d=output_name, type="sdf3d" } ] }
	mm_sdf_builder.add_parameters(scene, data, get_parameter_defs())
	data.code = "vec3 %s_p = %s - vec3($position_x, $position_y, $position_z);\n" % [ output_name, uv ]
	data.code += mm_sdf_builder.generate_rotate_3d("%s_p" % output_name, scene)
	data.code += "%s_p /= $scale;\n" % [ output_name ]
	data.code += mod_uv_code(scene, output_name)
	shape_and_children_code(scene, data, "%s_p" % output_name, editor)
	data.code += mod_code(output_name)
	data.code += "%s *= $scale;\n" % output_name
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data
