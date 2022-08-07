extends "res://addons/material_maker/sdf_builder/sdf3d/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.z", name="position_z", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Rotation.x", name="angle_x", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.y", name="angle_y", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.z", name="angle_z", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0 },
		{ label="Size.x", name="size_x", type="float", min=0.0, max=0.5, step=0.01, default=0.1 },
		{ label="Size.y", name="size_y", type="float", min=0.0, max=0.5, step=0.01, default=0.1 },
		{ label="Size.z", name="size_z", type="float", min=0.0, max=0.5, step=0.01, default=0.1 }
	]

func get_includes():
	return [ "rotate" ]

func mod_uv_code(_scene : Dictionary, output_name : String) -> String:
	return "vec3 %s_s = vec3($size_x, $size_y, $size_z);\n%s_p = %s_p - clamp(%s_p, -%s_s, %s_s);\n" % [ output_name, output_name, output_name, output_name, output_name, output_name ]
