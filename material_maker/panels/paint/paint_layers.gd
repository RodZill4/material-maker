extends Node

class Layer:
	var name : String
	var index : int
	var hidden : bool
	var albedo : Texture
	var mr : Texture
	var emission : Texture
	var depth : Texture
	var layers : Array = []
	
	var albedo_alpha : float = 1.0
	var metallic_alpha : float = 1.0
	var roughness_alpha : float = 1.0
	var emission_alpha : float = 1.0
	var depth_alpha : float = 1.0
	
	func set_alpha(channel : String, value : float) -> void:
		set(channel+"_alpha", value)
		var layers
		for cr in get(channel+"_color_rects"):
			cr.modulate.a = value
			layers = cr.get_parent().get_parent()
		layers._on_Painter_painted()
	
	var albedo_color_rects : Array = []
	var metallic_color_rects : Array = []
	var roughness_color_rects : Array = []
	var emission_color_rects : Array = []
	var depth_color_rects : Array = []

export(NodePath) var painter = null

var texture_size = 0
var layers : Array = []
var selected_layer : Layer

onready var tree = $Tree
onready var albedo = $Albedo
onready var metallic = $Metallic
onready var roughness = $Roughness
onready var mr = $MR
onready var emission = $Emission
onready var depth = $Depth
onready var painter_node = get_node(painter) if painter != null else null

onready var nm_viewport = $NormalMap
onready var nm_rect = $NormalMap/Rect
onready var nm_material = $NormalMap/Rect.get_material()

onready var layers_pane = get_node("/root/MainWindow").layout.get_panel("Layers")

const CHANNELS : Array = [ "albedo", "mr", "emission", "depth" ]

func _ready():
	pass

func set_texture_size(s : float):
	if texture_size == s:
		return
	texture_size = s
	var selected_layer_save = selected_layer
	select_layer(null)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	resize_layers(s)
	albedo.size = Vector2(s, s)
	metallic.size = Vector2(s, s)
	roughness.size = Vector2(s, s)
	mr.size = Vector2(s, s)
	$MR/Metallic.texture = metallic.get_texture()
	$MR/Roughness.texture = roughness.get_texture()
	emission.size = Vector2(s, s)
	depth.size = Vector2(s, s)
	nm_viewport.size = Vector2(s, s)
	nm_rect.rect_size = Vector2(s, s)
	nm_material.set_shader_param("epsilon", 1/s)
	nm_material.set_shader_param("tex", depth.get_texture())
	nm_material.set_shader_param("seams", painter_node.seams_viewport.get_texture())
	painter_node.set_texture_size(s)
	select_layer(selected_layer_save)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	_on_Painter_painted()

func find_parent_array(layer : Layer, layer_array : Array = layers):
	for l in layer_array:
		if l == layer:
			return layer_array
		var rv = find_parent_array(layer, l.layers)
		if rv != null:
			return rv
	return null

func resize_layers(size : int, layers_array : Array = layers):
	for l in layers_array:
		for c in CHANNELS:
			if l.get(c) != null:
				var texture : ImageTexture = l.get(c)
				var image : Image = Image.new()
				image.copy_from(texture.get_data())
				image.resize(size, size)
				texture.create_from_image(image)
		resize_layers(size, l.layers)

func get_albedo_texture():
	return albedo.get_texture()

func get_metallic_texture():
	return metallic.get_texture()

func get_roughness_texture():
	return roughness.get_texture()

func get_mr_texture():
	return mr.get_texture()

func get_emission_texture():
	return emission.get_texture()

func get_normal_map():
	return nm_viewport.get_texture()
	
func get_depth_texture():
	return depth.get_texture()

func _on_Tree_selection_changed(old_selected : TreeItem, new_selected : TreeItem) -> void:
	select_layer(new_selected.get_meta("layer"))

func select_layer(layer : Layer) -> void:
	if layer == selected_layer:
		return
	if painter_node == null:
		painter_node = get_node(painter)
	for c in CHANNELS:
		if selected_layer != null:
			var old_texture : Texture = selected_layer.get(c)
			var new_texture = ImageTexture.new()
			if old_texture != null:
				new_texture.create_from_image(old_texture.get_data())
			selected_layer.set(c, new_texture)
		if layer != null:
			if layer.get(c) != null:
				painter_node.call("init_"+c+"_texture", Color(1.0, 1.0, 1.0, 1.0), layer.get(c))
			else:
				painter_node.call("init_"+c+"_texture")
			layer.set(c, painter_node.call("get_"+c+"_texture"))
	selected_layer = layer
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	_on_layers_changed()

func get_unused_layer_name(layers_array : Array) -> String:
	return "New layer"

func layer_index_is_used(index : int, layers_array : Array) -> bool:
	for l in layers_array:
		if l.index == index or layer_index_is_used(index, l.layers):
			return true
	return false

func get_unused_layer_index() -> int:
	var index : int = 0
	while layer_index_is_used(index, layers):
		index += 1
	return index

func add_layer() -> void:
	var layer = Layer.new()
	layer.name = get_unused_layer_name(layers)
	layer.index = get_unused_layer_index()
	layer.hidden = false
	var image : Image = Image.new()
	image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for c in CHANNELS:
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		layer.set(c, texture)
	layers.push_front(layer)
	select_layer(layer)

func duplicate_layer(source_layer : Layer) -> void:
	var layer = Layer.new()
	layer.name = source_layer.name+" (copy)"
	layer.index = get_unused_layer_index()
	layer.hidden = false
	for c in CHANNELS:
		var texture = ImageTexture.new()
		texture.create_from_image(source_layer.get(c).get_data())
		layer.set(c, texture)
	layers.push_front(layer)
	select_layer(layer)

func remove_layer(layer : Layer) -> void:
	var need_reselect : bool = (layer == selected_layer)
	var layers_array : Array = find_parent_array(layer)
	layers_array.erase(layer)
	if need_reselect:
		selected_layer = null
		if !layers.empty():
			select_layer(layers[0])
			return
	_on_layers_changed()

func move_layer_into(layer : Layer, target_layer : Layer, index : int = -1) -> void:
	var array : Array = find_parent_array(layer)
	var orig_index = array.find(layer)
	array.erase(layer)
	var target_array = target_layer.layers if target_layer != null else layers
	if index == -1:
		index = target_array.size()
	elif array == target_array and index > orig_index:
		index -= 1
	target_array.insert(index, layer)
	_on_layers_changed()

func move_layer_up(layer : Layer) -> void:
	var array : Array = find_parent_array(layer)
	var orig_index = array.find(layer)
	if orig_index > 0:
		array.erase(layer)
		array.insert(orig_index-1, layer)
		_on_layers_changed()

func move_layer_down(layer : Layer) -> void:
	var array : Array = find_parent_array(layer)
	var orig_index = array.find(layer)
	if orig_index < array.size()-1:
		array.erase(layer)
		array.insert(orig_index+1, layer)
		_on_layers_changed()

func _on_layers_changed() -> void:
	var list = []
	get_visible_layers(list)
	update_layers_renderer(list)
	layers_pane.call_deferred("set_layers", self)

func get_visible_layers(list : Array, layers_array : Array = layers) -> void:
	for i in range(layers_array.size()-1, -1, -1):
		var l = layers_array[i]
		if l.hidden:
			continue
		get_visible_layers(list, l.layers)
		list.push_back(l)

func update_layers_renderer(visible_layers : Array) -> void:
	for viewport in [ albedo, metallic, roughness, emission, depth ]:
		while viewport.get_child_count() > 0:
			viewport.remove_child(viewport.get_child(0))
	for l in visible_layers:
		var texture_rect : TextureRect
		texture_rect = TextureRect.new()
		texture_rect.texture = l.albedo
		texture_rect.modulate = Color(1.0, 1.0, 1.0, l.albedo_alpha)
		texture_rect.rect_size = albedo.size
		l.albedo_color_rects = [ texture_rect ]
		albedo.add_child(texture_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.mr
		texture_rect.modulate = Color(1.0, 1.0, 1.0, l.metallic_alpha)
		texture_rect.rect_size = mr.size
		texture_rect.material = preload("res://material_maker/panels/paint/shaders/metallic_layer.tres")
		l.metallic_color_rects = [ texture_rect ]
		metallic.add_child(texture_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.mr
		texture_rect.modulate = Color(1.0, 1.0, 1.0, l.roughness_alpha)
		texture_rect.rect_size = mr.size
		texture_rect.material = preload("res://material_maker/panels/paint/shaders/roughness_layer.tres")
		l.roughness_color_rects = [ texture_rect ]
		roughness.add_child(texture_rect)
#		var color_rect : ColorRect = ColorRect.new()
#		color_rect.rect_size = mr.size
#		color_rect.material = preload("res://material_maker/panels/paint/shaders/mr_layer.tres").duplicate()
#		color_rect.material.set_shader_param("mr", l.mr"))
#		mr.add_child(color_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.albedo
		texture_rect.modulate = Color(0.0, 0.0, 0.0, l.albedo_alpha)
		texture_rect.rect_size = emission.size
		l.albedo_color_rects.push_back(texture_rect)
		emission.add_child(texture_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.emission
		texture_rect.modulate = Color(1.0, 1.0, 1.0, l.emission_alpha)
		texture_rect.rect_size = emission.size
		l.emission_color_rects.push_back(texture_rect)
		emission.add_child(texture_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.depth
		texture_rect.modulate = Color(1.0, 1.0, 1.0, l.depth_alpha)
		texture_rect.rect_size = depth.size
		l.depth_color_rects.push_back(texture_rect)
		depth.add_child(texture_rect)
	_on_Painter_painted()

func load(data : Dictionary, file_name : String):
	var dir_name = file_name.left(file_name.rfind("."))
	layers.clear()
	load_layers(data.layers, layers, dir_name)
	_on_layers_changed()

func load_layers(data_layers : Array, layers_array : Array, path : String, first_index : int = 0) -> int:
	for l in data_layers:
		var layer : Layer = Layer.new()
		layer.name = l.name
		if l.has("index"):
			layer.index = l.index
		else:
			layer.index = first_index
			first_index += 1
		layer.hidden = l.hidden
		for c in CHANNELS:
			if l.has(c):
				var texture = ImageTexture.new()
				texture.load(path+"/"+l[c])
				layer.set(c, texture)
		for c in [ "albedo", "metallic", "roughness", "emission", "depth" ]:
			layer.set(c+"_alpha", l[c+"_alpha"] if l.has(c+"_alpha") else 1.0)
		if l.has("layers"):
			first_index = load_layers(l.layers, layer.layers, path, first_index)
		layers_array.push_back(layer)
	return first_index

func save(file_name : String) -> Dictionary:
	var dir_name = file_name.left(file_name.rfind("."))
	var dir = Directory.new()
	dir.make_dir(dir_name)
	var data = { texture_size=texture_size }
	#tree.save_layers(data, tree.get_root(), 0, dir_name, [ "albedo", "mr", "emission", "depth" ])
	data.layers = save_layers(layers, dir_name)
	return data

func save_layers(layers_array : Array, path : String) -> Array:
	var layers_data = []
	for l in layers_array:
		var layer_data = { name=l.name, index=l.index, hidden=l.hidden }
		for c in CHANNELS:
			if l.get(c) != null:
				var file_name : String = "%s_%d.png" % [ c, l.index ]
				var file_path : String = path.plus_file(file_name)
				var image : Image = l.get(c).get_data()
				image.lock()
				image.save_png(file_path)
				image.unlock()
				layer_data[c] = file_name
		for c in [ "albedo", "metallic", "roughness", "emission", "depth" ]:
			layer_data[c+"_alpha"] = l.get(c+"_alpha")
		if !l.layers.empty():
			layer_data.layers = save_layers(l.layers, path)
		layers_data.push_back(layer_data)
	return layers_data

func _on_Painter_painted():
	for viewport in [ albedo, metallic, roughness, emission, depth ]:
		viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	mr.render_target_update_mode = Viewport.UPDATE_ONCE
	mr.update_worlds()
	nm_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	nm_viewport.update_worlds()

# debug

func debug_get_texture_names():
	return [ "Albedo", "Metallic", "Roughness", "Metallic/Roughness", "Emission", "Normal map", "Depth" ]

func debug_get_texture(ID):
	if ID == 0:
		return get_albedo_texture()
	if ID == 1:
		return $Metallic.get_texture()
	if ID == 2:
		return $Roughness.get_texture()
	elif ID == 3:
		return get_mr_texture()
	elif ID == 4:
		return get_emission_texture()
	elif ID == 5:
		return get_normal_map()
	elif ID == 6:
		return get_depth_texture()
