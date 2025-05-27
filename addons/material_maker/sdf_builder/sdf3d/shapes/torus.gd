extends "res://addons/material_maker/sdf_builder/sdf3d/boolean/union.gd"

@export_enum ("Cylinder", "Capsule", "Pyramid", "Cone") var shape : int

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
		{ label="Axis", name="axis", type="enum", values=[{ name="X", value="zxy" }, { name="Y", value="xyz" }, { name="Z", value="yzx" }], default=0 },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0 },
		{ label="Radius1", name="R", type="float", min=0.0, max=1.0, step=0.01, default=0.5 },
		{ label="Radius2", name="r", type="float", min=0.0, max=1.0, step=0.01, default=0.1 }
	]

func get_includes():
	return [ "rotate", "sdf3d_torus" ]

func shape_code(_scene : Dictionary, uv : String = "$uv") -> String:
	return "sdTorus(%s.$axis, vec2($R, $r))" % [ uv ]
