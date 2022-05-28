extends "res://addons/material_maker/sdf_builder/sdf2d/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ label="A.x", name="ax", type="float", min=-0.5, max=0.5, step=0.01, default=-0.25, control="P11.x" },
		{ label="A.y", name="ay", type="float", min=-0.5, max=0.5, step=0.01, default=-0.25, control="P11.y" },
		{ label="B.x", name="bx", type="float", min=-0.5, max=0.5, step=0.01, default=0.25, control="P12.x" },
		{ label="B.y", name="by", type="float", min=-0.5, max=0.5, step=0.01, default=0.25, control="P12.y" },
		{ label="Radius", name="r", type="float", min=-0.5, max=0.5, step=0.01, default=0.25, control="RadiusP11.r" }
	]

func get_includes():
	return [ "rotate", "sdline" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "float $(name_uv)_n%d = sdLine(%s, vec2($ax, $ay), vec2($bx, $by)).x-$r;\n" % [ scene.index, uv ]
