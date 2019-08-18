tool
extends MMGenBase
class_name MMGenBuffer

var texture : ImageTexture = ImageTexture.new()

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
	return [ { rgba="" } ]

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	var source = get_source(0)
	if source != null:
		print(parameters.size)
		var status = source.generator.render(source.output_index, context.renderer, pow(2, 4+parameters.size))
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
		if status:
			var image : Image = context.renderer.get_texture().get_data()
			texture.create_from_image(image)
			texture.flags = 0
	var rv = { defs="" }
	var variant_index = context.get_variant(self, uv)
	if variant_index == -1:
		variant_index = context.get_variant(self, uv)
	var texture_name = name+"_tex"
	rv.code = "vec4 %s_%d = texture(%s, %s);\n" % [ name, variant_index, texture_name, uv ]
	rv.rgba = "%s_%d" % [ name, variant_index ]
	rv.textures = { texture_name:texture }
	return rv