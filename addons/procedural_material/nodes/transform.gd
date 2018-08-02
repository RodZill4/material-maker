tool
extends "res://addons/procedural_material/node_base.gd"

var translate_x = 0.0
var translate_y = 0.0
var rotate = 0.0
var scale = 0.0

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $GridContainer/translate_x, $GridContainer/translate_y, $GridContainer/rotate, $GridContainer/scale ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	rv.uv = name+"_uv("+uv+")"
	var src_code = src.get_shader_code(rv.uv)
	if !generated:
		rv.defs = src_code.defs+"vec2 "+name+"_uv(vec2 uv) { return transform(uv, vec2(%.9f, %.9f), %.9f, %.9f); }\n" % [ translate_x, translate_y, 3.1415928*rotate/180.0, scale ]
		generated = true
	rv.code = src_code.code;
	if src_code.has("f"):
		rv.f = src_code.f
	if src_code.has("rgb"):
		rv.rgb = src_code.rgb
	return rv
