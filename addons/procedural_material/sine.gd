tool
extends "res://addons/procedural_material/node_base.gd"

var waves = 1.0
var sharpness = 1.0

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))
	initialize_properties([ $waves, $sharpness ])

func get_shader_code(uv):
	var rv = { defs="", code="", rgb=null, f=null }
	if !generated:
		rv.defs = "float "+name+"_f(vec2 uv) { return sine(uv, "+str(waves)+", "+str(sharpness)+"); }\n"
		generated = true
	rv.f = name+"_f("+uv+")"
	return rv

func _on_Count_text_changed(new_text):
	waves = float(new_text)
	get_parent().get_parent().generate_shader()

func _on_Sharpness_text_changed(new_text):
	sharpness = float(new_text)
	get_parent().get_parent().generate_shader()

func _get_state_variables():
	return [ "waves", "sharpness" ]
