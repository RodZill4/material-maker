tool
extends "res://addons/procedural_material/node_base.gd"

var amount = 0.0

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	set_slot(1, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $amount ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src0 = get_source(0)
	var src1 = get_source(1)
	if src0 == null || src1 == null:
		return rv
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		var src1_code0 = src1.get_shader_code(uv+"+vec2(0.01, 0.0)")
		var src1_code1 = src1.get_shader_code(uv+"-vec2(0.01, 0.0)")
		var src1_code2 = src1.get_shader_code(uv+"+vec2(0.0, 0.01)")
		var src1_code3 = src1.get_shader_code(uv+"-vec2(0.0, 0.01)")
		rv.defs = src1_code0.defs
		rv.code = src1_code0.code+src1_code1.code+src1_code2.code+src1_code3.code
		rv.code += "vec2 "+name+"_"+str(variant_index)+"_uv = "+uv+"+"+str(amount)+"*vec2("+get_source_f(src1_code0)+"-"+get_source_f(src1_code1)+", "+get_source_f(src1_code2)+"-"+get_source_f(src1_code3)+");\n"
		var src0_code = src0.get_shader_code(name+"_"+str(variant_index)+"_uv")
		rv.defs += src0_code.defs
		rv.code += src0_code.code
		rv.code += "vec3 "+name+"_"+str(variant_index)+"_rgb = "+get_source_rgb(src0_code)+";\n"
		rv.code += "float "+name+"_"+str(variant_index)+"_f = "+get_source_f(src0_code)+";\n"
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	rv.f = name+"_"+str(variant_index)+"_f"
	return rv
