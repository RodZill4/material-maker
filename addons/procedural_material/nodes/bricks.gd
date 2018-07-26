tool
extends "res://addons/procedural_material/node_base.gd"

var rows
var columns
var row_offset
var mortar
var bevel

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $GridContainer/rows, $GridContainer/columns, $GridContainer/row_offset, $GridContainer/mortar, $GridContainer/bevel ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "float "+name+"_f(vec2 uv) { return bricks(uv, vec2("+str(columns)+", "+str(rows)+"), "+str(row_offset)+", "+str(mortar)+", "+str(max(0.001, bevel))+"); }\n"
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "float "+name+"_"+str(variant_index)+"_f = "+name+"_f("+uv+");\n"
	rv.f = name+"_"+str(variant_index)+"_f"
	return rv
