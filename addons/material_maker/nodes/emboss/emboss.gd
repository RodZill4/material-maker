tool
extends "res://addons/material_maker/node_base.gd"

var size = 5
var direction = 0

var input_shader = ""
var input_texture
var final_texture

const CONVOLUTION = {
	x=1,
	y=1,
	kernel=[
		1, 2, 1,
		0, 0, 0,
		-1, -2, -1
	],
	epsilon=1.0/1024,
	scale=0.5,
	translate=Vector3(0.5, 0.5, 0.5)
}

const INDICES = [ 0, 1, 2, 5, 8, 7, 6, 3 ]
const COEFS = [ 1, 2, 1, 0, -1, -2, -1, 0 ]

func _ready():
	$HBoxContainer1/size.clear()
	for i in range(7):
		$HBoxContainer1/size.add_item(str(int(pow(2, 5+i))), i)
	$HBoxContainer1/size.selected = size
	input_texture = ImageTexture.new()
	final_texture = ImageTexture.new()
	initialize_properties([ $HBoxContainer1/size, $HBoxContainer2/direction ])

func _rerender():
	get_parent().renderer.precalculate_shader(input_shader, get_source().get_textures(), int(pow(2, 5+size)), input_texture, self, "pass_1", [])

func pass_1():
	var convolution = CONVOLUTION
	convolution.epsilon=1.0/pow(2, 5+size)
	for i in range(8):
		convolution.kernel[INDICES[i]] = COEFS[(i+8-int(direction))%8]
	get_parent().renderer.precalculate_shader(get_convolution_shader(convolution), {input=input_texture}, int(pow(2, 5+size)), final_texture, self, "rerender_targets", [])

func get_textures():
	var list = {}
	list[name] = final_texture
	return list

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	input_shader = get_parent().generate_shader(src.get_shader_code("UV"))
	_rerender()
	if generated_variants.empty():
		rv.defs = "uniform sampler2D %s_tex;\n" % [ name ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "vec3 %s_%d_rgb = texture(%s_tex, %s).rgb;\n" % [ name, variant_index, name, uv ]
	rv.rgb = "%s_%d_rgb" % [ name, variant_index ]
	return rv
