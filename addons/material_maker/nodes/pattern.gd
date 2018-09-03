tool
extends "res://addons/material_maker/node_base.gd"

var mix = 0;
var x_wave = 0
var x_scale = 4.0
var y_wave = 0
var y_scale = 4.0

const WAVE_FCT = [ "wave_sin", "wave_triangle", "wave_square", "fract", "wave_constant" ]
const MIX_FCT = [ "mix_multiply", "mix_add", "mix_max", "mix_min", "mix_xor", "mix_pow" ]

func _ready():
	initialize_properties([ $HBoxContainer0/mix, $HBoxContainer1/x_wave, $HBoxContainer1/x_scale, $HBoxContainer2/y_wave, $HBoxContainer2/y_scale ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "float %s_f(vec2 uv) { uv *= vec2(%.9f, %.9f); return %s(%s(uv.x), %s(uv.y)); }\n" % [ name, x_scale, y_scale, MIX_FCT[mix], WAVE_FCT[x_wave], WAVE_FCT[y_wave] ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "float %s_%d_f = %s_f(%s);\n" % [ name, variant_index, name, uv ]
	rv.f = name+"_"+str(variant_index)+"_f"
	return rv
