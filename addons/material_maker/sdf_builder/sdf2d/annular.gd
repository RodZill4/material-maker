extends "res://addons/material_maker/sdf_builder/sdf2d/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ label="Width", name="width", type="float", min=0.0, max=0.5, step=0.01, default=0.1, control="Scale1.r" }
	]

func get_includes():
	return [ "rotate" ]

func mod_code(output_name : String) -> String:
	return "%s = abs(%s)-0.5*$width;\n" % [ output_name, output_name ]
