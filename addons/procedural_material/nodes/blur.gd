tool
extends "res://addons/procedural_material/node_base.gd"

var sigma = 1.0
var epsilon = 0.005

func _ready():
	initialize_properties([ $HBoxContainer1/sigma, $HBoxContainer2/epsilon ])

func _get_shader_code(uv):
	var convolution = {
		kernel=[
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0
		],
		epsilon=epsilon
	}
	var sum = 0
	for x in range(-2, 3):
		for y in range(-2, 3):
			var coef = exp(-0.5*(pow((x-2)/sigma, 2.0) + pow((y-2)/sigma, 2.0))) / (2.0*PI*sigma*sigma)
			convolution.kernel[x+2+5*(y+2)] = coef
			sum += coef
	for i in range(25):
		convolution.kernel[i] /= sum
	return get_shader_code_convolution(convolution, uv)
