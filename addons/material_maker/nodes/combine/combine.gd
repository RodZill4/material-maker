tool
extends "res://addons/material_maker/node_base.gd"

func _get_shader_code(uv, slot = 0):
	var rv = { defs="", code="" }
	var src0 = get_source(0)
	var src1 = get_source(1)
	var src2 = get_source(2)
	var src3 = get_source(3)
	var src0_code = { defs="", code="", f="0.0" }
	var src1_code = { defs="", code="", f="0.0" }
	var src2_code = { defs="", code="", f="0.0" }
	var src3_code = { defs="", code="", f="1.0" }
	if src0 != null:
		src0_code = src0.get_shader_code(uv)
	if src1 != null:
		src1_code = src1.get_shader_code(uv)
	if src2 != null:
		src2_code = src2.get_shader_code(uv)
	if src3 != null:
		src3_code = src3.get_shader_code(uv)
	if generated_variants.empty():
		rv.defs = src0_code.defs;
		rv.defs += src1_code.defs;
		rv.defs += src2_code.defs;
		rv.defs += src3_code.defs;
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = src0_code.code
		rv.code += src1_code.code
		rv.code += src2_code.code
		rv.code += src3_code.code
		rv.code += "vec4 %s_%d_rgba = vec4(%s, %s, %s, %s);\n" % [ name, variant_index, src0_code.f, src1_code.f, src2_code.f, src3_code.f ]
	rv.rgba = "%s_%d_rgba" % [ name, variant_index ]
	return rv
