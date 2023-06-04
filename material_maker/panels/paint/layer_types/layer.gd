var name : String
var index : int
var hidden : bool
var layers : Array = []

const LAYER_NONE  : int = -1
const LAYER_PAINT : int = 0
const LAYER_PROC  : int = 1
const LAYER_MASK  : int = 2

func get_layer_type() -> int:
	return LAYER_NONE


func duplicate():
	var layer = get_script().new()
	print(layer.get_script().resource_path)
	layer.name = name+" (copy)"
	layer.hidden = false
	for c in get_channels():
		var texture = ImageTexture.new()
		texture.set_image(get(c).get_image())
		layer.set(c, texture)
	return layer


func get_channel_texture(channel_name : String) -> Texture2D:
	return get(channel_name)

func get_channels() -> Array:
	return []

func _load_layer(_data : Dictionary) -> void:
	pass

func load_layer(data : Dictionary, first_index : int, path : String) -> void:
	name = data.name
	if data.has("index"):
		index = data.index
	else:
		index = first_index
	hidden = data.hidden
	for c in get_channels():
		if data.has(c):
			var texture = ImageTexture.new()
			texture.load(path+"/"+data[c])
			set(c, texture)
	_load_layer(data)

func _save_layer(_data : Dictionary):
	pass

func save_layer(path : String) -> Dictionary:
	var layer_data = { name=name, type=get_layer_type(), index=index, hidden=hidden }
	for c in get_channels():
		if get(c) != null:
			var file_name : String = "%s_%d.png" % [ c, index ]
			var file_path : String = path.path_join(file_name)
			var image : Image = get(c).get_data()
			image.save_png(file_path)
			layer_data[c] = file_name
	_save_layer(layer_data)
	if !layers.is_empty():
		layer_data.layers = save_layers(layers, path)
	return layer_data

static func save_layers(layers_array : Array, path : String) -> Array:
	var layers_data = []
	for l in layers_array:
		var layer_data = l.save_layer(path)

		layers_data.push_back(layer_data)
	return layers_data

func set_state(s):
	print(s)
	for c in s.keys():
		if c in get_channels():
			set(c, s[c])
		else:
			print("Useless channel %s in layer state" % c)
