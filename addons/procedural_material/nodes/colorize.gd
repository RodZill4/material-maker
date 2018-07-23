tool
extends "res://addons/procedural_material/node_base.gd"

var color0
var color1

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $color0, $color1 ])
	
func color_to_string(c):
	return "vec3("+str(c.r)+","+str(c.g)+","+str(c.b)+")"

func get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	var src_code = src.get_shader_code(uv)
	if generated_variants.empty():
		rv.defs = src_code.defs;
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = src_code.code+"vec3 "+name+"_"+str(variant_index)+"_rgb = mix("+color_to_string(color0)+", "+color_to_string(color1)+", "+src_code.f+");\n"
	rv.f = src_code.f
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	return rv

func _get_state_variables():
	return [ "color0", "color1" ]
