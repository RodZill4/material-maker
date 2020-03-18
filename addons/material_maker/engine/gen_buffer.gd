tool
extends MMGenTexture
class_name MMGenBuffer

"""
Texture generator buffers, that render their input in a specific resolution and provide the result as output.
This is useful when using generators that sample their inputs several times (such as convolutions)
"""

var material : ShaderMaterial = null
var updating : bool = false
var update_again : bool = false

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	if !parameters.has("size"):
		parameters.size = 9
	add_to_group("preview")

func get_type() -> String:
	return "buffer"

func get_type_name() -> String:
	return "Buffer"

func get_parameter_defs() -> Array:
	return [
			{ name="size", type="size", first=4, last=12, default=4 },
			{ name="lod", type="float", min=0, max=10.0, step=0.01, default=0 }
		]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func get_output_defs() -> Array:
	return [ { type="rgba" }, { type="rgba" } ]

func source_changed(_input_port_index : int) -> void:
	if !is_inside_tree():
		return
	var context : MMGenContext = MMGenContext.new()
	var source = {}
	var source_output = get_source(0)
	if source_output != null:
		source = source_output.generator.get_shader_code("uv", source_output.output_index, context)
		while source is GDScriptFunctionState:
			source = yield(source, "completed")
	if source.empty():
		source = { defs="", code="", textures={}, rgba="vec4(0.0)" }
	material.shader.code = mm_renderer.generate_shader(source)
	if source.has("textures"):
		for k in source.textures.keys():
			material.set_shader_param(k, source.textures[k])
	update_buffer()

func on_float_parameter_changed(n : String, v : float) -> void:
	material.set_shader_param(n, v)
	update_buffer()

func update_buffer():
	update_again = true
	if !updating:
		updating = true
		while update_again:
			update_again = false
			var result = mm_renderer.render_material(material, pow(2, parameters.size))
			while result is GDScriptFunctionState:
				result = yield(result, "completed")
			if !update_again:
				result.copy_to_texture(texture)
			result.release()
		updating = false

func __get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var source = get_source(0)
	if source != null:
		var result = source.generator.render(source.output_index, pow(2, parameters.size))
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		result.copy_to_texture(texture)
		result.release()
		texture.flags = Texture.FLAG_MIPMAPS
	var rv = ._get_shader_code_lod(uv, output_index, context, 0 if output_index == 0 else parameters.lod)
	while rv is GDScriptFunctionState:
		rv = yield(rv, "completed")
	return rv

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "buffer"
	return data
