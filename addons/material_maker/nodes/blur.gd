tool
extends "res://addons/material_maker/node_base.gd"

var size = 5
var direction = 0
var sigma = 1.0

var input_shader = ""
var saved_texture

const DIRECTION_H = 1
const DIRECTION_V = 2
const DIRECTIONS = [
	{ name="Both", mask=DIRECTION_H|DIRECTION_V },
	{ name="X", mask=DIRECTION_H },
	{ name="Y", mask=DIRECTION_V }
]

func _ready():
	# init size widget
	$HBoxContainer1/size.clear()
	for i in range(7):
		$HBoxContainer1/size.add_item(str(int(pow(2, 5+i))), i)
	$HBoxContainer1/size.selected = size
	# init direction widget
	$HBoxContainer2/direction.clear()
	for d in DIRECTIONS:
		$HBoxContainer2/direction.add_item(d.name)
	$HBoxContainer2/direction.selected = direction
	initialize_properties([ $HBoxContainer1/size, $HBoxContainer2/direction, $HBoxContainer3/sigma ])
	saved_texture = ImageTexture.new()

func get_gaussian_blur_shader(horizontal):
	var convolution = { x=0, y=0, kernel=[], epsilon=1.0/pow(2, 5+size) }
	var kernel_size = 50
	if horizontal:
		convolution.x = kernel_size
	else:
		convolution.y = kernel_size
	convolution.kernel.resize(2*kernel_size+1)
	var sum = 0
	for x in range(-kernel_size, kernel_size+1):
		var coef = exp(-0.5*(pow((x)/sigma, 2.0))) / (2.0*PI*sigma*sigma)
		convolution.kernel[x+kernel_size] = coef
		sum += coef
	for x in range(-kernel_size, kernel_size+1):
		convolution.kernel[x+kernel_size] /= sum
	return get_convolution_shader(convolution)

func _rerender():
	if DIRECTIONS[direction].mask & DIRECTION_H != 0:
		get_parent().renderer.precalculate_shader(input_shader, get_source().get_textures(), int(pow(2, 5+size)), saved_texture, self, "pass_1", [])
	else:
		get_parent().renderer.precalculate_shader(input_shader, get_source().get_textures(), int(pow(2, 5+size)), saved_texture, self, "pass_2", [])

func pass_1():
	if DIRECTIONS[direction].mask & DIRECTION_V != 0:
		get_parent().renderer.precalculate_shader(get_gaussian_blur_shader(true), { input=saved_texture }, int(pow(2, 5+size)), saved_texture, self, "pass_2", [])
	else:
		get_parent().renderer.precalculate_shader(get_gaussian_blur_shader(true), { input=saved_texture }, int(pow(2, 5+size)), saved_texture, self, "rerender_targets", [])
	

func pass_2():
	get_parent().renderer.precalculate_shader(get_gaussian_blur_shader(false), { input=saved_texture }, int(pow(2, 5+size)), saved_texture, self, "rerender_targets", [])

func get_textures():
	var list = {}
	list[name] = saved_texture
	return list

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	input_shader = get_parent().renderer.generate_shader(src.get_shader_code("UV"))
	_rerender()
	if generated_variants.empty():
		rv.defs = "uniform sampler2D "+name+"_tex;\n"
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "vec3 "+name+"_"+str(variant_index)+"_rgb = texture("+name+"_tex, "+uv+").rgb;\n"
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	return rv
