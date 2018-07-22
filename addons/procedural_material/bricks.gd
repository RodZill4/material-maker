tool
extends "res://addons/procedural_material/node_base.gd"

var rows
var columns
var row_offset
var mortar
var bevel

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $GridContainer/rows, $GridContainer/columns, $GridContainer/row_offset, $GridContainer/mortar, $GridContainer/bevel ])

func get_shader_code(uv):
	var rv = { defs="", code="", rgb=null, f=null }
	if !generated:
		rv.defs = "float "+name+"_f(vec2 uv) { return bricks(uv, vec2("+str(rows)+", "+str(columns)+"), "+str(row_offset)+", "+str(mortar)+", "+str(bevel)+"); }\n"
		generated = true
	rv.f = name+"_f("+uv+")"
	return rv

func _get_state_variables():
	return [ "rows", "columns", "row_offset", "mortar", "bevel" ]
