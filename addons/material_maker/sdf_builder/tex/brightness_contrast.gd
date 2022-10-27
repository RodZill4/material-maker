extends "res://addons/material_maker/sdf_builder/base.gd"


func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ default=0.0, label="Brightness", max=1, min=-1, name="brightness", step=0.01, type="float" },
		{ default=1.0, label="Contrast", max=2, min=0, name="contrast", step=0.01, type="float" },
		{ default=true, label="Clamp", name="clamp", type="boolean" }
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

	match ctxt.type:
		"rgba":
			child = "vec4(vec3(0.5), 1.0)"
		"color":
			child = "vec3(0.5)"
		_:
			child = "0.5"
	if ! scene.children.empty():
		var child_color_code : Dictionary = mm_sdf_builder.get_color_code(scene.children[0], ctxt, editor)
		if child_color_code.has("color"):
			child = child_color_code.color
	var type : String = ""
	match ctxt.type:
		"rgba":
			type = "vec4"
		"color":
			type = "vec3"
	var tex : String
	if ctxt.type == "rgba":
		tex = "%s*vec4(vec3($contrast), 1.0)+vec4(vec3($brightness+0.5-$contrast*0.5), 0.0)" % [ child ]
	else:
		tex = "%s*$contrast+%s($brightness+0.5-$contrast*0.5)" % [ child, type ]
	if ! scene.parameters.has("clamp") || scene.parameters.clamp:
		tex = "clamp(%s, %s(0.0), %s(1.0))" % [ tex, type, type ]
	return { color = tex }
