tool
extends MMGenBase
class_name MMGenExport

"""
Can be used to export an additional texture
"""

var texture = null

# The default texture size as a power-of-two exponent
const TEXTURE_SIZE_DEFAULT = 10  # 1024x1024

func get_image_size() -> int:
	var rv : int
	if parameters.has("size"):
		rv = int(pow(2, parameters.size))
	else:
		rv = int(pow(2, TEXTURE_SIZE_DEFAULT))
	return rv

func get_type() -> String:
	return "export"

func get_type_name() -> String:
	return "Export"

func get_parameter_defs() -> Array:
	return [
			{ name="size", type="size", first=4, last=12, default=10 },
			{ name="suffix", type="string", default="suffix" }
		]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func render_textures(renderer : MMGenRenderer) -> void:
	print("rendering texture...")
	var source = get_source(0)
	if source != null:
		var result = source.generator.render(source.output_index, renderer, get_image_size())
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		texture = ImageTexture.new()
		result.copy_to_texture(texture)
		result.release()
	else:
		texture = null

func export_textures(prefix, __ = null) -> void:
	print("exporting texture")
	if texture != null:
		var image = texture.get_data()
		image.save_png("%s_%s.png" % [ prefix, parameters.suffix])
