@tool
extends MMGenBase
class_name MMGenExport


# Can be used to export an additional texture


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

func get_description() -> String:
	return "\n".join(["Export",
			"Defines a texture which will be saved " +
			"along with other textures on material export"])

func get_parameter_defs() -> Array:
	return [
			{ name="size", label="Size", type="size", first=4, last=13, default=10 },
			{ name="suffix", label="Suffix", type="string", default="suffix" }
		]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func export_material(prefix : String, _profile : String, size : int = 0) -> void:
	if size == 0:
		size = get_image_size()
	var source = get_source(0)
	if source != null:
		var texture : MMTexture = await source.generator.render_output_to_texture(source.output_index, Vector2i(size, size))
		if parameters.suffix != "":
			await texture.save_to_file("%s_%s.png" % [ prefix, parameters.suffix ])
		else:
			await texture.result.save_to_file("%s.png" % [ prefix ])
