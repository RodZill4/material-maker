extends "res://addons/material_maker/sdf_builder/sdf2d/boolean/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ label="H", name="h_flip", type="boolean", default=true },
		{ label="V", name="v_flip", type="boolean", default=true }
	]

func get_includes():
	return [ "rotate" ]

func mod_uv_code(scene : Dictionary, output_name : String) -> String:
	var code : String = ""
	if scene.parameters.h_flip:
		code += "%s_p.x = -%s_p.x;\n" % [ output_name, output_name ]
	if scene.parameters.v_flip:
		code += "%s_p.y = -%s_p.y;\n" % [ output_name, output_name ]
	return code
