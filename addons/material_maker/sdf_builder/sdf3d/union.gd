extends "res://addons/material_maker/sdf_builder/base.gd"


func _ready():
	pass # Replace with function body.

func get_children_types():
	return [ "SDF3D", "SDF3D_COLOR" ]

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.z", name="position_z", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Rotation.x", name="angle_x", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.y", name="angle_y", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.z", name="angle_z", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0 },
	]

func get_includes():
	return [ "rotate" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return ""

func shape_and_children_code(scene : Dictionary, data : Dictionary, uv : String = "$uv", editor : bool = false):
	var output_name = "$(name_uv)_n%d" % scene.index
	var assigned : bool = false
	data.code += "float %s;\n" % output_name
	var init_value = shape_code(scene, uv)
	if init_value != "":
		data.code += "%s = %s;\n" % [ output_name, init_value ]
		assigned = true
	if editor:
		data.code += "if (index == -%d) return %s*$scale;\n" % [ scene.index, output_name ]
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, "%s_p" % output_name, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
		if data2.has("outputs"):
			if data2.has("code"):
				data.code += data2.code
			if assigned:
				data.code += "%s = min(%s, %s);\n" % [ output_name, output_name, data2.outputs[0].sdf3d ]
			else:
				data.code += "%s = %s;\n" % [ output_name, data2.outputs[0].sdf3d ]
				assigned = true
	if ! assigned:
		data.code += "%s = 1000000.0;\n" % [ output_name ]

func mod_uv_code(_scene : Dictionary, output_name : String) -> String:
	return ""

func mod_code(scene : Dictionary, output_name : String, editor : bool) -> String:
	return ""

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf3d=output_name, type="sdf3d" } ] }
	mm_sdf_builder.add_parameters(scene, data, get_parameter_defs())
	data.code = "vec3 %s_p = %s;\n" % [ output_name, uv ]
	if editor or mm_sdf_builder.check_non_zero_param(scene, "position_x") or mm_sdf_builder.check_non_zero_param(scene, "position_y") or mm_sdf_builder.check_non_zero_param(scene, "position_z"):
		data.code += "%s_p -= vec3($position_x, $position_y, $position_z);\n" % output_name
	data.code += mm_sdf_builder.generate_rotate_3d("%s_p" % output_name, scene, editor)
	if editor or mm_sdf_builder.check_non_zero_param(scene, "scale", 1.0):
		data.code += "%s_p /= $scale;\n" % [ output_name ]
	data.code += mod_uv_code(scene, output_name)
	shape_and_children_code(scene, data, "%s_p" % output_name, editor)
	data.code += mod_code(scene, output_name, editor)
	if editor or mm_sdf_builder.check_non_zero_param(scene, "scale", 1.0):
		data.code += "%s *= $scale;\n" % output_name
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data

func get_coloring_tolerance() -> String:
	return "0.001"

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> Dictionary:
	var color_code : String = ""
	var ctxt2 : Dictionary = ctxt.duplicate()
	ctxt2.local_uv = "$(name_uv)_n%d_p" % scene.index
	var colored_children : Array = []
	var color_count : int = 0
	var distance_count : int = 0
	for s in scene.children:
		if mm_sdf_builder.item_types[mm_sdf_builder.item_ids[s.type]].item_category == "TEX":
			continue
		var child_color_code = mm_sdf_builder.get_color_code(s, ctxt2, editor)
		colored_children.append(child_color_code)
		if child_color_code.has("color"):
			color_count += 1
			if child_color_code.has("distance"):
				distance_count += 1
	if color_count == 0:
		return { distance = "_n%d" % scene.index }
	if distance_count == 0:
		for c in colored_children:
			if c.has("color"):
				return { color = c.color, distance = "_n%d" % scene.index }
	var first : bool = true
	for i in range(colored_children.size()):
		if ! colored_children[i].has("distance"):
			continue
		if first:
			first = false
			color_code += "int $(name_uv)_n%d_id = %d;\nfloat $(name_uv)_n%d_best_d = %s;\n" % [ scene.index, i, scene.index, colored_children[i].distance ]
		else:
			color_code += "if ($(name_uv)_n%d_best_d > %s) { $(name_uv)_n%d_best_d = %s; $(name_uv)_n%d_id = %d; }\n" % [ scene.index, colored_children[i].distance, scene.index, colored_children[i].distance, scene.index, i ]
	first = true
	var else_color = ""
	for i in range(colored_children.size()):
		if ! colored_children[i].has("color"):
			continue
		if ! colored_children[i].has("distance"):
			if else_color == "":
				else_color = colored_children[i].color
			continue
		if first:
			first = false
		else:
			color_code += " else "
		color_code += "if ($(name_uv)_n%d_id == %d) {\n%s\n}\n" % [ scene.index, i, colored_children[i].color ]
	if else_color != "":
		color_code += " else {\n%s\n}" % [ else_color ]
	return { color = color_code, distance = "_n%d" % scene.index }

