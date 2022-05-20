extends "res://addons/material_maker/sdf_builder/sdf2d/union.gd"

func _ready():
	pass # Replace with function body.

func get_children_types():
	return [ "SDF2D" ]

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.z", name="position_z", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Rotation.x", name="angle_x", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.y", name="angle_y", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.z", name="angle_z", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0 },
		{ label="Length", name="length", type="float", min=0.0, max=1.0, step=0.01, default=0.5 }
	]

func get_includes():
	return [ "sdf3d_rotate" ]

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf3d=output_name, type="sdf3d" } ] }
	mm_sdf_builder.add_parameters(scene, data, get_parameter_defs())
	data.code = "vec3 %s_p = %s - vec3($position_x, $position_y, $position_z);\n" % [ output_name, uv ]
	data.code += mm_sdf_builder.generate_rotate_3d("%s_p" % output_name, scene)
	data.code += "%s_p /= $scale;\n" % [ output_name ]
	shape_and_children_code(scene, data, "%s_p.xy" % output_name, editor)
	data.code += "vec2 %s_w = vec2(%s, abs(%s_p.z) - $length);\n" % [ output_name, output_name, output_name ]
	data.code += "%s = min(max(%s_w.x, %s_w.y),0.0) + length(max(%s_w,0.0))*$scale;\n" % [ output_name, output_name, output_name, output_name ] 
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data
