extends "res://addons/material_maker/sdf_builder/sdf3d/union.gd"

export(int, "Sphere", "Octahedron") var shape

const INCLUDES : Array = [
	[ "rotate" ],
	[ "rotate", "sdf3d_octahedron" ]
]
const FUNCTIONS : Array = [ "length(%s)-$radius", "sdOctahedron(%s, $radius)" ]

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
		{ label="Radius", name="radius", type="float", min=0.0, max=1.0, step=0.01, default=0.5 }
	]

func get_includes():
	return INCLUDES[shape]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return FUNCTIONS[shape] % [ uv ]
