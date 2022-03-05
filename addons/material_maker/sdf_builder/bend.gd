extends "res://addons/material_maker/sdf_builder/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ label="Amount", name="amount", type="float", min=-1.0, max=1.0, step=0.01, default=0.1 }
	]

func get_includes():
	return [ "rotate", "sdbend" ]

func mod_uv_code(output_name : String) -> String:
	return "%s_p = sdBend(%s_p, $amount);\n" % [ output_name, output_name ]
