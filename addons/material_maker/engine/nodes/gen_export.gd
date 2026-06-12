@tool
extends MMGenBase
class_name MMGenExport


# Can be used to export an additional texture

var texture = null

# The default texture size as a power-of-two exponent
const TEXTURE_SIZE_DEFAULT = 10  # 1024x1024

enum ImageFormat { PNG, JPG, WEBP, EXR }

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
	var desc_list : PackedStringArray = PackedStringArray()
	desc_list.push_back(TranslationServer.translate("Export"))
	desc_list.push_back(TranslationServer.translate(
			"Defines a texture which will be saved along with other textures on material export."+
			" Can also be triggered via 'Quick export'"))
	return "\n".join(desc_list)

func _serialize(data: Dictionary) -> Dictionary:
	return data

func get_parameter_defs() -> Array:
	var tooltip := """
		Filename for the exported texture.
		$node, $project, $idx and $resolution can be used.
		"""
	return [
			{ name="size", label="Size", type="size", first=4, last=13, default=10 },
			{ name="format", label="Format", default=0, type="enum", values=[
				{ name="PNG" }, { name="JPG" }, { name="WEBP" }, { name="EXR" },
			]},
			{ name="suffix", label="Filename", type="string", default="$project", longdesc=tooltip }
		]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func get_image_format() -> String:
	match parameters.format:
		ImageFormat.PNG:
			return "png"
		ImageFormat.JPG:
			return "jpg"
		ImageFormat.WEBP:
			return "webp"
		ImageFormat.EXR:
			return "exr"
		_: return "png"

func interpret_file_name(file_name : String, path : String = "") -> String:
	var additional_ids : Dictionary[String, String] = { "$node": "unnamed" }

	if "$node" in file_name:
		var source_port : OutputPort = get_source(0)
		if source_port != null:
			var source_node : MMGenBase = source_port.generator
			if source_node:
				additional_ids["$node"] = source_node.get_type_name().to_snake_case()
	
	var graph_node : MMGenBase = self
	while graph_node.get_parent() is MMGenBase:
		graph_node = graph_node.get_parent()
	
	var resolution : String = str(get_image_size())
	return MMLoader.interpret_file_name(file_name, path, "."+get_image_format(), graph_node, additional_ids, resolution)

func export_material(prefix : String, _profile : String, size : int = 0, command_line : bool = false) -> void:
	if size == 0:
		size = get_image_size()
	var source = get_source(0)
	if source != null:
		var texture : MMTexture = await source.generator.render_output_to_texture(source.output_index, Vector2i(size, size))
		if parameters.suffix != "":
			var filename : String = interpret_file_name(parameters.suffix, prefix.get_base_dir())
			await texture.save_to_file(prefix.get_base_dir().path_join(filename))
		else:
			await texture.save_to_file("%s.%s" % [ prefix, get_image_format() ])
