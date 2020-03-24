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
	call_deferred("update_shader")

func update_shader() -> void:
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
	for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
		if p.name == n:
			material.set_shader_param(n, v)
			update_buffer()
			return

func on_texture_changed(n : String) -> void:
	for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
		if p.name == n:
			update_buffer()
			return

func update_buffer() -> void:
	update_again = true
	if !updating:
		updating = true
		while update_again:
			update_again = false
			var result = mm_renderer.render_material(material, pow(2, get_parameter("size")))
			while result is GDScriptFunctionState:
				result = yield(result, "completed")
			if !update_again:
				result.copy_to_texture(texture)
			result.release()
		updating = false
		get_tree().call_group("preview", "on_texture_changed", "o%s_tex" % str(get_instance_id()))

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "buffer"
	return data
