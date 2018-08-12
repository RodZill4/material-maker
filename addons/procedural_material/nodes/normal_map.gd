tool
extends "res://addons/procedural_material/node_base.gd"

var amount = 0.0

const CONVOLUTION = {
	kernel=[
		0, 0,                  0,                 0,                 0,
		0, Vector3(-1, -1, 0), Vector3(0, -2, 0), Vector3(1, -1, 0), 0,
		0, Vector3(-2, 0, 0),  0,                 Vector3(2, 0, 0),  0,
		0, Vector3(-1, 1, 0),  Vector3(0, 2, 0),  Vector3(1, 1, 0),  0,
		0, 0,                  0,                 0,                 0
	],
	epsilon=0.005,
	normalize=true,
	translate_before_normalize=Vector3(0.0, 0.0, -1.0),
	scale_before_normalize=0.5,
	translate=Vector3(0.5, 0.5, 0.5),
	scale=0.5
}

func _ready():
	initialize_properties([ $amount ])

func _get_shader_code(uv):
	var src = get_source()
	if src == null:
		return { defs="", code="" }
	var convolution = CONVOLUTION
	convolution.scale_before_normalize = amount
	return get_shader_code_convolution(src, convolution, uv)
