tool
extends "res://addons/material_maker/node_base.gd"

var source = 0

func _ready():
	initialize_properties([ $source ])

func reset():
	generated = false
	generated_variants = [ [], [] ]

func _get_shader_code(uv, index = 0):
	var rv = { defs="", code="" }
	var src = get_source(2*source+index)
	var src_code = { defs="", code="", rgb="0.0" }
	if src != null:
		src_code = src.get_shader_code(uv)
	if generated_variants[index].empty():
		rv.defs = src_code.defs;
	var variant_index = generated_variants[index].find(uv)
	if variant_index == -1:
		variant_index = generated_variants[index].size()
		generated_variants[index].append(uv)
		rv.code = src_code.code
	rv.rgb = src_code.rgb
	return rv
