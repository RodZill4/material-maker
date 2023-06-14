@tool
extends MMGenBase
class_name MMGenTexture


# Base class for texture generators that provide a texture as output


var texture : ImageTexture = ImageTexture.new()


func get_output_defs(_show_hidden : bool = false) -> Array:
	return [ { type="rgba" } ]

func get_adjusted_uv(uv : String) -> String:
	return uv

func _get_shader_code_lod(uv : String, _output_index : int, context : MMGenContext, is_greyscale : bool = false, lod : float = -1.0, texture_suffix : String = "_tex") -> ShaderCode:
	var genname = "o"+str(get_instance_id())
	var rv = ShaderCode.new()
	rv.output_type = "f" if is_greyscale else "rgba"
	var texture_name = genname+texture_suffix
	var variant_index = context.get_variant(self, uv)
	var type = "float" if is_greyscale else "vec4"
	var greyscale_select = ".r" if is_greyscale else ""
	if variant_index == -1:
		variant_index = context.get_variant(self, uv)
		rv.add_uniform(texture_name, "sampler2D", texture)
		if lod < 0.0:
			rv.code = "%s %s_%d = textureLod(%s, %s, 0.0)%s;\n" % [ type, genname, variant_index, texture_name, get_adjusted_uv(uv), greyscale_select ]
		else:
			rv.add_uniform("p_%s_lod" % genname, "float", lod)
			rv.code = "%s %s_%d = textureLod(%s, %s, p_o%d_lod)%s;\n" % [ type, genname, variant_index, texture_name, get_adjusted_uv(uv), get_instance_id(), greyscale_select ]
	rv.output_values[rv.output_type] = "%s_%d" % [ genname, variant_index ]
	return rv

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	return _get_shader_code_lod(uv, output_index, context)
