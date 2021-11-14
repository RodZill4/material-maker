tool
extends MMGenBuffer
class_name MMGenPalettize
enum OutputType {COLOR, INDEXED}
var palette = []
var output_type = OutputType.COLOR

func _ready():
	self.version = VERSION_SIMPLE
	._ready()

func get_type() -> String:
	return "palettize"

func get_type_name() -> String:
	return "Palettize"

func get_input_defs() -> Array:
	return [ 
		{ name="in", type="rgba" },
		{ name="palette", type="rgba"}
	]

func get_parameter_defs() -> Array:
	var parameter_defs : Array = [ 
		{ name="size", type="size", first=4, last=13, default=7 },
		{ name="palette_size", type="size", first=1, last=4, default=5 }
	]
	return parameter_defs

func source_changed(_input_port_index : int) -> void:
	match _input_port_index:
		0:
			call_deferred("update_shader")
		1:
			call_deferred("update_palette")

func set_parameter(n : String, v) -> void:
	if is_inside_tree():
		if n == "palette_size":
			update_palette()
		else:
			get_tree().call_group("preview", "on_texture_invalidated", "o%s_tex" % str(get_instance_id()))
	.set_parameter(n, v)
	

func update_palette():
	print("update_palette")
	palette.clear()
	var source = get_source(0)
	if source == null:
		get_tree().call_group("preview", "on_texture_invalidated", "o%s_tex" % str(get_instance_id()))
		return
	
	var result = source.generator.render(self, source.output_index, 128)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	result.release(self)
	var paletteImageTex = ImageTexture.new()
	result.copy_to_texture(paletteImageTex)
	var paletteImage = paletteImageTex.get_data()
	paletteImage.convert(Image.FORMAT_RGBA8)
	paletteImage.lock()
	var palette_size = get_parameter("palette_size")
	var dimension = pow(2, palette_size)
	palette.resize(pow( dimension, 2) )
	print("palette_size = %s" % [str(palette.size())])
	
	var s_x = paletteImage.get_width() / dimension
	var s_y = paletteImage.get_height() / dimension
	for y in range(0, dimension):
		for x in range(0, dimension):
			var i = y * dimension + x
			var point = Vector2(x * s_x + s_x / 2.0, y * s_y + s_y / 2.0)
			palette[i] = paletteImage.get_pixel(x * s_x + s_x / 2.0, y * s_y + s_y / 2.0)
	paletteImage.unlock()
	get_tree().call_group("preview", "on_texture_invalidated", "o%s_tex" % str(get_instance_id()))

func _post_process():
	var buffer = ImageTexture.new()
	buffer.create_from_image(texture.get_data())
	var converted = convert_image(buffer.get_data())
	texture.create_from_image(converted)
	var flags = Texture.FLAG_REPEAT | ImageTexture.STORAGE_COMPRESS_LOSSLESS
	texture.flags = flags


func convert_image(input:Image) -> Image:
	var output = Image.new()
	var format = Image.FORMAT_RGBA8 if output_type == OutputType.COLOR else Image.FORMAT_LA8
	input.convert(Image.FORMAT_RGBA8)
	output.create(input.get_width(), input.get_height(), false, format)
	input.lock()
	output.lock()

	for y in range(0, input.get_height()):
		for x in range(0, input.get_width()):
			var c_in = input.get_pixel(x, y)
			var result = convert_to_indexed_color(c_in)
			if output_type == OutputType.COLOR:
				var c : Color = result.color
				output.set_pixel(x,y, c)
				
			else:
				var c : Color = result.indexed
				output.set_pixel(x,y, c)
	input.unlock()
	output.unlock()
	return output

func convert_to_indexed_color(c:Color) -> Dictionary:
	var closest = Color()
	var indexed = Color()
	var closest_distance = 256 * 256 + 256 * 256 + 256 * 256
	var index = -1
	for i in range(0, palette.size()):
		var p = palette[i]
		var dr = c.r8 - p.r8
		var dg = c.g8 - p.g8
		var db = c.b8 - p.b8
		var distance = dr * dr + dg * dg + db * db
		if distance <= closest_distance:
			closest_distance = distance
			closest = Color(p.r, p.g, p.b, c.a)
			index = i
	indexed.r8 = index
	indexed.g8 = index
	indexed.b8 = index
	indexed.a = c.a
	return {"color" : closest, "indexed" : indexed }

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "palettize"
	data.version = VERSION_SIMPLE
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("version"):
		version = data.version
	else:
		version = VERSION_SIMPLE
