tool
extends "res://addons/procedural_material/node_base.gd"

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
	input_texture = ImageTexture.new()
	final_texture = ImageTexture.new()
	initialize_properties([ $direction ])

func _rerender():
	get_parent().precalculate_shader(input_shader, get_source().get_textures(), 1024, input_texture, self, "pass_1", [])

func pass_1():
	var convolution = CONVOLUTION
	for i in range(8):
		convolution.kernel[INDICES[i]] = COEFS[(i+8-int(direction))%8]
	get_parent().precalculate_shader(get_convolution_shader(convolution), {input=input_texture}, 1024, final_texture, self, "rerender_targets", [])

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
