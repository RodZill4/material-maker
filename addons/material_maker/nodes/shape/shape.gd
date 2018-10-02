tool
extends "res://addons/material_maker/node_base.gd"

const SHAPES = [ "circle", "polygon", "star", "curved_star", "rays" ]

func _ready():
	initialize_properties([ $shape, $sides, $radius, $edge ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	rv.f = "%s(%s, %d, %f, %f)" % [ SHAPES[parameters.shape], uv, parameters.sides, parameters.radius, parameters.edge ]
	return rv
