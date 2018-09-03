tool
extends "res://addons/material_maker/node_base.gd"

var scale_x
var scale_y
var intensity

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $HBoxContainer1/scale_x, $HBoxContainer2/scale_y, $HBoxContainer3/intensity ])

func _get_shader_code(uv, slot = 0):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "vec4 %s_xyzw(vec2 uv) { return voronoi(uv, vec2(%f, %f), %.9f, %d); }\n" % [ name, scale_x, scale_y, intensity, get_seed() ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "vec4 %s_%d_xyzw = %s_xyzw(%s);\n" % [ name, variant_index, name, uv ]
	if slot == 0:
		rv.f = "%s_%d_xyzw.z" % [ name, variant_index ]
	elif slot == 1:
		rv.f = "%s_%d_xyzw.w" % [ name, variant_index ]
	else:
		rv.rgb = "rand3(fract(%s_%d_xyzw.xy))" % [ name, variant_index ]
	return rv

func _on_offset_changed():
	update_shaders()
