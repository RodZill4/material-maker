tool
extends MMGenShader
class_name MMGenSDF


var scene : Array = []


func _ready():
	pass # Replace with function body.

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
	return [ { type="f" } ]

func set_scene(s : Array):
	scene = s
	var uv = "$uv-vec2(0.5)"
	var shader_model = { includes=[], parameters=[{default=-1, name="index", type="float"}]}
	shader_model.instance = "float $(name)_d(vec2 uv, int index) {\n"
	var first : bool = true
	for i in scene:
		var item_shader_model = mm_sdf_builder.scene_to_shader_model(i, "uv", true)
		shader_model.includes.append_array(item_shader_model.includes)
		shader_model.parameters.append_array(item_shader_model.parameters)
		shader_model.instance += item_shader_model.code.replace("$(name_uv)", "")
		var output_name = item_shader_model.outputs[0].sdf2d.replace("$(name_uv)", "")
		if first:
			shader_model.instance += "float return_value = %s;" % output_name
			first = false
		else:
			shader_model.instance += "return_value = min(return_value, %s);" % output_name
	shader_model.instance += "return return_value;"
	shader_model.instance += "}\n"
	shader_model.code = "float edgewidth = 0.002;\n"
	shader_model.code += "float $(name_uv)_d = -$(name)_d(%s, -1);\n" % uv
	shader_model.code += "float $(name_uv)_d2 = -$(name)_d(%s, int(round($index)));\n" % uv
	shader_model.outputs = [{}]
	shader_model.outputs[0].f = "clamp(0.05*sin($(name_uv)_d*251.327412287)+mix(0.0, mix(0.5, 0.75, smoothstep(-edgewidth, edgewidth, $(name_uv)_d2)), smoothstep(-edgewidth, edgewidth, $(name_uv)_d)), 0.0, 1.0)"
	shader_model.outputs[0].type = "f"
	set_shader_model(shader_model)

func _serialize(data: Dictionary) -> Dictionary:
	data.scene = scene
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("scene"):
		set_scene(data.scene)
