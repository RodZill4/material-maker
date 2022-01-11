extends Node


export(NodePath) var painter = null


var shaders = []

var texture_size = 0
var layers : Array = []
var selected_layer : Layer

onready var albedo = $Albedo
onready var metallic = $Metallic
onready var roughness = $Roughness
onready var emission = $Emission
onready var normal = $Normal
onready var normal_map = $NormalMap
onready var depth = $Depth
onready var occlusion = $Occlusion
onready var painter_node = get_node(painter) if painter != null else null

onready var nm_material : ShaderMaterial = $NormalMap/Rect.get_material()
var generate_nm : bool = true

onready var layers_pane = get_node("/root/MainWindow").layout.get_panel("Layers")

const Layer = preload("res://material_maker/panels/paint/layer_types/layer.gd")
const LayerPaint = preload("res://material_maker/panels/paint/layer_types/layer_paint.gd")
const LayerProcedural = preload("res://material_maker/panels/paint/layer_types/layer_procedural.gd")
const LayerMask = preload("res://material_maker/panels/paint/layer_types/layer_mask.gd")
const LAYER_TYPES : Array = [ LayerPaint, LayerProcedural, LayerMask ]

const CHANNELS : Array = [ "albedo", "metallic", "roughness", "emission", "normal", "depth", "occlusion" ]


signal layer_selected(l)


func _ready():
	pass

func set_texture_size(s : float):
	if texture_size == s:
		return
	texture_size = s
	var size = Vector2(s, s)
	var selected_layer_save = selected_layer
	var result = select_layer(null)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	resize_layers(s)
	for vp in [ albedo, metallic, roughness, emission, normal, depth, occlusion, normal_map ]:
		vp.size = size
		for c in vp.get_children():
			c.rect_size = size
	
	nm_material.set_shader_param("epsilon", 1/s)
	#nm_material.set_shader_param("depth_tex", depth.get_texture())
	#nm_material.set_shader_param("seams", painter_node.mesh_seams_tex)
	
	painter_node.set_texture_size(s)
	select_layer(selected_layer_save)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
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

func get_emission_texture():
	return emission.get_texture()

func get_normal_map():
	#return nm_viewport.get_texture()
	return normal_map.get_texture()

func get_depth_texture():
	return depth.get_texture()

func get_occlusion_texture():
	return occlusion.get_texture()

func _on_Tree_selection_changed(old_selected : TreeItem, new_selected : TreeItem) -> void:
	select_layer(new_selected.get_meta("layer"))

func select_layer(layer : Layer) -> void:
	if layer == selected_layer:
		return
	if painter_node == null:
		painter_node = get_node(painter)
	if selected_layer != null:
		for c in selected_layer.get_channels():
			var old_texture : Texture = selected_layer.get(c)
			var new_texture = ImageTexture.new()
			if old_texture != null:
				new_texture.create_from_image(old_texture.get_data())
			selected_layer.set(c, new_texture)
	if layer != null:
		for c in layer.get_channels():
			if layer.get(c) != null:
				painter_node.call("init_"+c+"_texture", Color(1.0, 1.0, 1.0, 1.0), layer.get(c))
			else:
				painter_node.call("init_"+c+"_texture")
			layer.set(c, painter_node.call("get_"+c+"_texture"))
		emit_signal("layer_selected", layer)
	selected_layer = layer
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
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

func add_layer(layer_type : int = 0) -> void:
	if layer_type < 0 or layer_type >= LAYER_TYPES.size():
		return
	var layers_array : Array = layers
	if layer_type == Layer.LAYER_MASK:
		if selected_layer == null:
			return
		elif selected_layer.get_layer_type() == Layer.LAYER_MASK:
			layers_array = find_parent_array(selected_layer)
		else:
			layers_array = selected_layer.layers
	var layer_class = LAYER_TYPES[layer_type]
	var layer = layer_class.new()
	layer.name = get_unused_layer_name(layers)
	layer.index = get_unused_layer_index()
	layer.hidden = false
	var image : Image = Image.new()
	image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for c in layer.get_channels():
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		layer.set(c, texture)
	layers_array.push_front(layer)
	select_layer(layer)

func duplicate_layer(source_layer : Layer) -> void:
	var layers_array : Array = find_parent_array(source_layer)
	var layer = source_layer.duplicate()
	layers_array.push_front(layer)
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
	assert(layer != null)
	if layer.get_layer_type() == Layer.LAYER_MASK and (target_layer == null or target_layer.get_layer_type() == Layer.LAYER_MASK):
		return
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

func update_alpha(channel : String) -> void:
	for l in layers:
		if l.has_method("update_color_rects"):
			l.update_color_rects(channel)

func _on_layers_changed() -> void:
	var list = []
	get_visible_layers(list)
	update_layers_renderer(list)
	for c in CHANNELS:
		update_alpha(c)
	layers_pane.call_deferred("set_layers", self)

func get_visible_layers(list : Array, layers_array : Array = layers, mask_array : Array = []) -> void:
	for i in range(layers_array.size()-1, -1, -1):
		var l = layers_array[i]
		if l.hidden or l.get_layer_type() == Layer.LAYER_MASK:
			continue
		var m = mask_array.duplicate()
		for cl in l.layers:
			if !cl.hidden and cl.get_layer_type() == Layer.LAYER_MASK:
				m.push_back(cl.mask)
		get_visible_layers(list, l.layers, m)
		list.push_back({ layer=l, masks=m })

func get_shaders(mask_count : int) -> Dictionary:
	while shaders.size() <= mask_count:
		var mc = shaders.size()
		var albedo_shader : Shader = Shader.new()
		var metallic_shader : Shader = Shader.new()
		var roughness_shader : Shader = Shader.new()
		var albedomask_shader : Shader = Shader.new()
		var shader_prefix = "shader_type canvas_item;\nrender_mode blend_mix;\nuniform sampler2D input_tex : hint_albedo;\nuniform float modulate = 1.0;\n"
		var shader_modulate = "modulate"
		for i in mc:
			shader_prefix += "uniform sampler2D mask%d_tex : hint_albedo;\n" % i;
			shader_modulate += "*texture(mask%d_tex, UV).r" % i;
		shader_prefix += "void fragment() {\n	vec4 tex = texture(input_tex, UV);\n"
		albedo_shader.code = shader_prefix+"	COLOR=vec4(tex.rgb, tex.a*"+shader_modulate+");\n}"
		metallic_shader.code = shader_prefix+"	COLOR=vec4(tex.r, tex.r, tex.r, tex.b*"+shader_modulate+");\n}"
		roughness_shader.code = shader_prefix+"	COLOR=vec4(tex.g, tex.g, tex.g, tex.a*"+shader_modulate+");\n}"
		albedomask_shader.code = shader_prefix+"	COLOR=vec4(0.0, 0.0, 0.0, tex.a*"+shader_modulate+");\n}"
		shaders.push_back( { albedo=albedo_shader, metallic=metallic_shader, roughness=roughness_shader, albedomask=albedomask_shader } )
	return shaders[mask_count]

func apply_masks(material : ShaderMaterial, masks : Array) -> void:
	for i in range(masks.size()):
		material.set_shader_param("mask%d_tex" % i, masks[i])

func update_layers_renderer(visible_layers : Array) -> void:
	for viewport in [ albedo, metallic, roughness, emission, normal, depth, occlusion ]:
		while viewport.get_child_count() > 0:
			viewport.remove_child(viewport.get_child(0))
	var texture_rect : TextureRect
	var color_rect : ColorRect
	color_rect = ColorRect.new()
	color_rect.rect_size = normal.size
	color_rect.color = Color(0.5, 0.5, 0)
	normal.add_child(color_rect)
	color_rect = ColorRect.new()
	color_rect.rect_size = normal.size
	color_rect.color = Color(1.0, 1.0, 1.0)
	occlusion.add_child(color_rect)
	for lm in visible_layers:
		var l = lm.layer
		var m = lm.masks
		var layer_shaders = get_shaders(m.size())
		# albedo
		color_rect = ColorRect.new()
		color_rect.rect_size = albedo.size
		color_rect.material = ShaderMaterial.new()
		color_rect.material.shader = layer_shaders.albedo
		color_rect.material.set_shader_param("input_tex", l.albedo)
		color_rect.material.set_shader_param("modulate", l.albedo_alpha)
		apply_masks(color_rect.material, m)
		l.albedo_color_rects = [ color_rect ]
		albedo.add_child(color_rect)
		# metallic
		color_rect = ColorRect.new()
		color_rect.rect_size = metallic.size
		color_rect.material = ShaderMaterial.new()
		color_rect.material.shader = layer_shaders.metallic
		color_rect.material.set_shader_param("input_tex", l.mr)
		color_rect.material.set_shader_param("modulate", l.metallic_alpha)
		apply_masks(color_rect.material, m)
		l.metallic_color_rects = [ color_rect ]
		metallic.add_child(color_rect)
		# roughness
		color_rect = ColorRect.new()
		color_rect.rect_size = roughness.size
		color_rect.material = ShaderMaterial.new()
		color_rect.material.shader = layer_shaders.roughness
		color_rect.material.set_shader_param("input_tex", l.mr)
		color_rect.material.set_shader_param("modulate", l.roughness_alpha)
		apply_masks(color_rect.material, m)
		l.roughness_color_rects = [ color_rect ]
		roughness.add_child(color_rect)
		# emission
		color_rect = ColorRect.new()
		color_rect.rect_size = emission.size
		color_rect.material = ShaderMaterial.new()
		color_rect.material.shader = layer_shaders.albedomask
		color_rect.material.set_shader_param("input_tex", l.albedo)
		color_rect.material.set_shader_param("modulate", l.albedo_alpha)
		apply_masks(color_rect.material, m)
		l.albedo_color_rects.push_back(color_rect)
		emission.add_child(color_rect)
		color_rect = ColorRect.new()
		color_rect.rect_size = emission.size
		color_rect.material = ShaderMaterial.new()
		color_rect.material.shader = layer_shaders.albedo
		color_rect.material.set_shader_param("input_tex", l.emission)
		color_rect.material.set_shader_param("modulate", l.emission_alpha)
		apply_masks(color_rect.material, m)
		l.emission_color_rects = [ color_rect ]
		emission.add_child(color_rect)
		# normal
		color_rect = ColorRect.new()
		color_rect.rect_size = normal.size
		color_rect.material = ShaderMaterial.new()
		color_rect.material.shader = layer_shaders.albedo
		color_rect.material.set_shader_param("input_tex", l.normal)
		color_rect.material.set_shader_param("modulate", l.normal_alpha)
		apply_masks(color_rect.material, m)
		l.normal_color_rects = [ color_rect ]
		normal.add_child(color_rect)
		# depth
		color_rect = ColorRect.new()
		color_rect.rect_size = depth.size
		color_rect.material = ShaderMaterial.new()
		color_rect.material.shader = layer_shaders.metallic
		color_rect.material.set_shader_param("input_tex", l.do)
		color_rect.material.set_shader_param("modulate", l.depth_alpha)
		apply_masks(color_rect.material, m)
		l.depth_color_rects = [ color_rect ]
		depth.add_child(color_rect)
		# occlusion
		color_rect = ColorRect.new()
		color_rect.rect_size = occlusion.size
		color_rect.material = ShaderMaterial.new()
		color_rect.material.shader = layer_shaders.roughness
		color_rect.material.set_shader_param("input_tex", l.do)
		color_rect.material.set_shader_param("modulate", l.occlusion_alpha)
		apply_masks(color_rect.material, m)
		l.occlusion_color_rects = [ color_rect ]
		occlusion.add_child(color_rect)
	_on_Painter_painted()

func set_normal_options(paint_normal, paint_depth_as_bump, bump_strength):
	if paint_normal:
		generate_nm = true
		if paint_depth_as_bump:
			nm_material.set_shader_param("bump_strength", bump_strength)
		else:
			nm_material.set_shader_param("bump_strength", 0.0)
	elif paint_depth_as_bump:
		generate_nm = true
		nm_material.set_shader_param("bump_strength", 1.0)
	else:
		generate_nm = false
	_on_Painter_painted()

func load(data : Dictionary, file_name : String):
	var dir_name = file_name.left(file_name.rfind("."))
	layers.clear()
	load_layers(data.layers, layers, dir_name)
	if !layers.empty():
		select_layer(layers[0])
	_on_layers_changed()

func load_layers(data_layers : Array, layers_array : Array, path : String, first_index : int = 0) -> int:
	for l in data_layers:
		var layer : Layer = LAYER_TYPES[l.type if l.has("type") else 0].new()
		layer.load_layer(l, first_index, path)
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
		for c in CHANNELS:
			layer.set(c+"_alpha", l[c+"_alpha"] if l.has(c+"_alpha") else 1.0)
		if l.has("layers"):
			first_index = load_layers(l.layers, layer.layers, path, first_index)
		layers_array.push_back(layer)
	return first_index

func save(file_name : String) -> Dictionary:
	var dir_name = file_name.left(file_name.rfind("."))
	var dir = Directory.new()
	dir.make_dir(dir_name)
	var data = {}
	data.layers = Layer.save_layers(layers, dir_name)
	return data

func _on_Painter_painted():
	for viewport in [ albedo, metallic, roughness, emission, normal, depth, occlusion ]:
		viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		viewport.update_worlds()
	if generate_nm:
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		normal_map.render_target_update_mode = Viewport.UPDATE_ONCE
		normal_map.update_worlds()

# debug

func debug_get_texture_names():
	return [ "Albedo", "Metallic", "Roughness", "Emission", "Normal map", "Depth", "Occlusion" ]

# Localization strings
# tr("Albedo")
# tr("Metallic")
# tr("Roughness")
# tr("Emission")
# tr("Normal map")
# tr("Depth")
# tr("Occlusion")

func debug_get_texture(ID):
	match ID:
		0:
			return get_albedo_texture()
		1:
			return $Metallic.get_texture()
		2:
			return $Roughness.get_texture()
		3:
			return get_emission_texture()
		4:
			return get_normal_map()
		5:
			return get_depth_texture()
		6:
			return get_occlusion_texture()
