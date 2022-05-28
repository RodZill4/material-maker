tool
extends MMGenShader
class_name MMGenSDF


export var editor : bool = false
var scene : Array = []


func _ready():
	pass # Replace with function body.

func get_type() -> String:
	return "sdf"

func get_type_name() -> String:
	return "EasySDF"

func get_filtered_parameter_defs(parameters_filter : String) -> Array:
	if parameters_filter == "":
		return get_parameter_defs()
	else:
		var defs = []
		for p in get_parameter_defs():
			if p.name.begins_with(parameters_filter):
				defs.push_back(p)
		return defs

func get_output_defs(_show_hidden : bool = false) -> Array:
	if editor:
		return [ { type="rgb" } ]
	else:
		return [ { type="sdf2d" } ]

func set_sdf_scene(s : Array):
	scene = s.duplicate(true)
	var uv = "$uv-vec2(0.5)"
	var shader_model = { includes=[], parameters=[]}
	shader_model.instance = "float $(name)_d(vec2 uv, int index) {\n"
	var first : bool = true
	var parameter_defs = []
	for i in scene:
		var item_shader_model = mm_sdf_builder.scene_to_shader_model(i, "uv", editor)
		if item_shader_model.has("includes"):
			shader_model.includes.append_array(item_shader_model.includes)
		if item_shader_model.has("parameters"):
			parameter_defs.append_array(item_shader_model.parameters)
		if item_shader_model.has("code"):
			shader_model.instance += item_shader_model.code.replace("$(name_uv)", "")
		if item_shader_model.has("outputs"):
			var output_name = item_shader_model.outputs[0].sdf2d.replace("$(name_uv)", "")
			if first:
				shader_model.instance += "float return_value = %s;" % output_name
				first = false
			else:
				shader_model.instance += "return_value = min(return_value, %s);" % output_name
	if first:
		shader_model.instance += "return 1.0;"
	else:
		shader_model.instance += "return index == 0 ? return_value : 1.0;"
	shader_model.instance += "}\n"
	if editor:
		shader_model.code = "float edgewidth = 0.0001;\n"
		shader_model.code += "float $(name_uv)_d = -$(name)_d(%s, 0);\n" % uv
		shader_model.code += "float $(name_uv)_d2 = -$(name)_d(%s, int(round($index)));\n" % uv
		shader_model.code += "float $(name_uv)_d3 = -$(name)_d(%s, -int(round($index)));\n" % uv
		shader_model.code += "float color = 0.25*smoothstep(-edgewidth, edgewidth, $(name_uv)_d);\n"
		shader_model.code += "color += 0.5*smoothstep(-edgewidth, edgewidth, $(name_uv)_d2);\n"
		shader_model.code += "color += 0.05*sin($(name_uv)_d*251.327412287);\n"
		shader_model.outputs = [{}]
		shader_model.outputs[0].rgb = "clamp(color+vec3(0.2, 0.2, 0.0)*smoothstep(-edgewidth, edgewidth, $(name_uv)_d3), vec3(0.0), vec3(1.0))"
		shader_model.outputs[0].type = "rgb"

		parameter_defs.push_back({default=-1, name="index", type="float"})
		shader_model.parameters = parameter_defs
	else:
		shader_model.code = "float $(name_uv)_d = $(name)_d(%s, 0);\n" % uv
		shader_model.outputs = [{}]
		shader_model.outputs[0].sdf2d = "$(name_uv)_d"
		shader_model.outputs[0].type = "sdf2d"
	set_shader_model(shader_model)

func _serialize(data: Dictionary) -> Dictionary:
	data.sdf_scene = scene
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("sdf_scene"):
		set_sdf_scene(data.sdf_scene)

func edit(node) -> void:
	if scene != null:
		var edit_window = load("res://material_maker/windows/sdf_builder/sdf_builder.tscn").instance()
		node.get_parent().add_child(edit_window)
		edit_window.set_sdf_scene(scene)
		edit_window.connect("node_changed", node, "update_sdf_generator")
		edit_window.connect("editor_window_closed", node, "finalize_generator_update")
		edit_window.popup_centered()
