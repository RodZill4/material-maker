tool
extends "res://addons/procedural_material/node_base.gd"

var scale_x
var scale_y
var iterations
var persistance

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $GridContainer/scale_x, $GridContainer/scale_y, $GridContainer/iterations, $GridContainer/persistance ])

func get_shader_code(uv):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "float "+name+"_f(vec2 uv) { return perlin(uv, vec2("+str(scale_x)+", "+str(scale_y)+"), "+str(iterations)+", "+str(persistance)+"); }\n"
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "float "+name+"_"+str(variant_index)+"_f = "+name+"_f("+uv+");\n"
	rv.f = name+"_"+str(variant_index)+"_f"
	return rv
