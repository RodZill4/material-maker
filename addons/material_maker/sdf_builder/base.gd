extends Node

export var item_type : String
export var item_category : String
export var icon : Texture

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[] }
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, uv, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
	return data

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> Dictionary:
	return {}

static func get_color_code_smooth_union(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> Dictionary:
	var ctxt2 = ctxt.duplicate()
	ctxt2.target = "tmp_%d" % scene.index
	ctxt2.check = false
	var color_code : String = ""
	for s in scene.children:
		var child_color_code : Dictionary = mm_sdf_builder.get_color_code(s, ctxt2, editor)
		if child_color_code.has("distance"):
			if child_color_code.has("color"):
				color_code += child_color_code.color
			else:
				color_code += "\ntmp_%d = current_color_%d;" % [ scene.index, scene.index ]
			color_code += "\ncoef_%d = 1.0/pow(1.0+max(%s, 0.0), 10000.0*pow(0.8-0.3*clamp($color_k, 0.0, 1.0), 10.0));" % [ scene.index, child_color_code.distance ]
			color_code += "\nsum_%d += tmp_%d*coef_%d;" % [ scene.index, scene.index, scene.index ]
			color_code += "\ncoefsum_%d += coef_%d;" % [ scene.index, scene.index ]
		elif child_color_code.has("color"):
			color_code += child_color_code.color
			color_code += "\ncurrent_color_%d = tmp_%d;" % [ scene.index, scene.index ]
	if color_code == "":
		return { distance = "_n%d" % scene.index }
	color_code = ("%s sum_%d;\n%s tmp_%d;\n%s current_color_%d;\nfloat coef_%d;\nfloat coefsum_%d = 0.0;\n" % [ ctxt.glsl_type, scene.index, ctxt.glsl_type, scene.index, ctxt.glsl_type, scene.index, scene.index, scene.index ])+color_code+("%s = sum_%d/coefsum_%d;" % [ ctxt.target, scene.index, scene.index ])
	return { color = color_code, distance = "_n%d" % scene.index }
