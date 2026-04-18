@tool
extends MMGenShader
class_name MMGenSDF


@export var editor : bool = false
@export var expressions : bool = false
var node_parameters : Array = []
var scene : Array = []


func _ready():
	pass # Replace with function body.

func get_type() -> String:
	return "sdf"

func get_type_name() -> String:
	return "Easy SDF"

func get_filtered_parameter_defs(parameters_filter : String) -> Array:
	if parameters_filter == "":
		return get_parameter_defs()
	else:
		var defs = []
		for p in get_parameter_defs():
			if p.name.begins_with(parameters_filter):
				defs.push_back(p)
		return defs

func get_scene_type() -> String:
	if scene.is_empty():
		return ""
	return mm_sdf_builder.item_types[mm_sdf_builder.item_ids[scene[0].type]].item_category

func set_sdf_scene(s : Array):
	scene = s.duplicate(true)
	var scene_type : String = get_scene_type()
	var shader_model = { includes=[], parameters=[] }
	var uv : String = "$uv"
	var distance_function : String = ""
	var color_function : String = ""
	var default_albedo : String = "vec4(0.0, 0.0, 0.0, 1.0)"
	# Generate distance function
	match scene_type:
		"SDF3D":
			distance_function = "float $(name)_d(vec3 uv"
			color_function = "float $(name)_c(vec3 uv"
			default_albedo = "vec4(1.0, 1.0, 1.0, 1.0)"
		_:
			uv = "$uv-vec2(0.5)"
			distance_function = "float $(name)_d(vec2 uv"
			color_function = "float $(name)_c(vec2 uv"
	if editor:
		distance_function += ", int index"
	
	distance_function += ") {\n"
	color_function += ", out vec4 albedo, out float metallic, out float roughness, out vec3 emission) {\n"
	if editor:
		color_function += "int index = 0;\n"

	color_function += "albedo = "+default_albedo+";\n"
	color_function += "metallic = 0.0;\n"
	color_function += "roughness = 1.0;\n"
	color_function += "emission = vec3(0.0);\n"
	var first : bool = true
	var parameter_defs = node_parameters.duplicate(true)
	for p in parameter_defs:
		p.label = p.shortdesc if p.has("shortdesc") else ""
	for i in scene:
		if i.has("hidden") and i.hidden:
			continue
		var item_shader_model = mm_sdf_builder.scene_to_shader_model(i, "uv", editor)
		if item_shader_model.has("includes"):
			shader_model.includes.append_array(item_shader_model.includes)
		if item_shader_model.has("parameters"):
			parameter_defs.append_array(item_shader_model.parameters)
		if item_shader_model.has("code"):
			var code : String = item_shader_model.code.replace("$(name_uv)", "")
			distance_function += code
			color_function += code
		if item_shader_model.has("outputs"):
			var output = item_shader_model.outputs[0]
			var output_name
			var field : String
			if scene_type == "SDF2D":
				field = "sdf2d"
			else:
				field = "sdf3d"
			if item_shader_model.outputs[0].has(field):
				output_name = item_shader_model.outputs[0][field].replace("$(name_uv)", "")
				if first:
					distance_function += "float return_value = %s;\n" % output_name
					color_function += "float return_value = %s;\n" % output_name
					first = false
				else:
					distance_function += "return_value = min(return_value, %s);\n" % output_name
					color_function += "return_value = min(return_value, %s);\n" % output_name
	var fake_scene = { index=0, type="Union3D", children=scene, parameters={} }
	if scene_type == "SDF2D":
		fake_scene.type = "Union"
	var color_code : Dictionary
	color_code = mm_sdf_builder.get_color_code(fake_scene, { uv="uv", channel="albedo", target="albedo", type="rgba", glsl_type="vec4" }, editor)
	if color_code.has("color"):
		color_function += "\n// Albedo\n"
		color_function += "{\n"+color_code.color+"}\n"
	color_code = mm_sdf_builder.get_color_code(fake_scene, { uv="uv", channel="metallic", target="metallic", type="float", glsl_type="float" }, editor)
	if color_code.has("color"):
		color_function += "\n// Metallic\n"
		color_function += "{\n"+color_code.color+"}\n"
	color_code = mm_sdf_builder.get_color_code(fake_scene, { uv="uv", channel="roughness", target="roughness", type="float", glsl_type="float" }, editor)
	if color_code.has("color"):
		color_function += "\n// Roughness\n"
		color_function += "{\n"+color_code.color+"}\n"
	color_code = mm_sdf_builder.get_color_code(fake_scene, { uv="uv", channel="emission", target="emission", type="color", glsl_type="vec3" }, editor)
	if color_code.has("color"):
		color_function += "\n// Emission\n"
		color_function += "{\n"+color_code.color+"}\n"
	color_function += "\n"
	if first:
		distance_function += "return 1.0;"
		color_function += "return 1.0;"
	elif editor:
		distance_function += "return index == 0 ? return_value : 1.0;"
		color_function += "return index == 0 ? return_value : 1.0;"
	else:
		distance_function += "return return_value;"
		color_function += "return return_value;"
	distance_function += "}\n"
	color_function += "}\n"
	color_function = color_function.replace("$(name_uv)", "")
	shader_model.instance = distance_function + color_function
	match scene_type:
		"SDF3D":
			shader_model.code = "vec4 $(name_uv)_albedo;\n"
			shader_model.code += "float $(name_uv)_metallic;\n"
			shader_model.code += "float $(name_uv)_roughness;\n"
			shader_model.code += "vec3 $(name_uv)_emission;\n"
			shader_model.code += "$(name)_c(%s.xyz*vec3(1.0, -1.0, -1.0), $(name_uv)_albedo, $(name_uv)_metallic, $(name_uv)_roughness, $(name_uv)_emission);\n" % uv
			if editor:
				shader_model.outputs = [{ sdf3d = "@NOCODE $(name)_d(%s, 0)" % uv, type = "sdf3d" }]
			else:
				shader_model.outputs = [{ sdf3d = "@NOCODE $(name)_d(%s*vec3(1.0, -1.0, -1.0))" % uv, type = "sdf3d" }]
			shader_model.parameters = parameter_defs
			shader_model.outputs.push_back({ tex3d = "$(name_uv)_albedo.rgb", type = "tex3d", shortdesc="Albedo" })
			shader_model.outputs.push_back({ tex3d_gs = "clamp($(name_uv)_metallic, 0.0, 1.0)", type = "tex3d_gs", shortdesc="Metallic" })
			shader_model.outputs.push_back({ tex3d_gs = "clamp($(name_uv)_roughness, 0.0, 1.0)", type = "tex3d_gs", shortdesc="Roughness" })
			shader_model.outputs.push_back({ tex3d = "$(name_uv)_emission", type = "tex3d", shortdesc="Emission" })
		_:
			shader_model.parameters = parameter_defs
			shader_model.code = "vec4 $(name_uv)_albedo;\n"
			shader_model.code += "float $(name_uv)_metallic;\n"
			shader_model.code += "float $(name_uv)_roughness;\n"
			shader_model.code += "vec3 $(name_uv)_emission;\n"
			shader_model.code += "$(name)_c(%s, $(name_uv)_albedo, $(name_uv)_metallic, $(name_uv)_roughness, $(name_uv)_emission);\n" % uv
			if editor:
				parameter_defs.push_back({default=-1, name="index", type="float"})
				shader_model.outputs = [{ sdf2d = "@NOCODE $(name)_d(%s, 0)" % uv, type = "sdf2d" }]
			else:
				shader_model.outputs = [{ sdf2d = "@NOCODE $(name)_d(%s)" % uv, type = "sdf2d", shortdesc="SDF" }]
			shader_model.outputs.push_back({ rgba = "$(name_uv)_albedo", type = "rgba", shortdesc="Albedo" })
			shader_model.outputs.push_back({ f = "$(name_uv)_metallic", type = "f", shortdesc="Metallic" })
			shader_model.outputs.push_back({ f = "$(name_uv)_roughness", type = "f", shortdesc="Roughness" })
			shader_model.outputs.push_back({ rgb = "$(name_uv)_emission", type = "rgb", shortdesc="Emission" })
	for p in parameter_defs:
		if ! parameters.has(p.name):
			if p.type == "float" and p.default is int:
				parameters[p.name] = float(p.default)
			else:
				parameters[p.name] = p.default
	if editor and expressions:
		for p in parameter_defs:
			if p.has("parmexpr"):
				shader_model.code = shader_model.code.replace("$"+p.name, p.parmexpr)
				shader_model.instance = shader_model.instance.replace("$"+p.name, p.parmexpr)
	set_shader_model(shader_model)

func _serialize(data: Dictionary) -> Dictionary:
	data.node_parameters = node_parameters.duplicate(true)
	data.sdf_scene = mm_sdf_builder.serialize_scene(scene)
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("node_parameters"):
		node_parameters = data.node_parameters.duplicate(true)
	if data.has("sdf_scene"):
		set_sdf_scene(mm_sdf_builder.deserialize_scene(data.sdf_scene))

func edit(node, tab : String = "") -> void:
	if scene != null:
		var edit_window = load("res://material_maker/windows/sdf_builder/sdf_builder.tscn").instantiate()
		node.get_parent().add_child(edit_window)
		edit_window.set_node_parameter_defs(node_parameters)
		edit_window.set_sdf_scene(scene)
		edit_window.connect("node_changed", Callable(node, "update_sdf_generator"))
		edit_window.connect("editor_window_closed", Callable(node, "finalize_generator_update"))
		edit_window.popup_centered()
