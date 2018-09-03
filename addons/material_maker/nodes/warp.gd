tool
extends "res://addons/material_maker/node_base.gd"

var amount = 0.0

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	set_slot(1, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $amount ])

func _get_shader_code(uv):
	var epsilon = 0.01
	var rv = { defs="", code="" }
	var src0 = get_source(0)
	var src1 = get_source(1)
	if src0 == null || src1 == null:
		return rv
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		var src1_code0 = src1.get_shader_code("fract(%s+vec2(%.9f, 0.0))" % [ uv, epsilon ])
		var src1_code1 = src1.get_shader_code("fract(%s-vec2(%.9f, 0.0))" % [ uv, epsilon ])
		var src1_code2 = src1.get_shader_code("fract(%s+vec2(0.0, %.9f))" % [ uv, epsilon ])
		var src1_code3 = src1.get_shader_code("fract(%s-vec2(0.0, %.9f))" % [ uv, epsilon ])
		rv.defs = src1_code0.defs
		rv.code = src1_code0.code+src1_code1.code+src1_code2.code+src1_code3.code
		rv.code += "vec2 %s_%d_uv = %s+%.9f*vec2((%s)-(%s), (%s)-(%s));\n" % [ name, variant_index, uv, amount, src1_code0.f, src1_code1.f, src1_code2.f, src1_code3.f ]
		var src0_code = src0.get_shader_code("%s_%d_uv" % [ name, variant_index ])
		rv.defs += src0_code.defs
		rv.code += src0_code.code
		rv.code += "vec3 %s_%d_rgb = %s;\n" % [ name, variant_index, src0_code.rgb ]
		rv.code += "float %s_%d_f = %s;\n" % [ name, variant_index, src0_code.f ]
	rv.rgb = "%s_%d_rgb" % [ name, variant_index ]
	rv.f = "%s_%d_f" % [ name, variant_index ]
	return rv
