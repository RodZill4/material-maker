tool
extends "res://addons/material_maker/node_base.gd"

var size = 4
var density = 0.5

func _ready():
	$HBoxContainer1/size.clear()
	for i in range(7):
		$HBoxContainer1/size.add_item(str(int(pow(2, 5+i))), i)
	$HBoxContainer1/size.selected = size
	initialize_properties([ $HBoxContainer1/size, $HBoxContainer2/density ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "float %s_f(vec2 uv) { return dots(uv, %.9f, %.9f, %d); }\n" % [ name, 1.0/pow(2.0, 5.0+size), density, get_seed() ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "float %s_%d_f = %s_f(%s);\n" % [ name, variant_index, name, uv ]
	rv.f = "%s_%d_f" % [ name, variant_index ]
	return rv

func _on_offset_changed():
	update_shaders()
