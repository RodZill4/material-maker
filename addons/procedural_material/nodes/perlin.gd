tool
extends "res://addons/procedural_material/node_base.gd"

var scale_x
var scale_y
var iterations
var persistence

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $GridContainer/scale_x, $GridContainer/scale_y, $GridContainer/iterations, $GridContainer/persistence ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "float "+name+"_f(vec2 uv) { return perlin(uv, vec2(%f, %f), %d, %.9f, %d); }\n" % [ scale_x, scale_y, iterations, persistence, get_seed() ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "float "+name+"_"+str(variant_index)+"_f = "+name+"_f("+uv+");\n"
	rv.f = name+"_"+str(variant_index)+"_f"
	return rv

func _on_offset_changed():
	update_shaders()
