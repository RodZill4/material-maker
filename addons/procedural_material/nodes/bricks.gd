tool
extends "res://addons/procedural_material/node_base.gd"

var rows
var columns
var row_offset
var mortar
var bevel

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $HBoxContainer1/rows, $HBoxContainer2/columns, $HBoxContainer3/row_offset, $HBoxContainer4/mortar, $HBoxContainer5/bevel ])

func _get_shader_code(uv, slot = 0):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "vec3 "+name+"_xyz(vec2 uv) { return bricks(uv, vec2("+str(columns)+", "+str(rows)+"), "+str(row_offset)+", "+str(mortar)+", "+str(max(0.001, bevel))+"); }\n"
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "vec3 "+name+"_"+str(variant_index)+"_xyz = "+name+"_xyz("+uv+");\n"
	if slot == 0:
		rv.f = name+"_"+str(variant_index)+"_xyz.x"
	else:
		rv.rgb = "rand3("+name+"_"+str(variant_index)+"_xyz.yz)"
	return rv
