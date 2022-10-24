extends "res://addons/material_maker/sdf_builder/base.gd"


func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ default=0.5, label="Value", max=1, min=0, name="value", step=0.01, type="float" },
		{ default=0.1, label="Width", max=0.5, min=0, name="width", step=0.01, type="float" },
		{ label="Invert", name="invert", type="boolean", default=false }
	]

func get_includes():
	return [ ]

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var data : Dictionary = { parameters=[] }
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, uv, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
	return data

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false):
	var child : String
	if scene.children.empty():
		child = "0.0"
	else:
		var ctxt2 : Dictionary = ctxt.duplicate()
		ctxt2.type = "float"
		child = mm_sdf_builder.get_color_code(scene.children[0], ctxt2, editor).color
	var tex : String = "clamp(("+child+"-$value)/max(0.0001, $width)+0.5, 0.0, 1.0)"
	if scene.parameters.has("invert") && scene.parameters.invert:
		tex = "(1.0-"+tex+")"
	match ctxt.type:
		"rgba":
			tex = "vec4(vec3("+tex+"), 1.0)"
		"color":
			tex = "vec3("+tex+")"
	return { color = tex }
