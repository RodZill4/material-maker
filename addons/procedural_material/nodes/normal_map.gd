tool
extends "res://addons/procedural_material/node_base.gd"

var amount = 0.0

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	set_slot(1, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $amount ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		var epsilon = 0.005
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		var src_code_tl = src.get_shader_code(uv+"+vec2(-%.9f, -%.9f)" % [ epsilon, epsilon ])
		var src_code_l = src.get_shader_code(uv+"+vec2(-%.9f, 0.0)" % [ epsilon, ])
		var src_code_bl = src.get_shader_code(uv+"+vec2(-%.9f, %.9f)" % [ epsilon, epsilon ])
		var src_code_tr = src.get_shader_code(uv+"+vec2(%.9f, -%.9f)" % [ epsilon, epsilon ])
		var src_code_r = src.get_shader_code(uv+"+vec2(%.9f, 0.0)" % [ epsilon ])
		var src_code_br = src.get_shader_code(uv+"+vec2(%.9f, %.9f)" % [ epsilon, epsilon ])
		var src_code_t = src.get_shader_code(uv+"+vec2(0.0, -%.9f)" % [ epsilon ])
		var src_code_b = src.get_shader_code(uv+"+vec2(0.0, %.9f)" % [ epsilon ])
		rv.defs = src_code_tl.defs
		rv.code = src_code_tl.code+src_code_l.code+src_code_bl.code+src_code_tr.code
		rv.code += src_code_r.code+src_code_br.code+src_code_t.code+src_code_b.code
		rv.code += "vec3 %s_%d_rgb = vec3(0.5, 0.5, 0.5) + 0.5*normalize(%.9f*vec3(%s+2.0*%s+%s-%s-2.0*%s-%s, %s+2.0*%s+%s-%s-2.0*%s-%s, 0.0) + vec3(0.0, 0.0, 1.0));\n" % [ name, variant_index, amount, src_code_tr.f, src_code_r.f, src_code_br.f, src_code_tl.f, src_code_l.f, src_code_bl.f, src_code_bl.f, src_code_b.f, src_code_br.f, src_code_tl.f, src_code_t.f, src_code_tr.f ]
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	return rv
