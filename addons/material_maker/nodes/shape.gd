tool
extends "res://addons/material_maker/node_base.gd"

var shape
var sides
var radius
var edge

const SHAPES = [ "circle", "polygon", "star", "curved_star" ]

func _ready():
	initialize_properties([ $shape, $sides, $radius, $edge ])

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	rv.f = "%s(%s, %d, %f, %f)" % [ SHAPES[shape], uv, sides, radius, edge ]
	return rv
