extends "res://addons/material_maker/sdf_builder/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ name="ax", type="float", min=-0.5, max=0.5, step=0.01, default=-0.25, control="P11.x" },
		{ name="ay", type="float", min=-0.5, max=0.5, step=0.01, default=-0.25, control="P11.y" },
		{ name="bx", type="float", min=-0.5, max=0.5, step=0.01, default=0.25, control="P12.x" },
		{ name="by", type="float", min=-0.5, max=0.5, step=0.01, default=0.25, control="P12.y" },
		{ name="r", type="float", min=-0.5, max=0.5, step=0.01, default=0.25, control="RadiusP11.r" }
	]

func get_includes():
	return [ "rotate", "sdline" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "float $(name_uv)_n%d = sdLine($(name_uv)_n%d_p, vec2($n%d_ax, $n%d_ay), vec2($n%d_bx, $n%d_by)).x-$n%d_r;\n" % [ scene.index, scene.index, scene.index, scene.index, scene.index, scene.index, scene.index ]
