extends RefCounted
class_name MMPixels


var size : Vector2i = Vector2i(8, 8)
var bpp : int = 1
var palette : PackedColorArray = PackedColorArray()
var pixels : PackedInt32Array = PackedInt32Array()


func _init():
	palette.clear()
	var colors : int = 1 << bpp
	for c in range(colors):
		var color : Color = Color(1, 1, 1).darkened(float(colors-c-1)/float(colors-1))
		palette.append(color)
	update_data()

func update_data() -> void:
	if palette.size() < 1 << bpp:
		while palette.size() < 1 << bpp:
			palette.append(Color(0, 0, 0))
	elif palette.size() > 1 << bpp:
		palette = palette.slice(0, 1 << bpp)
	var pixels_per_word : int = 32 / bpp
	var num_words : int = 1+(size.x*size.y-1) / pixels_per_word
	pixels.clear()
	for i in range(num_words):
		pixels.append(0)

func _to_string() -> String:
	return ""

func duplicate() -> MMPixels:
	var copy = MMPixels.new()
	copy.size = size
	copy.bpp = bpp
	copy.palette = palette.duplicate()
	copy.pixels = pixels.duplicate()
	return copy

func compare(other : MMPixels) -> bool:
	return false

func set_size(w : int, h : int, b : int) -> void:
	var old : MMPixels = duplicate()
	size.x = w
	size.y = h
	bpp = maxi(b, 1)
	update_data()
	for x in range(w):
		for y in range(h):
			set_color_index(x, y, old.get_color_index(x, y))

func get_color_index(x : int, y : int) -> int:
	if x < 0 or y < 0 or x >= size.x or y >= size.y:
		return 0
	var pixels_per_word : int = 32 / bpp
	var mask = (1 << bpp) - 1
	var index = x + size.x * y
	return mask & (pixels[index/pixels_per_word] >> (bpp*(index%pixels_per_word)))

func set_color_index(x : int, y : int, c : int) -> void:
	if x < 0 or y < 0 or x >= size.x or y >= size.y:
		return
	var pixels_per_word : int = 32 / bpp
	var mask : int = (1 << bpp) - 1
	var index : int = x + size.x * y
	var word_index : int = index/pixels_per_word
	var shift : int = bpp*(index%pixels_per_word)
	pixels[word_index] &= ~(mask << shift)
	pixels[word_index] |= (c & mask) << shift

func get_shader_params(parameter_name : String, attribute : String = "uniform") -> String:
	var rv = ""
	for p : MMGenBase.ShaderUniform in get_parameters(parameter_name):
		rv += p.to_str(attribute)
	return rv

func get_parameters(parameter_name : String) -> Array[MMGenBase.ShaderUniform]:
	var rv : Array[MMGenBase.ShaderUniform] = []
	rv.append(MMGenBase.ShaderUniform.new("p_%s_palette" % parameter_name, "vec4", palette, palette.size()))
	rv.append(MMGenBase.ShaderUniform.new("p_%s_pixels" % parameter_name, "int", pixels, pixels.size()))
	return rv

func get_parameter_values(parameter_name : String) -> Dictionary:
	var rv : Dictionary = {}
	rv["p_%s_palette" % parameter_name] = palette
	rv["p_%s_pixels" % parameter_name] = pixels
	return rv

func get_shader(parameter_name : String) -> String:
	var shader
	shader  = "const ivec2 "+parameter_name+"_size = ivec2(%d, %d);\n" % [ size.x, size.y ]
	shader += "vec4 "+parameter_name+"_pixels_fct(ivec2 v) {\n"
	shader += "\tif (v.x < 0 || v.x >= %d || v.y < 0 || v.y >= %d) {\n" % [ size.x, size.y ]
	shader += "\t\treturn p_%s_palette[0];\n" % parameter_name
	shader += "\t} else {\n"
	shader += "\t\tint i = v.x+%d*v.y;\n" % size.x
	shader += "\t\tint c = %d & (p_%s_pixels[i/%d] >> (%d*(i%%%d)));\n" % [ (1 << bpp)-1, parameter_name, 32/bpp, bpp, 32/bpp ]
	shader += "\t\treturn p_%s_palette[c];\n" % parameter_name
	shader += "\t}\n"
	shader += "}\n"
	return shader

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
		palette.clear()
		for c in v.pl:
			palette.append(Color(c.r, c.g, c.b, c.a))
		pixels.clear()
		for p in v.px:
			pixels.append(int(p))
	elif typeof(v) == TYPE_OBJECT and v.get_script() == get_script():
		size = v.size
		bpp = v.bpp
		palette = v.palette.duplicate()
		pixels = v.pixels.duplicate()
	else:
		print("Cannot deserialize pixels")
