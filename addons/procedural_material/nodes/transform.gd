tool
extends "res://addons/procedural_material/node_base.gd"

var rotate = 0.0
var scale = 0.0

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $GridContainer/rotate, $GridContainer/scale ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	rv.uv = name+"_uv("+uv+")"
	var src_code = src.get_shader_code(rv.uv)
	if !generated:
		rv.defs = src_code.defs+"vec2 "+name+"_uv(vec2 uv) { return transform(uv, "+str(3.1415928*rotate/180.0)+", "+str(scale)+"); }\n"
		generated = true
	rv.code = src_code.code;
	if src_code.has("f"):
		rv.f = src_code.f
	if src_code.has("rgb"):
		rv.rgb = src_code.rgb
	return rv
