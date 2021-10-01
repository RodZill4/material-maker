extends Node

onready var view_to_texture_viewport = $View2Texture
onready var view_to_texture_mesh = $View2Texture/PaintedMesh
onready var view_to_texture_camera = $View2Texture/Camera

onready var texture_to_view_viewport = $Texture2View
onready var texture_to_view_mesh = $Texture2View/PaintedMesh

onready var mesh_seams_tex : ImageTexture = ImageTexture.new()

onready var albedo_viewport = $AlbedoPaint
onready var mr_viewport = $MRPaint
onready var emission_viewport = $EmissionPaint
onready var normal_viewport = $NormalPaint
onready var do_viewport = $DOPaint
onready var mask_viewport = $MaskPaint
onready var viewports = [ albedo_viewport, mr_viewport, emission_viewport, normal_viewport, do_viewport, mask_viewport ]

var camera
var transform
var viewport_size

var brush_node = null
var brush_params = {
	brush_size = Vector2(1.0, 1.0),
	brush_hardness = 0.5,
	pattern_scale  = 10.0,
	pattern_angle  = 0.0
}

var has_albedo   : bool = false
var has_mr       : bool = false
var has_emission : bool = false
var has_normal   : bool = false
var has_do       : bool = false
var has_mask     : bool = false

var brush_preview_material : ShaderMaterial
var pattern_shown : bool = false
var brush_textures : Dictionary = {}

var mesh_aabb : AABB
var mesh_inv_uv_tex : ImageTexture = null
var mesh_normal_tex : ImageTexture = null

const VIEW_TO_TEXTURE_RATIO = 2.0

signal colors_picked(brush)
signal painted()

func _ready():
	var v2t_tex = view_to_texture_viewport.get_texture()
	var t2v_tex = texture_to_view_viewport.get_texture()
	# shader debug
	# add View2Texture as input of Texture2View (to ignore non-visible parts of the mesh)
	texture_to_view_mesh.get_surface_material(0).set_shader_param("view2texture", v2t_tex)
	# Add Texture2ViewWithoutSeams as input to all painted textures
	for index in range(viewports.size()):
		viewports[index].set_intermediate_textures(t2v_tex, mesh_seams_tex)

func update_seams_texture():
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	texture_to_view_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var map_renderer = load("res://material_maker/tools/map_renderer/map_renderer.tscn").instance()
	add_child(map_renderer)
	var result = map_renderer.gen(texture_to_view_mesh.mesh, "seams", "copy_to_texture", [ mesh_seams_tex ], texture_to_view_viewport.size.x)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	map_renderer.queue_free()

func update_inv_uv_texture(m : Mesh) -> void:
	var map_renderer = load("res://material_maker/tools/map_renderer/map_renderer.tscn").instance()
	add_child(map_renderer)
	if mesh_inv_uv_tex == null:
		mesh_inv_uv_tex = ImageTexture.new()
	var result = map_renderer.gen(m, "inv_uv", "copy_to_texture", [ mesh_inv_uv_tex ], texture_to_view_viewport.size.x)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	if mesh_normal_tex == null:
		mesh_normal_tex = ImageTexture.new()
	result = map_renderer.gen(m, "mesh_normal", "copy_to_texture", [ mesh_normal_tex ], texture_to_view_viewport.size.x)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	map_renderer.queue_free()
	mesh_aabb = m.get_aabb()

func set_mesh(m : Mesh):
	var mat : Material
	mat = texture_to_view_mesh.get_surface_material(0)
	texture_to_view_mesh.mesh = m
	texture_to_view_mesh.set_surface_material(0, mat)
	mat = view_to_texture_mesh.get_surface_material(0)
	view_to_texture_mesh.mesh = m
	view_to_texture_mesh.set_surface_material(0, mat)
	var result = update_seams_texture()
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	result = update_inv_uv_texture(m)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")

func calculate_mask(value : float, channel : int) -> Color:
	if (channel == SpatialMaterial.TEXTURE_CHANNEL_RED):
		return Color(value, 0, 0, 0)
	elif (channel == SpatialMaterial.TEXTURE_CHANNEL_GREEN):
		return Color(0, value, 0, 0)
	elif (channel == SpatialMaterial.TEXTURE_CHANNEL_BLUE):
		return Color(0, 0, value, 0)
	elif (channel == SpatialMaterial.TEXTURE_CHANNEL_ALPHA):
		return Color(0, 0, 0, value)
	return Color(0, 0, 0, 0)


func init_albedo_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture = null):
	albedo_viewport.init(color, texture)

func init_mr_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture = null):
	mr_viewport.init(color, texture)

func init_mr_texture_channels(metallic : float = 1.0, metallic_texture : Texture = null, metallic_channel : int = SpatialMaterial.TEXTURE_CHANNEL_RED, roughness : float = 1.0, roughness_texture : Texture = null, roughness_channel : int = SpatialMaterial.TEXTURE_CHANNEL_GREEN):
	mr_viewport.init_channels(metallic_texture, calculate_mask(metallic, metallic_channel), roughness_texture, calculate_mask(roughness, roughness_channel), null, Color(1.0, 0.0, 0.0, 0.0), null, Color(1.0, 0.0, 0.0, 0.0))

func init_emission_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture = null):
	emission_viewport.init(color, texture)

func init_normal_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture = null):
	normal_viewport.init(color, texture)

func init_do_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture = null):
	do_viewport.init(color, texture)

func init_do_texture_channels(depth : float = 1.0, depth_texture : Texture = null, occlusion : float = 1.0, occlusion_texture : Texture = null, occlusion_channel : int = SpatialMaterial.TEXTURE_CHANNEL_GREEN):
	do_viewport.init_channels(depth_texture, calculate_mask(depth, SpatialMaterial.TEXTURE_CHANNEL_RED), occlusion_texture, calculate_mask(occlusion, occlusion_channel), null, Color(1.0, 0.0, 0.0, 0.0), null, Color(1.0, 0.0, 0.0, 0.0))

func init_mask_texture(color : Color = Color(0.0, 0.0, 0.0, 1.0), texture : Texture = null):
	mask_viewport.init(color, texture)

func init_textures(m : SpatialMaterial):
	init_mask_texture()
	init_albedo_texture(m.albedo_color, m.albedo_texture)
	init_mr_texture_channels(m.metallic, m.metallic_texture, m.metallic_texture_channel, m.roughness, m.roughness_texture, m.roughness_texture_channel)
	if m.emission_enabled:
		var emission_color = m.emission
		emission_color.a = 1.0
		init_emission_texture(emission_color, m.emission_texture)
	else:
		init_emission_texture(Color(0.0, 0.0, 0.0), null)
	if m.normal_enabled:
		init_normal_texture(Color(1.0, 1.0, 1.0), m.n_texture)
	else:
		init_normal_texture(Color(0.5, 0.5, 0.0), null)
	if m.depth_enabled or m.ao_enabled:
		init_do_texture_channels(m.depth_scale if m.depth_enabled else 0.0, m.depth_texture, m.ao_light_affect if m.ao_enabled else 1.0, m.ao_texture, m.ao_texture_channel)
	else:
		init_do_texture(Color(0.0, 1.0, 0.0, 0.0), null)

func set_texture_size(s : float):
	if texture_to_view_viewport.size.x != s:
		texture_to_view_viewport.size = Vector2(s, s)
		for index in range(viewports.size()):
			viewports[index].set_texture_size(s)
		update_seams_texture()

func update_view(c, t, s):
	camera = c
	transform = t
	viewport_size = s
	update_tex2view()
	update_brush()

func update_tex2view():
	if viewport_size.y <= 0:
		return
	var aspect = viewport_size.x/viewport_size.y
	view_to_texture_viewport.size = VIEW_TO_TEXTURE_RATIO*viewport_size
	view_to_texture_camera.transform = camera.global_transform
	view_to_texture_camera.fov = camera.fov
	view_to_texture_camera.near = camera.near
	view_to_texture_camera.far = camera.far
	view_to_texture_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	view_to_texture_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var material = texture_to_view_mesh.get_surface_material(0)
	if true:
		var shader_file = File.new()
		shader_file.open("res://material_maker/tools/painter/shaders/texture2view.shader", File.READ)
		material.shader.code = shader_file.get_as_text()
	material.set_shader_param("model_transform", transform)
	material.set_shader_param("fovy_degrees", camera.fov)
	material.set_shader_param("z_near", camera.near)
	material.set_shader_param("z_far", camera.far)
	material.set_shader_param("aspect", aspect)
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	texture_to_view_viewport.update_worlds()

# Brush methods

func get_brush_mode() -> String:
	return brush_node.get_parameter_defs()[0].values[brush_node.get_parameter("mode")].value

func set_brush_node(node) -> void:
	brush_node = node
	update_brush(true)

func set_brush_preview_material(m : ShaderMaterial) -> void:
	brush_preview_material = m

func get_brush_preview_shader(mode : String) -> String:
	var file = File.new()
	file.open("res://material_maker/tools/painter/shaders/brush_%s.shader" % mode, File.READ)
	return file.get_as_text()

func set_brush_angle(a) -> void:
	brush_params.pattern_angle = a
	update_brush()

func show_pattern(b):
	if pattern_shown != b:
		pattern_shown = b
		update_brush()

func update_brush(update_shaders = false):
	#if brush_params.albedo_texture_mode != 2: $Pattern.visible = false
	if brush_preview_material != null:
		if update_shaders:
			var code : String = get_output_code(1)
			update_shader(brush_preview_material, get_brush_preview_shader(get_brush_mode()), code)
		var v2t_tex = view_to_texture_viewport.get_texture()
		brush_preview_material.set_shader_param("view2tex_tex", v2t_tex)
		brush_preview_material.set_shader_param("mesh_inv_uv_tex", mesh_inv_uv_tex)
		brush_preview_material.set_shader_param("mesh_aabb_position", mesh_aabb.position)
		brush_preview_material.set_shader_param("mesh_aabb_size", mesh_aabb.size)
		brush_preview_material.set_shader_param("mesh_normal_tex", mesh_normal_tex)
		brush_preview_material.set_shader_param("layer_albedo_tex", get_albedo_texture())
		brush_preview_material.set_shader_param("layer_mr_tex", get_mr_texture())
		brush_preview_material.set_shader_param("layer_emission_tex", get_emission_texture())
		brush_preview_material.set_shader_param("layer_normal_tex", get_normal_texture())
		brush_preview_material.set_shader_param("layer_do_tex", get_do_texture())
		for p in brush_params.keys():
			brush_preview_material.set_shader_param(p, brush_params[p])
		brush_preview_material.set_shader_param("pattern_alpha", 0.5 if pattern_shown else 0.0)
	if brush_node == null:
		return
	# Mode
	var mode : String = get_brush_mode()
	has_albedo = brush_node.get_parameter("has_albedo")
	has_mr = brush_node.get_parameter("has_metallic") or brush_node.get_parameter("has_roughness")
	has_emission = brush_node.get_parameter("has_emission")
	has_normal = brush_node.get_parameter("has_normal")
	has_do = brush_node.get_parameter("has_depth") or brush_node.get_parameter("has_ao")
	has_mask = true #brush_node.get_parameter("has_mask")
	# Update shaders
	if update_shaders:
		for index in range(viewports.size()):
			update_shader(viewports[index].get_paint_material(), viewports[index].get_paint_shader(mode), get_output_code(index+1))
			viewports[index].set_mesh_textures(mesh_aabb, mesh_inv_uv_tex, mesh_normal_tex)
			viewports[index].set_layer_textures( { albedo=get_albedo_texture(), mr=get_mr_texture(), emission=get_emission_texture(), normal=get_normal_texture(), do=get_do_texture(), mask=get_mask_texture()} )
	for index in range(viewports.size()):
		viewports[index].set_brush(brush_params)

func get_output_code(index : int) -> String:
	if brush_node == null or !is_instance_valid(brush_node):
		brush_node = null
		return ""
	var context : MMGenContext = MMGenContext.new()
	var source_mask = brush_node.get_shader_code("uv", 0, context)
	context = MMGenContext.new(context)
	var source = brush_node.get_shader_code("uv", index, context)
	var new_code : String = mm_renderer.common_shader
	new_code += "\n"
	for g in source.globals:
		if source_mask.globals.find(g) == -1:
			source_mask.globals.append(g)
	for g in source_mask.globals:
		new_code += g
	for t in source.textures.keys():
		if !source_mask.textures.has(t):
			source_mask.textures[t] = source.textures[t]
	brush_textures = source_mask.textures
	new_code += source_mask.defs+"\n"
	new_code += "\nfloat brush_function(vec2 uv) {\n"
	new_code += "float _seed_variation_ = 0.0;\n"
	new_code += source_mask.code+"\n"
	new_code += "vec2 __brush_box = abs(uv-vec2(0.5));\n"
	new_code += "return (max(__brush_box.x, __brush_box.y) < 0.5) ? "+source_mask.f+" : 0.0;\n"
	new_code += "}\n"
	new_code += source.defs+"\n"
	new_code += "\nvec4 pattern_function(vec2 uv) {\n"
	new_code += "float _seed_variation_ = 0.0;\n"
	new_code += source.code+"\n"
	new_code += "return "+source.rgba+";\n"
	new_code += "}\n"
	return new_code

func update_shader(shader_material : ShaderMaterial, shader_template : String, shader_code : String) -> void:
	if shader_material == null:
		print("no shader material")
		return
	var new_code = shader_template.left(shader_template.find("// BEGIN_PATTERN"))+"// BEGIN_PATTERN\n"+shader_code+shader_template.right(shader_template.find("// END_PATTERN"))
	shader_material.shader.code = new_code
	# Get parameter values from the shader code
	MMGenBase.define_shader_float_parameters(shader_material.shader.code, shader_material)
	for t in brush_textures.keys():
		shader_material.set_shader_param(t, brush_textures[t])

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	for index in range(viewports.size()):
		mm_renderer.update_float_parameters(viewports[index].paint_material, parameter_changes)
	mm_renderer.update_float_parameters(brush_preview_material, parameter_changes)

func update_brush_params(shader_params : Dictionary) -> void:
	for p in shader_params.keys():
		if p == "brush_size":
			brush_params[p] = Vector2(shader_params.brush_size, shader_params.brush_size)/viewport_size
		else:
			brush_params[p] = shader_params[p]
		if brush_preview_material != null:
			brush_preview_material.set_shader_param(p, brush_params[p])

func paint(shader_params : Dictionary) -> void:
	if has_albedo:
		albedo_viewport.do_paint(shader_params)
	if has_mr:
		mr_viewport.do_paint(shader_params)
	if has_emission:
		emission_viewport.do_paint(shader_params)
	if has_normal:
		normal_viewport.do_paint(shader_params)
	if has_do:
		do_viewport.do_paint(shader_params)
	if has_mask:
		mask_viewport.do_paint(shader_params)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	emit_signal("painted")

func fill(erase : bool, reset : bool = false) -> void:
	paint({ brush_pos=Vector2(0, 0), brush_ppos=Vector2(0, 0), erase=erase, pressure=1.0, fill=true, reset=reset })

func pick_color(position):
	var view_to_texture_image = view_to_texture_viewport.get_texture().get_data()
	view_to_texture_image.lock()
	var position_in_texture = view_to_texture_image.get_pixelv(position*VIEW_TO_TEXTURE_RATIO)
	position_in_texture = Vector2(position_in_texture.r, position_in_texture.g)
	var albedo_image = get_albedo_texture().get_data()
	albedo_image.lock()
	brush_params.albedo_color = albedo_image.get_pixelv(position_in_texture*albedo_image.get_size())
	var mr_image = get_mr_texture().get_data()
	mr_image.lock()
	var mr = mr_image.get_pixelv(position_in_texture*mr_image.get_size())
	brush_params.metallic = mr.r
	brush_params.roughness = mr.g
	var emission_image = get_emission_texture().get_data()
	emission_image.lock()
	brush_params.emission_color = emission_image.get_pixelv(position_in_texture*emission_image.get_size())
	emit_signal("colors_picked", brush_params)

func get_albedo_texture():
	return albedo_viewport.get_texture()

func get_mr_texture():
	return mr_viewport.get_texture()

func get_emission_texture():
	return emission_viewport.get_texture()

func get_normal_texture():
	return normal_viewport.get_texture()

func get_do_texture():
	return do_viewport.get_texture()

func get_mask_texture():
	return mask_viewport.get_texture()

func save_viewport(v : Viewport, f : String):
	v.get_texture().get_data().save_png(f)

func debug_get_texture_names():
	return [ "View to texture", "Texture to view", "Seams", "Albedo (current layer)", "Metallic/Roughness (current layer)", "Emission (current layer)", "Normal (current layer)", "Depth/Occlusion (current layer)", "Mask (current layer)" ]

func debug_get_texture(ID):
	match ID:
		0:
			return view_to_texture_viewport.get_texture()
		1:
			return texture_to_view_viewport.get_texture()
		2:
			return mesh_seams_tex
		3:
			return albedo_viewport.get_texture()
		4:
			return mr_viewport.get_texture()
		5:
			return emission_viewport.get_texture()
		6:
			return normal_viewport.get_texture()
		7:
			return do_viewport.get_texture()
		8:
			return mask_viewport.get_texture()
	return null
