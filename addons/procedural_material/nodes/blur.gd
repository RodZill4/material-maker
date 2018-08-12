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

func get_gaussian_blur_shader(v):
	var shader_code
	var kernel_size = 10
	var kernel = []
	kernel.resize(2*kernel_size+1)
	shader_code = "shader_type canvas_item;\n"
	shader_code += "uniform sampler2D input_tex;\n"
	shader_code += "void fragment() {\n"
	shader_code += "vec3 color = vec3(0.0);"
	var sum = 0
	for x in range(-kernel_size, kernel_size+1):
		var coef = exp(-0.5*(pow((x)/sigma, 2.0))) / (2.0*PI*sigma*sigma)
		kernel[x+kernel_size] = coef
		sum += coef
	for x in range(-kernel_size, kernel_size+1):
		shader_code += "color += %.9f*textureLod(input_tex, UV+vec2(%.9f, %.9f), %.9f).rgb;\n" % [ kernel[x+kernel_size] / sum, x*v.x, x*v.y, epsilon ]
	shader_code += "COLOR = vec4(color, 1.0);\n"
	shader_code += "}\n"
	return shader_code;

func _rerender():
	get_parent().precalculate_shader(input_shader, get_source().get_textures(), 4096, input_texture, self, "pass_1", [])

func pass_1():
	get_parent().precalculate_shader(get_gaussian_blur_shader(Vector2(epsilon, 0)), { input=input_texture}, 4096, mid_texture, self, "pass_2", [])

func pass_2():
	get_parent().precalculate_shader(get_gaussian_blur_shader(Vector2(0, epsilon)), { input=mid_texture}, 4096, final_texture, self, "rerender_targets", [])

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

func __get_shader_code(uv):
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
