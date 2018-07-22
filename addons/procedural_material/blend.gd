tool
extends "res://addons/procedural_material/node_base.gd"

var amount = 0.0

func _ready():
	set_slot(0, true, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	set_slot(1, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))
	set_slot(2, true, 0, Color(0.5, 0.5, 1), false, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $amount ])

func color_to_string(c):
	return "vec3("+str(c.r)+","+str(c.g)+","+str(c.b)+")"

func get_shader_code(uv):
	var rv = { defs="", code="", uv=null, rgb=null, f=null }
	var src0 = get_source(0)
	var src1 = get_source(1)
	var src2 = get_source(2)
	if src0 == null or src1 == null:
		return rv
	var src0_code = src0.get_shader_code(uv)
	var src1_code = src1.get_shader_code(uv)
	var src2_code = { defs="", code="" }
	var amount_str = str(amount)
	if src2 != null:
		src2_code = src2.get_shader_code(uv)
		amount_str = str(src2_code.f)
	if !generated:
		rv.defs = src0_code.defs+src1_code.defs+src2_code.defs
		rv.code = src0_code.code+src1_code.code+src2_code.code
		rv.code += "vec3 "+name+"_rgb = mix("+get_source_rgb(src0_code)+", "+get_source_rgb(src1_code)+", "+amount_str+");\n"
		generated = true
	rv.rgb = name+"_rgb"
	return rv

func _get_state_variables():
	return [ "amount" ]
