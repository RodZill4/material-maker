tool
extends MMGenBase
class_name MMGenTexture

"""
Base class for texture generators that provide a texture as output
"""

var texture : ImageTexture = ImageTexture.new()

func get_output_defs():
	return [ { rgba="" } ]

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	var genname = "o"+str(get_instance_id())
	var rv = { defs="", code="" }
	var texture_name = genname+"_tex"
	var variant_index = context.get_variant(self, uv)
	if variant_index == -1:
		variant_index = context.get_variant(self, uv)
		rv.code = "vec4 %s_%d = texture(%s, %s);\n" % [ genname, variant_index, texture_name, uv ]
	rv.rgba = "%s_%d" % [ genname, variant_index ]
	rv.textures = { texture_name:texture }
	return rv