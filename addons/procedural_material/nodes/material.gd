tool
extends "res://addons/procedural_material/node_base.gd"

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))

func get_shader_code(uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		rv.code += "void fragment() {\n"
		rv.code += "COLOR = vec4(0.0, 0.0, 0.0, 1.0);"
	else:
		var src_code = src.get_shader_code("UV")
		rv.code += src_code.defs
		rv.code += "void fragment() {\n"
		rv.code += src_code.code
		rv.code += "vec3 "+name+"_rgb = "+get_source_rgb(src_code)+";\n"
		rv.code += "COLOR = vec4("+name+"_rgb, 1.0);\n"
		rv.code += "}\n"
	return rv

func _get_state_variables():
	return [ ]
