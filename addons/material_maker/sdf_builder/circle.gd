extends "res://addons/material_maker/sdf_builder/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ name="radius", type="float", min=0.0, max=1.0, step=0.01, default=0.5}
	]

func get_includes():
	return [ "rotate" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "float $(name_uv)_n%d = length($(name_uv)_n%d_p)-$n%d_radius;\n" % [ scene.index, scene.index, scene.index ]
