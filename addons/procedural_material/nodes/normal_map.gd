tool
extends "res://addons/procedural_material/node_base.gd"

var amount = 0.0

var input_shader = ""
var input_texture
var final_texture

const CONVOLUTION = {
	x=1,
	y=1,
	kernel=[
		Vector3(-1, -1, 0), Vector3(0, -2, 0), Vector3(1, -1, 0),
		Vector3(-2, 0, 0),  0,                 Vector3(2, 0, 0),
		Vector3(-1, 1, 0),  Vector3(0, 2, 0),  Vector3(1, 1, 0),
	],
	epsilon=1.0/1024,
	normalize=true,
	translate_before_normalize=Vector3(0.0, 0.0, -1.0),
	scale_before_normalize=0.5,
	translate=Vector3(0.5, 0.5, 0.5),
	scale=0.5
}

func _ready():
	input_texture = ImageTexture.new()
	final_texture = ImageTexture.new()
	initialize_properties([ $amount ])

func _rerender():
	get_parent().precalculate_shader(input_shader, get_source().get_textures(), 1024, input_texture, self, "pass_1", [])

func pass_1():
	var convolution = CONVOLUTION
	convolution.scale_before_normalize = 8.0*amount
	get_parent().precalculate_shader(get_convolution_shader(convolution), { input=input_texture}, 1024, final_texture, self, "rerender_targets", [])

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
		rv.defs = "uniform sampler2D %s_tex;\n" % [ name ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "vec3 %s_%d_rgb = texture(%s_tex, %s).rgb;\n" % [ name, variant_index, name, uv ]
	rv.rgb = "%s_%d_rgb" % [ name, variant_index ]
	return rv
