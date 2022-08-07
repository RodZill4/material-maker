extends "res://addons/material_maker/sdf_builder/sdf2d/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ label="Size.x", name="size_x", type="float", min=0.0, max=1.0, step=0.01, default=0.5, control="Rect1.x" },
		{ label="Size.y", name="size_y", type="float", min=0.0, max=1.0, step=0.01, default=0.5, control="Rect1.y" },
		{ label="Steps", name="steps", type="float", min=1.0, max=16.0, step=1.0, default=3 }
	]

func get_includes():
	return [ "rotate", "sdstairs" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "sdStairs(vec2(1.0, -1.0)*%s+vec2($size_x, $size_y), 2.0*vec2($size_x, $size_y)/$steps, $steps)" % [ uv ]
