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
	return [ { type="rgb" } ]

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
	shader_model.instance += "return index == 0 ? return_value : 1.0;"
	shader_model.instance += "}\n"
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
	set_shader_model(shader_model)

func _serialize(data: Dictionary) -> Dictionary:
	data.scene = scene
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("scene"):
		set_scene(data.scene)
