tool
extends "res://addons/material_maker/node_base.gd"

func _ready():
	initialize_properties([ $color ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	rv.rgb = "vec3(%.9f, %.9f, %.9f)" % [ parameters.color.r, parameters.color.g, parameters.color.b ]
	return rv
