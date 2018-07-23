tool
extends "res://addons/procedural_material/node_base.gd"

var amount = 0.0

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	set_slot(1, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $amount ])

func get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		var src_code0 = src.get_shader_code(uv+"+vec2(0.01, 0.0)")
		var src_code1 = src.get_shader_code(uv+"+vec2(-0.01, 0.0)")
		var src_code2 = src.get_shader_code(uv+"+vec2(0.0, 0.01)")
		var src_code3 = src.get_shader_code(uv+"+vec2(0.0, -0.01)")
		rv.defs = src_code0.defs
		rv.code = src_code0.code+src_code1.code+src_code2.code+src_code3.code
		rv.code += "vec3 "+name+"_"+str(variant_index)+"_rgb = vec3(0.5, 0.5, 0.5) + 0.5*normalize("+str(amount)+"*vec3("+get_source_f(src_code0)+"-"+get_source_f(src_code1)+", "+get_source_f(src_code2)+"-"+get_source_f(src_code3)+", 0.0) + vec3(0.0, 0.0, 1.0));\n"
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	return rv
