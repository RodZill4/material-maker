extends RefCounted
class_name MMPixels


var size : Vector2i = Vector2i(8, 8)
var bpp : int = 1
var palette : PackedColorArray = PackedColorArray()
var pixels : PackedInt32Array = PackedInt32Array()


func _to_string() -> String:
	return ""

func duplicate() -> Object:
	var copy = get_script().new()
	copy.size = size
	copy.bpp = size
	copy.palette = palette.duplicate()
	copy.pixels = pixels.duplicate()
	return copy

func get_shader_params(parameter_name : String, attribute : String = "uniform") -> String:
	var rv = ""
	for p : MMGenBase.ShaderUniform in get_parameters(parameter_name):
		rv += p.to_str(attribute)
	return rv

func get_parameters(parameter_name : String) -> Array[MMGenBase.ShaderUniform]:
	var rv : Array[MMGenBase.ShaderUniform] = []
	rv.append(MMGenBase.ShaderUniform.new("p_%s_size" % parameter_name, "ivec2", size))
	rv.append(MMGenBase.ShaderUniform.new("p_%s_bpp" % parameter_name, "int", bpp))
	rv.append(MMGenBase.ShaderUniform.new("p_%s_palette" % parameter_name, "vec4", palette, palette.size()))
	rv.append(MMGenBase.ShaderUniform.new("p_%s_pixels" % parameter_name, "int", pixels, pixels.size()))
	return rv

func get_parameter_values(parameter_name : String) -> Dictionary:
	var rv : Dictionary = {}
	rv["p_%s_size" % parameter_name] = size
	rv["p_%s_bpp" % parameter_name] = bpp
	rv["p_%s_palette" % parameter_name] = palette
	rv["p_%s_pixels" % parameter_name] = pixels
	return rv

func get_shader(parameter_name : String) -> String:
	return "p_%s_points" % parameter_name

func serialize() -> Dictionary:
	var rv : Dictionary = {}
	rv.type = "Pixels"
	rv.w = size.x
	rv.h = size.y
	rv.bpp = bpp
	rv.pl = []
	for c in palette:
		rv.pl.append({ r=c.r, g=c.g, b=c.b, a=c.a })
	rv.px = []
	for p in pixels:
		rv.px.append(p)
	return rv

func deserialize(v) -> void:
	if typeof(v) == TYPE_DICTIONARY and v.has("type") and v.type == "Pixels":
		size.x = int(v.w)
		size.y = int(v.h)
		bpp = int(v.bpp)
		palette = PackedColorArray()
		for c in v.pl:
			palette.append(Color(c.r, c.g, c.b, c.a))
		pixels = PackedInt32Array()
		for p in v.px:
			pixels.append(int(p))
	elif typeof(v) == TYPE_OBJECT and v.get_script() == get_script():
		size = v.size
		bpp = v.bpp
		palette = v.palette.duplicate()
		pixels = v.pixels.duplicate()
	else:
		print("Cannot deserialize pixels")
