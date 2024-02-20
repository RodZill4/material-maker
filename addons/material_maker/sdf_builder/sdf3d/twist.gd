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
		{ label="Axis", name="axis", type="enum", values=[{ name="X", value="yz" }, { name="Y", value="zx" }, { name="Z", value="xy" }], default=0 },
		{ label="Angle", name="angle", type="float", min=-180.0, max=180.0, step=0.1, default=0.0 }
	]

func get_includes():
	return [ "rotate" ]

func mod_uv_code(scene : Dictionary, output_name : String) -> String:
	var axis : int = 0
	if scene.has("parameters") and scene.parameters.has("axis"):
		axis = scene.parameters.axis
	match axis:
		1:
			return "%s_p.zx=rotate(%s_p.zx, %s_p.y*$angle*0.01745329251);\n" % [ output_name, output_name, output_name ]
		2:
			return "%s_p.xy=rotate(%s_p.xy, %s_p.z*$angle*0.01745329251);\n" % [ output_name, output_name, output_name ]
		_:
			return "%s_p.yz=rotate(%s_p.yz, %s_p.x*$angle*0.01745329251);\n" % [ output_name, output_name, output_name ]
