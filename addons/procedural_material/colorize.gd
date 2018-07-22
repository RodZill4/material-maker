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
	var rv = { defs="", code="", uv=null, rgb=null, f=null }
	var src = get_source()
	if src == null:
		return rv
	var src_code = src.get_shader_code(uv)
	if !generated:
		rv.defs = src_code.defs;
		rv.code = src_code.code+"vec3 "+name+"_rgb = mix("+color_to_string(color0)+", "+color_to_string(color1)+", "+src_code.f+");\n"
		generated = true
	rv.f = src_code.f
	rv.rgb = name+"_rgb"
	return rv

func _get_state_variables():
	return [ "color0", "color1" ]
