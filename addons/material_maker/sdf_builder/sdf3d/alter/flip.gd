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
		{ label="X", name="x_flip", type="boolean", default=true },
		{ label="Y", name="y_flip", type="boolean", default=true },
		{ label="Z", name="z_flip", type="boolean", default=true }
	]

func get_includes():
	return [ "rotate" ]

func mod_uv_code(scene : Dictionary, output_name : String) -> String:
	var code : String = ""
	if scene.parameters.x_flip:
		code += "%s_p.x = -%s_p.x;\n" % [ output_name, output_name ]
	if scene.parameters.y_flip:
		code += "%s_p.y = -%s_p.y;\n" % [ output_name, output_name ]
	if scene.parameters.z_flip:
		code += "%s_p.z = -%s_p.z;\n" % [ output_name, output_name ]
	return code
