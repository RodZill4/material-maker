extends "res://addons/material_maker/sdf_builder/union.gd"

export(int, "Box", "Rhombus", "IsocelesTriangle", "Tunnel") var shape

const INCLUDES : Array = [
	[ "rotate", "sdbox" ],
	[ "rotate", "sdrhombus" ],
	[ "rotate", "sdisoscelestriangle" ],
	[ "rotate", "sdtunnel" ]
]
const FUNCTIONS : Array = [ "sd_box", "sdRhombus", "sd_isosceles_triangle", "sdTunnel" ]

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
	return "float $(name_uv)_n%d = %s($(name_uv)_n%d_p, vec2($n%d_size_x, $n%d_size_y));\n" % [ scene.index, FUNCTIONS[shape], scene.index, scene.index, scene.index ]
