extends "res://addons/material_maker/sdf_builder/sdf2d/boolean/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.05, control="P1.y" },
		{ label="Radius", name="r", type="float", min=0.0, max=1.0, step=0.01, default=0.45, control="Radius1.r"},
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
	]

func get_includes():
	return [ "sdheart", "rotate" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "sdHeart((%s) / ($r *1.75)) * ($r *1.75)" % [ uv ]
