tool
extends "res://addons/procedural_material/node_base.gd"

var sigma = 1.0
var epsilon = 0.005

var input_shader = ""
var input_texture
var mid_texture
var final_texture

func _ready():
	input_texture = ImageTexture.new()
	mid_texture = ImageTexture.new()
	final_texture = ImageTexture.new()
	initialize_properties([ $HBoxContainer1/epsilon, $HBoxContainer2/sigma ])

func get_gaussian_blur_shader(horizontal):
	var convolution = { x=0, y=0, kernel=[], epsilon=epsilon }
	var kernel_size = 10
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
	get_parent().precalculate_shader(input_shader, get_source().get_textures(), 4096, input_texture, self, "pass_1", [])

func pass_1():
	get_parent().precalculate_shader(get_gaussian_blur_shader(true), { input=input_texture}, 4096, mid_texture, self, "pass_2", [])

func pass_2():
	get_parent().precalculate_shader(get_gaussian_blur_shader(false), { input=mid_texture}, 4096, final_texture, self, "rerender_targets", [])

func get_textures():
	var list = {}
	list[name] = final_texture
	return list

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	input_shader = do_generate_shader(src.get_shader_code("UV"))
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
