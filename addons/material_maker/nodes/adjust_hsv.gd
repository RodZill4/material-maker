tool
extends "res://addons/material_maker/node_base.gd"

var hue
var saturation
var value

func _ready():
	initialize_properties([ $HBoxContainer1/hue, $HBoxContainer2/saturation, $HBoxContainer3/value ])

func _get_shader_code(uv, output = 0):
	var rv = { defs="", code="" }
	var src = get_source()
	var src_code = { defs="", code="", rgb="vec3(0.0)" }
	if src == null:
		return rv
	src_code = src.get_shader_code(uv)
	if generated_variants.empty():
		rv.defs = src_code.defs;
		rv.defs += "vec3 %s_rgb(vec3 c) { vec3 hsv = rgb2hsv(c); return hsv2rgb(vec3(fract(hsv.x+%.9f), clamp(hsv.y*%.9f, 0.0, 1.0), clamp(hsv.z*%.9f, 0.0, 1.0))); }\n" % [ name, hue, saturation, value ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = src_code.code
		rv.code += "vec3 %s_%d_rgb = %s_rgb(%s);\n" % [ name, variant_index, name, src_code.rgb ]
	rv.rgb = "%s_%d_rgb" % [ name, variant_index ]
	return rv
