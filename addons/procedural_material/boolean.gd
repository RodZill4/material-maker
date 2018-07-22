tool
extends "res://addons/procedural_material/node_base.gd"

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	set_slot(1, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))

func get_shader_code(uv):
	var rv = { defs="", code="", uv=null, rgb=null, f=null }
	var src0 = get_source(0)
	var src1 = get_source(1)
	if src0 == null || src1 == null:
		return rv
	var src0_code = src0.get_shader_code(uv)
	var src1_code = src1.get_shader_code(uv)
	if !generated:
		rv.defs = src0_code.defs+src1_code.defs
		rv.code  = "float "+name+"_f = "+src0_code.f+"+"+src1_code.f+";\n"
		generated = true
	rv.f = name+"_f"
	return rv
