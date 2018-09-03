tool
extends "res://addons/material_maker/node_base.gd"

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	var src_code = src.get_shader_code(uv)
	if generated_variants.empty():
		rv.defs = src_code.defs+$Control.get_shader("%s_gradient" % name);
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = src_code.code+"vec3 %s_%d_rgb = %s_gradient(%s);\n" % [ name, variant_index, name, src_code.f ]
	rv.rgb = "%s_%d_rgb" % [ name, variant_index ]
	return rv

func serialize():
	var data = .serialize()
	data.gradient = $Control.serialize()
	return data

func deserialize(data):
	if data.has("gradient"):
		$Control.deserialize(data.gradient)
	.deserialize(data)
