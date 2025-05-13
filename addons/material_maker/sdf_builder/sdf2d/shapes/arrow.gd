extends "res://addons/material_maker/sdf_builder/sdf2d/boolean/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="A X", name="ax", type="float", min=-1.0, max=1.0, step=0.01, default=-0.3, control="P11.x"},
		{ label="A Y", name="ay", type="float", min=-1.0, max=1.0, step=0.01, default=-0.3, control="P11.y"},
		{ label="B X", name="bx", type="float", min=-1.0, max=1.0, step=0.01, default=0.3, control="P12.x"},
		{ label="B Y", name="by", type="float", min=-1.0, max=1.0, step=0.01, default=0.3, control="P12.y"},
		{ label="Ratio", name="k", type="float", min=0.0, max=1.0, step=0.01, default=0.55, control="None"},
		{ label="Head", name="wh", type="float", min=0.0, max=1.0, step=0.01, default=0.25, control="None"},
		{ label="Tail", name="wt", type="float", min=0.0, max=1.0, step=0.01, default=0.1, control="None"},
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
	]

func get_includes():
	return [ "sdarrow", "rotate" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "sdArrow(%s,vec2($ax,$ay),vec2($bx,$by),$wt,$wh,$k/$wh*distance(vec2($ax,$ay),vec2($bx,$by)))" % [ uv ]
