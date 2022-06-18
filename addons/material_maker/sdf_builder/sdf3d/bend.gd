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
		{ label="Amount", name="amount", type="float", min=-1.0, max=1.0, step=0.01, default=0.5 }
	]

func get_includes():
	return [ "rotate", "sdf3d_bend" ]

func mod_uv_code(_scene : Dictionary, output_name : String) -> String:
	return "%s_p = Bend3d(%s_p, $amount);\n" % [ output_name, output_name ]
