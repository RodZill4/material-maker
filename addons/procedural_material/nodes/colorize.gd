tool
extends "res://addons/procedural_material/node_base.gd"

var color0
var color1

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	var src_code = src.get_shader_code(uv)
	if generated_variants.empty():
		rv.defs = src_code.defs+$Control.get_shader(name+"_gradient");
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = src_code.code+"vec3 "+name+"_"+str(variant_index)+"_rgb = "+name+"_gradient("+src_code.f+");\n"
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	return rv

func serialize():
	var data = .serialize()
	data.gradient = $Control.serialize()
	return data

func deserialize(data):
	$Control.deserialize(data.gradient)
	.deserialize(data)
