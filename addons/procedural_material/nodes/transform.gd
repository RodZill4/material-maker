tool
extends "res://addons/procedural_material/node_base.gd"

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
	rv.uv = name+"_uv("+uv+")"
	var src_code = src.get_shader_code(rv.uv)
	if !generated:
		rv.defs = src_code.defs+"vec2 "+name+"_uv(vec2 uv) { return %s(uv, vec2(%.9f, %.9f), %.9f, vec2(%.9f, %.9f)); }\n" % [ "transform_repeat" if repeat else "transform_norepeat", translate_x, translate_y, PI*rotate/180.0, scale_x, scale_y ]
		generated = true
	rv.code = src_code.code;
	if src_code.has("f"):
		rv.f = src_code.f
	if src_code.has("rgb"):
		rv.rgb = src_code.rgb
	return rv

func deserialize(data):
	if data.has("scale"):
		scale_x = data.scale
		scale_y = data.scale
	.deserialize(data)
