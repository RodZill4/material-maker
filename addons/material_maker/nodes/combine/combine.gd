tool
extends "res://addons/material_maker/node_base.gd"

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src0 = get_source(0)
	var src1 = get_source(1)
	var src2 = get_source(2)
	var src0_code = { defs="", code="", f="0.0" }
	var src1_code = { defs="", code="", f="0.0" }
	var src2_code = { defs="", code="", f="0.0" }
	if src0 != null:
		src0_code = src0.get_shader_code(uv)
	if src1 != null:
		src1_code = src1.get_shader_code(uv)
	if src2 != null:
		src2_code = src2.get_shader_code(uv)
	if generated_variants.empty():
		rv.defs = src0_code.defs;
		rv.defs += src1_code.defs;
		rv.defs += src2_code.defs;
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = src0_code.code
		rv.code += src1_code.code
		rv.code += src2_code.code
		rv.code += "vec3 %s_%d_rgb = vec3(%s, %s, %s);\n" % [ name, variant_index, src0_code.f, src1_code.f, src2_code.f ]
	rv.rgb = "%s_%d_rgb" % [ name, variant_index ]
	return rv
