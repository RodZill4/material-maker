extends Node

func _ready():
	pass # Replace with function body.

func get_shape_names() -> Array:
	var names = []
	for c in get_children():
		names.push_back(c.name)
	return names

func get_includes(scene : Dictionary) -> Array:
	var includes : Array = []
	var type = get_node(scene.type)
	if type.has_method("get_includes"):
		for i in type.get_includes():
			if !includes.has(i):
				includes.push_back(i)
	if scene.has("children"):
		for c in scene.children:
			for i in get_includes(c):
				if !includes.has(i):
					includes.push_back(i)
	return includes

func add_parameters(scene : Dictionary, data : Dictionary, parameter_defs : Array):
	pass

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv-vec2(0.5)", editor = false) -> Dictionary:
	var scene_node = get_node(scene.type)
	var shader_model = scene_node.scene_to_shader_model(scene, uv, editor)
	if editor:
		for p in scene_node.get_parameter_defs():
			p = p.duplicate(true)
			if scene.parameters.has(p.name):
				p.default = scene.parameters[p.name]
			var new_name = "n%d_%s" % [ scene.index, p.name ]
			shader_model.code = shader_model.code.replace("$"+p.name, "$"+new_name)
			p.name = new_name
			shader_model.parameters.push_back(p)
	else:
		for p in scene_node.get_parameter_defs():
			shader_model.code = shader_model.code.replace("$"+p.name, "%.09f" % scene.parameters[p.name])
	shader_model.includes = get_includes(scene)
	return shader_model
