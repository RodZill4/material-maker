tool
extends MMGenTexture
class_name MMGenBuffer

"""
Texture generator buffers, that render their input in a specific resolution and provide the result as output.
This is useful when using generators that sample their inputs several times (such as convolutions)
"""

var updated : bool = false

func _ready() -> void:
	if !parameters.has("size"):
		parameters.size = 9

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

func source_changed(input_port_index : int) -> void:
	updated = false
	.source_changed(input_port_index)

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var source = get_source(0)
	if source != null and !updated:
		var result = source.generator.render(source.output_index, pow(2, parameters.size))
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		result.copy_to_texture(texture)
		result.release()
		texture.flags = Texture.FLAG_MIPMAPS
		updated = true
	var rv = ._get_shader_code_lod(uv, output_index, context, 0 if output_index == 0 else parameters.lod)
	while rv is GDScriptFunctionState:
		rv = yield(rv, "completed")
	return rv

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "buffer"
	return data
