extends VBoxContainer

export(NodePath) var painter = null

var texture_size = 0

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

func _ready():
	tree.create_layer()
	nm_material.set_shader_param("tex", depth.get_texture())
	nm_material.set_shader_param("seams", painter_node.seams_viewport.get_texture())

func set_texture_size(s : float):
	if texture_size == s:
		return
	texture_size = s
	var selected = tree.get_selected()
	if selected != null:
		for c in [ "albedo", "mr", "emission", "depth" ]:
			var old_texture : Texture = selected.get_meta(c)
			var new_texture = ImageTexture.new()
			if old_texture != null:
				new_texture.create_from_image(old_texture.get_data())
			selected.set_meta(c, new_texture)
	tree.resize_layers(tree.get_root(), [ "albedo", "mr", "emission", "depth" ], s)
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
	painter_node.set_texture_size(s)
	if selected != null:
		for c in [ "albedo", "mr", "emission", "depth" ]:
			if selected != null:
				if selected.has_meta(c):
					painter_node.call("init_"+c+"_texture", Color(1.0, 1.0, 1.0, 1.0), selected.get_meta(c))
				else:
					painter_node.call("init_"+c+"_texture")
				selected.set_meta(c, painter_node.call("get_"+c+"_texture"))
	tree._on_layers_changed()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	_on_Painter_painted()

func get_albedo_texture():
	return albedo.get_texture()

func get_mr_texture():
	return mr.get_texture()

func get_emission_texture():
	return emission.get_texture()

func get_normal_map():
	return nm_viewport.get_texture()
	
func get_depth_texture():
	return depth.get_texture()

func _on_Tree_selection_changed(old_selected : TreeItem, new_selected : TreeItem):
	if painter_node == null:
		painter_node = get_node(painter)
	for c in [ "albedo", "mr", "emission", "depth" ]:
		if old_selected != null:
			var old_texture : Texture = old_selected.get_meta(c)
			var new_texture = ImageTexture.new()
			if old_texture != null:
				new_texture.create_from_image(old_texture.get_data())
			old_selected.set_meta(c, new_texture)
		if new_selected != null:
			if new_selected.has_meta(c):
				painter_node.call("init_"+c+"_texture", Color(1.0, 1.0, 1.0, 1.0), new_selected.get_meta(c))
			else:
				painter_node.call("init_"+c+"_texture")
			new_selected.set_meta(c, painter_node.call("get_"+c+"_texture"))

func _on_Tree_layers_changed(layers : Array):
	for viewport in [ albedo, metallic, roughness, emission, depth ]:
		while viewport.get_child_count() > 0:
			viewport.remove_child(viewport.get_child(0))
	for l in layers:
		var texture_rect : TextureRect
		texture_rect = TextureRect.new()
		texture_rect.texture = l.get_meta("albedo")
		texture_rect.rect_size = albedo.size
		albedo.add_child(texture_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.get_meta("mr")
		texture_rect.rect_size = mr.size
		texture_rect.material = preload("res://addons/material_spray/layers/metallic_layer.tres")
		metallic.add_child(texture_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.get_meta("mr")
		texture_rect.rect_size = mr.size
		texture_rect.material = preload("res://addons/material_spray/layers/roughness_layer.tres")
		roughness.add_child(texture_rect)
#		var color_rect : ColorRect = ColorRect.new()
#		color_rect.rect_size = mr.size
#		color_rect.material = preload("res://addons/material_spray/layers/mr_layer.tres").duplicate()
#		color_rect.material.set_shader_param("mr", l.get_meta("mr"))
#		mr.add_child(color_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.get_meta("albedo")
		texture_rect.modulate = Color(0.0, 0.0, 0.0)
		texture_rect.rect_size = emission.size
		emission.add_child(texture_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.get_meta("emission")
		texture_rect.rect_size = emission.size
		emission.add_child(texture_rect)
		texture_rect = TextureRect.new()
		texture_rect.texture = l.get_meta("depth")
		texture_rect.rect_size = depth.size
		depth.add_child(texture_rect)
	_on_Painter_painted()

func load(file_name):
	var dir_name = file_name.left(file_name.rfind("."))
	var file : File = File.new()
	if file.open(file_name, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		set_texture_size(data.texture_size)
		tree.load_layers(data, dir_name, [ "albedo", "mr", "emission", "depth" ])
		file.close()

func save(file_name):
	var dir_name = file_name.left(file_name.rfind("."))
	var dir = Directory.new()
	dir.make_dir(dir_name)
	var data = { texture_size=texture_size }
	tree.save_layers(data, tree.get_root(), 0, dir_name, [ "albedo", "mr", "emission", "depth" ])
	var file = File.new()
	if file.open(file_name, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()

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
