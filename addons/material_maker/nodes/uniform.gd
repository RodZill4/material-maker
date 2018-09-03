tool
extends "res://addons/material_maker/node_base.gd"

var color = Color(0.0, 0.0, 0.0)

func _ready():
	initialize_properties([ $color ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	rv.rgb = "vec3(%.9f, %.9f, %.9f)" % [ color.r, color.g, color.b ]
	return rv
