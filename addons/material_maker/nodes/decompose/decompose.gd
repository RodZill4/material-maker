tool
extends "res://addons/material_maker/node_base.gd"

const OUTPUTS = [ "r", "g", "b" ]

func _get_shader_code(uv, output = 0):
	var rv = { defs="", code="" }
	var src = get_source()
	var src_code = { defs="", code="", rgb="vec3(0.0)" }
	if src != null:
		src_code = src.get_shader_code(uv)
	if generated_variants.empty():
		rv.defs = src_code.defs;
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = src_code.code
		rv.code += "vec3 %s_%d_rgb = %s;\n" % [ name, variant_index, src_code.rgb ]
	rv.f = "%s_%d_rgb.%s" % [ name, variant_index, OUTPUTS[output] ]
	return rv
