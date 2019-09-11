tool
extends MMGenTexture
class_name MMGenBuffer

"""
Texture generator buffers, that render their input in a specific resolution and provide the result as output.
This is useful when using generators that sample their inputs several times (such as convolutions) 
"""

func _ready():
	if !parameters.has("size"):
		parameters.size = 4

func get_type():
	return "buffer"

func get_type_name():
	return "Buffer"

func get_parameter_defs():
	return [ { name="size", type="size", first=4, last=11, default=4 } ]

func get_input_defs():
	return [ { name="in", type="rgba" } ]
	
func get_output_defs():
	return [ { type="rgba" } ]

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	var source = get_source(0)
	if source != null:
		var status = source.generator.render(source.output_index, context.renderer, pow(2, 4+parameters.size))
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
		if status:
			var image : Image = context.renderer.get_texture().get_data()
			texture.create_from_image(image)
			texture.flags = 0
	var rv = ._get_shader_code(uv, output_index, context)
	while rv is GDScriptFunctionState:
		rv = yield(rv, "completed")
	return rv

func _serialize(data):
	data.type = "buffer"
	return data
