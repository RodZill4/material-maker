tool
extends "res://addons/material_maker/node_base.gd"

var translate_x = 0.0
var translate_y = 0.0
var rotate = 0.0
var scale_x = 1.0
var scale_y = 1.0
var repeat = true

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $HBoxContainer1/translate_x, $HBoxContainer2/translate_y, $HBoxContainer3/rotate, $HBoxContainer4/scale_x, $HBoxContainer5/scale_y, $repeat ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		var inputs = [ "", "", "", "", "" ]
		for i in range(5):
			var tsrc = get_source(i+1)
			if tsrc != null:
				var tsrc_code = tsrc.get_shader_code(uv)
				if generated_variants.size() == 1:
					rv.defs += tsrc_code.defs
				rv.code += tsrc_code.code
				inputs[i] = "*(2.0*(%s)-1.0)" % tsrc_code.f
		rv.code += "vec2 %s_%d_uv = %s(%s, vec2(%.9f%s, %.9f%s), %.9f%s, vec2(%.9f%s, %.9f%s));\n" % [ name, variant_index, "transform_repeat" if repeat else "transform_norepeat", uv, translate_x, inputs[0], translate_y, inputs[1], PI*rotate/180.0, inputs[2], scale_x, inputs[3], scale_y, inputs[4] ]
	var src_code = src.get_shader_code("%s_%d_uv" % [ name, variant_index ])
	if rv.code != "":
		if generated_variants.size() == 1:
			rv.defs += src_code.defs
		rv.code += src_code.code
	rv.rgb = src_code.rgb
	return rv

func deserialize(data):
	if data.has("scale"):
		scale_x = data.scale
		scale_y = data.scale
	.deserialize(data)
