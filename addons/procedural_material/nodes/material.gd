tool
extends "res://addons/procedural_material/node_base.gd"

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))

func get_shader_code(uv):
	var rv = { defs="", code="", rgb="vec3(0.0, 0.0, 0.0)" }
	var src = get_source()
	if src != null:
		rv = src.get_shader_code(uv)
		if !rv.has("rgb"):
			rv.rgb = get_source_rgb(rv)
	return rv

func _get_state_variables():
	return [ ]
