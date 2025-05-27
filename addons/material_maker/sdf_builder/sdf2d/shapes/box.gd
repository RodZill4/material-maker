extends "res://addons/material_maker/sdf_builder/sdf2d/boolean/union.gd"


@export_enum("Box", "Rhombus", "IsocelesTriangle", "Tunnel", "Ellipse") var shape : int


const INCLUDES : Array = [
	[ "rotate", "sdbox" ],
	[ "rotate", "sdrhombus" ],
	[ "rotate", "sdisoscelestriangle" ],
	[ "rotate", "sdtunnel" ],
	[ "rotate", "sdellipse" ],
	[ "rotate", "sdstairs" ]
]
const FUNCTIONS : Array = [ "sd_box", "sdRhombus", "sd_isosceles_triangle", "sdTunnel", "sd_ellipse", "sdStairs" ]

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ label="Size.x", name="size_x", type="float", min=0.0, max=1.0, step=0.01, default=0.5, control="Rect1.x" },
		{ label="Size.y", name="size_y", type="float", min=0.0, max=1.0, step=0.01, default=0.5, control="Rect1.y" }
	]

func get_includes():
	return INCLUDES[shape]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "%s(%s, vec2($size_x, $size_y))" % [ FUNCTIONS[shape], uv ]
