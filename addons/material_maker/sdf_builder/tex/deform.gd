extends "res://addons/material_maker/sdf_builder/base.gd"


func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ default=0.0, label="Amount", max=1, min=-1, name="amount", step=0.01, type="float" },
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
	var tex : String
	if scene.children.empty():
		tex = "1.0"
		match ctxt.type:
			"rgba":
				tex = "vec4(vec3("+tex+"), 1.0)"
			"color":
				tex = "vec3("+tex+")"
	else:
		var deform : String = "vec3(0.0)"
		var ctxt2 : Dictionary
		if scene.children.size() > 1.0:
			ctxt2 = ctxt.duplicate()
			ctxt2.type = "color"
			var deform_color_code : Dictionary = mm_sdf_builder.get_color_code(scene.children[1], ctxt2, editor)
			if deform_color_code.has("color"):
				deform = deform_color_code.color
		ctxt2 = ctxt.duplicate()
		if ctxt.has("geometry") and ctxt.geometry == "sdf3d":
			ctxt2.uv = "(%s+$amount*(%s.xyz-vec3(0.5)))" % [ ctxt2.uv, deform ]
		else:
			ctxt2.uv = "(%s+$amount*(%s.xy-vec2(0.5)))" % [ ctxt2.uv, deform ]
		var tex_color_code : Dictionary = mm_sdf_builder.get_color_code(scene.children[0], ctxt2, editor)
		if tex_color_code.has("color"):
			tex = tex_color_code.color
	return { color = tex }
