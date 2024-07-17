extends MMShaderBase
class_name MMShaderCompute


var compute_shader : MMComputeShader = MMComputeShader.new()


func set_shader_from_shadercode(shader_code : MMGenBase.ShaderCode, is_32_bits : bool = false, compare_texture : MMTexture = null) -> bool:
	return await compute_shader.set_shader_from_shadercode(shader_code, is_32_bits, compare_texture)

func get_parameters() -> Dictionary:
	return compute_shader.get_parameters()

func set_parameter(name : String, value):
	compute_shader.set_parameter(name, value)

func get_texture_type(index : int = 0) -> int:
	return compute_shader.output_textures[index].type

func render(texture : MMTexture, size : int) -> bool:
	return await compute_shader.render(texture, Vector2i(size, size))

func get_difference() -> int:
	return compute_shader.get_difference()

func get_render_time() -> int:
	return compute_shader.render_time
