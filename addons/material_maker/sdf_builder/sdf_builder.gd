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

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv-vec2(0.5)", editor = false) -> Dictionary:
	var shader_model = get_node(scene.type).scene_to_shader_model(scene, uv, editor)
	shader_model.includes = get_includes(scene)
	return shader_model
