tool
extends MMGenBase
class_name MMGenTexture

"""
Base class for texture generators that provide a texture as output
"""

var texture : ImageTexture = ImageTexture.new()

func get_output_defs() -> Array:
	return [ { rgba="", type="rgba" } ]

func _get_shader_code_lod(uv : String, _output_index : int, context : MMGenContext, lod : float = -1.0, texture_suffix : String = "_tex") -> Dictionary:
	var genname = "o"+str(get_instance_id())
	var rv = { globals=[], defs="", code="", type="rgba" }
	var texture_name = genname+texture_suffix
	var variant_index = context.get_variant(self, uv)
	if variant_index == -1:
		variant_index = context.get_variant(self, uv)
		if lod < 0.0:
			rv.code = "vec4 %s_%d = textureLod(%s, %s, 0.0);\n" % [ genname, variant_index, texture_name, uv ]
		else:
			rv.defs = "uniform float p_o%s_lod = %.09f;\n" % [ str(get_instance_id()), lod ]
			rv.code = "vec4 %s_%d = textureLod(%s, %s, p_o%s_lod);\n" % [ genname, variant_index, texture_name, uv, str(get_instance_id()) ]
	rv.rgba = "%s_%d" % [ genname, variant_index ]
	rv.textures = { texture_name:texture }
	return rv

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	return _get_shader_code_lod(uv, output_index, context)
