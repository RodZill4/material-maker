extends MMShaderBase
class_name MMShaderMaterial


var material : ShaderMaterial


func _init(m : ShaderMaterial = null):
	material = m
	if material == null:
		material = ShaderMaterial.new()
	if material.shader == null:
		material.shader = Shader.new()

func set_shader(shader_code : String) -> bool:
	var shader : Shader = Shader.new()
	shader.code = shader_code
	material.shader = shader
	if material.shader.get_shader_uniform_list().is_empty():
		material.shader = preload("res://material_maker/panels/preview_2d/shader_error.gdshader")
		material.set_shader_parameter("error_tex", preload("res://material_maker/panels/preview_2d/shader_error.png"))
		return true
	return true

func get_parameters() -> Dictionary:
	var rv : Dictionary = {}
	for p in material.get_property_list():
		if p.name.left(17) != "shader_parameter/":
			continue
		var parameter_name : String = p.name.right(-17)
		rv[parameter_name] = material.get_shader_parameter(parameter_name)
	return rv

func set_parameter(name : String, value):
	if value is MMTexture:
		material.set_shader_parameter(name, await value.get_texture())
	else:
		material.set_shader_parameter(name, value)
