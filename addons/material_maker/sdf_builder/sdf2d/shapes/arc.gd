extends "res://addons/material_maker/sdf_builder/sdf2d/boolean/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Angle 1", name="a1", type="float", min=-180.0, max=180.0, step=1.0, default=50.0, control="Angle1.a"},
		{ label="Angle 2", name="a2", type="float", min=-180.0, max=180.0, step=1.0, default=-90.0, control="Angle2.a"},
		{ label="Radius", name="r1", type="float", min=0.0, max=1.0, step=0.01, default=0.4, control="Radius1.r"},
		{ label="Width", name="r2", type="float", min=0.0, max=1.0, step=0.01, default=0.1, control="Radius11.r"},
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
	]

func get_includes():
	return [ "sdarc", "rotate" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "sdArc( %s, mod($a1, 360.0)*0.01745329251, mod($a2, 360.0)*0.01745329251, $r1, $r2)" % [ uv ]
