tool
extends "res://addons/procedural_material/node_base.gd"

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))

func get_shader_code(uv):
	var rv = { defs="", code="", rgb=null, f=null }
	var src = get_source()
	if src == null:
		rv.code += "void fragment() {\n"
		rv.code += "COLOR = vec4(0.0, 0.0, 0.0, 1.0);"
	else:
		var src_code = src.get_shader_code("UV")
		rv.code += src_code.defs
		rv.code += "void fragment() {\n"
		rv.code += src_code.code+"\n"
		if src_code.rgb != null:
			rv.code += "vec3 "+name+"_rgb = "+src_code.rgb+"\n"
			rv.code += "COLOR = vec4("+name+"_rgb.r, "+name+"_rgb.g, "+name+"_rgb.b, 1.0);"
		elif src_code.f != null:
			rv.code += "float "+name+"_f = "+src_code.f+";\n"
			rv.code += "COLOR = vec4("+name+"_f, "+name+"_f, "+name+"_f, 1.0);"
			rv.code += "\n}\n"
	return rv