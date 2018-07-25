tool
extends "res://addons/procedural_material/node_base.gd"

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))
	set_slot(1, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))

func get_shader_code(uv):
	var rv = { defs="", code="", f="0.0" }
	var src = get_source()
	if src != null:
		rv = src.get_shader_code(uv)
		rv.albedo = get_source_rgb(rv)
	src = get_source(1)
	if src != null:
		var src_code = src.get_shader_code(uv)
		rv.defs += src_code.defs
		rv.code += src_code.code
		rv.normal_map = get_source_rgb(src_code)
	return rv

func _get_state_variables():
	return [ ]
