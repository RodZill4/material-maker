extends "res://addons/material_maker/sdf_builder/base.gd"

func _ready():
	pass # Replace with function body.

func get_children_types():
	return [ "SDF2D", "SDF2D_COLOR" ]

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
	]

func get_includes():
	return [ "rotate" ]

func shape_code_pre(scene : Dictionary, uv : String = "$uv") -> String:
	return ""

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return ""

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	var assigned : bool = false
	data.code += "float %s;\n" % output_name
	var init_value = shape_code(scene, uv)
	if init_value != "":
		data.code += shape_code_pre(scene, uv)
		data.code += "%s = %s;\n" % [ output_name, init_value ]
		assigned = true
		if editor:
			data.code += "if (index == -%d) return %s*$scale;\n" % [ scene.index, output_name ]
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, uv, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
		if data2.has("outputs"):
			if data2.has("code"):
				data.code += data2.code
			if assigned:
				data.code += "%s = min(%s, %s);\n" % [ output_name, output_name, data2.outputs[0].sdf2d ]
			else:
				data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf2d ]
				assigned = true

func mod_uv_code(_scene : Dictionary, output_name : String) -> String:
	return ""

func mod_code(scene : Dictionary, output_name : String, editor : bool) -> String:
	return ""

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf2d=output_name, type="sdf2d" } ] }
	mm_sdf_builder.add_parameters(scene, data, get_parameter_defs())
	data.code = "vec2 %s_p = %s - vec2($position_x, $position_y);\n" % [ output_name, uv ]
	data.code += "%s_p = rotate(%s_p, radians($angle))/$scale;\n" % [ output_name, output_name ]
	data.code += mod_uv_code(scene, output_name)
	shape_and_children_code(scene, data, "%s_p" % output_name, editor)
	data.code += mod_code(scene, output_name, editor)
	data.code += "%s *= $scale;\n" % output_name
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> Dictionary:
	var color_code : String = ""
	var ctxt2 : Dictionary = ctxt.duplicate()
	ctxt2.local_uv = "$(name_uv)_n%d_p" % scene.index
	var colored_children : Array = []
	var else_color : String = ""
	var first : bool = true
	for i in range(scene.children.size()):
		var s = scene.children[scene.children.size() - i - 1]
		if mm_sdf_builder.item_types[mm_sdf_builder.item_ids[s.type]].item_category == "TEX":
			continue
		var child_color_code = mm_sdf_builder.get_color_code(s, ctxt2, editor)
		if ! child_color_code.has("color"):
			continue
		if ! child_color_code.has("distance"):
			if else_color == "":
				else_color = child_color_code.color
			continue
		if first:
			first = false
		else:
			color_code += " else "
		color_code += "if (%s < 0.0) {\n%s\n}\n" % [ child_color_code.distance, child_color_code.color ]
	if else_color != "":
		if first:
			color_code += "%s\n" % [ else_color ]
		else:
			color_code += " else {\n%s\n}" % [ else_color ]
	elif first:
		return { distance = "_n%d" % scene.index }
	return { color = color_code, distance = "_n%d" % scene.index }
