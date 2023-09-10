extends Node

var texture_size : float = 0

@onready var view_to_texture_viewport = $View2Texture
@onready var view_to_texture_mesh = $View2Texture/PaintedMesh
@onready var view_to_texture_camera = $View2Texture/Camera3D
var view_to_texture_image : Image

@onready var texture_to_view_viewport = $Texture2View
@onready var texture_to_view_mesh = $Texture2View/PaintedMesh
@onready var texture_to_view_texture : ImageTexture = ImageTexture.new()
@onready var texture_to_view_postprocess : ShaderMaterial = preload("res://material_maker/tools/painter/shaders/texture2view_postprocess.tres")

@onready var mesh_seams_tex : ImageTexture = ImageTexture.new()

@onready var albedo_viewport = $AlbedoPaint
@onready var mr_viewport = $MRPaint
@onready var emission_viewport = $EmissionPaint
@onready var normal_viewport = $NormalPaint
@onready var do_viewport = $DOPaint
@onready var mask_viewport = $MaskPaint
const viewport_names : Array = [ "albedo", "mr", "emission", "normal", "do", "mask" ]
@onready var viewports : Dictionary = {
	albedo=albedo_viewport,
	mr=mr_viewport,
	emission=emission_viewport,
	normal=normal_viewport,
	do=do_viewport,
	mask=mask_viewport
}

var camera
var transform
var viewport_size

var brush_node = null
var brush_params = {
	brush_size = 1.0,
	brush_hardness = 0.5,
	pattern_scale  = 10.0,
	pattern_angle  = 0.0
}

var has_channel : Dictionary = {}

var brush_preview_material : ShaderMaterial
var pattern_shown : bool = false
#var brush_textures : Dictionary = {}

var mesh_aabb : AABB
var mesh_inv_uv_tex : ImageTexture = null
var mesh_normal_tex : ImageTexture = null
var mesh_tangent_tex : ImageTexture = null

const VIEW_TO_TEXTURE_RATIO = 2.0

# shader files
var shader_files : Dictionary = {}
const CACHE_SHADER_FILES : bool = false


signal painted(painted_channels)
signal end_of_stroke(stroke_state)


func _ready():
	var v2t_tex = view_to_texture_viewport.get_texture()
	# shader debug
	# add View2Texture as input of Texture2View (to ignore non-visible parts of the mesh)
	texture_to_view_mesh.get_surface_override_material(0).set_shader_parameter("view2texture", v2t_tex)
	# Add Texture2ViewWithoutSeams as input to all painted textures
	mm_deps.create_buffer("painter_%d:brush" % get_instance_id(), self)
	for v in viewports.keys():
		viewports[v].set_intermediate_textures(texture_to_view_texture, mesh_seams_tex)
		mm_deps.create_buffer("painter_%d:%s" % [ get_instance_id(), v ], self)

func update_seams_texture(_m : Mesh = null) -> void:
	texture_to_view_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	var map_renderer = load("res://material_maker/tools/map_renderer/map_renderer.tscn").instantiate()
	add_child(map_renderer)
	await map_renderer.gen(texture_to_view_mesh.mesh, "seams", "copy_to_texture", [ mesh_seams_tex ], texture_size)
	map_renderer.queue_free()

func update_inv_uv_texture(m : Mesh) -> void:
	var map_renderer = load("res://material_maker/tools/map_renderer/map_renderer.tscn").instantiate()
	add_child(map_renderer)
	if mesh_inv_uv_tex == null:
		mesh_inv_uv_tex = ImageTexture.new()
	await map_renderer.gen(m, "position", "copy_to_texture", [ mesh_inv_uv_tex ], texture_size)
	if mesh_normal_tex == null:
		mesh_normal_tex = ImageTexture.new()
	await map_renderer.gen(m, "normal", "copy_to_texture", [ mesh_normal_tex ], texture_size)
	if mesh_tangent_tex == null:
		mesh_tangent_tex = ImageTexture.new()
	await map_renderer.gen(m, "tangent", "copy_to_texture", [ mesh_tangent_tex ], texture_size)
	map_renderer.queue_free()
	mesh_aabb = m.get_aabb()

func set_mesh(m : Mesh):
	var mat : Material
	mat = texture_to_view_mesh.get_surface_override_material(0)
	texture_to_view_mesh.mesh = m
	texture_to_view_mesh.set_surface_override_material(0, mat)
	mat = view_to_texture_mesh.get_surface_override_material(0)
	view_to_texture_mesh.mesh = m
	view_to_texture_mesh.set_surface_override_material(0, mat)
	for init_fct in [ "update_seams_texture", "update_inv_uv_texture" ]:
		var result = await call(init_fct, m)

func calculate_mask(value : float, channel : int) -> Color:
	if (channel == StandardMaterial3D.TEXTURE_CHANNEL_RED):
		return Color(value, 0, 0, 0)
	elif (channel == StandardMaterial3D.TEXTURE_CHANNEL_GREEN):
		return Color(0, value, 0, 0)
	elif (channel == StandardMaterial3D.TEXTURE_CHANNEL_BLUE):
		return Color(0, 0, value, 0)
	elif (channel == StandardMaterial3D.TEXTURE_CHANNEL_ALPHA):
		return Color(0, 0, 0, value)
	return Color(0, 0, 0, 0)


func init_albedo_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture2D = null):
	albedo_viewport.init(color, texture)

func init_mr_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture2D = null):
	mr_viewport.init(color, texture)

func init_mr_texture_channels(metallic : float = 1.0, metallic_texture : Texture2D = null, metallic_channel : int = StandardMaterial3D.TEXTURE_CHANNEL_RED, roughness : float = 1.0, roughness_texture : Texture2D = null, roughness_channel : int = StandardMaterial3D.TEXTURE_CHANNEL_GREEN):
	mr_viewport.init_channels(metallic_texture, calculate_mask(metallic, metallic_channel), roughness_texture, calculate_mask(roughness, roughness_channel), null, Color(1.0, 0.0, 0.0, 0.0), null, Color(1.0, 0.0, 0.0, 0.0))

func init_emission_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture2D = null):
	emission_viewport.init(color, texture)

func init_normal_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture2D = null):
	normal_viewport.init(color, texture)

func init_do_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture2D = null):
	do_viewport.init(color, texture)

func init_do_texture_channels(depth : float = 1.0, depth_texture : Texture2D = null, occlusion : float = 1.0, occlusion_texture : Texture2D = null, occlusion_channel : int = StandardMaterial3D.TEXTURE_CHANNEL_GREEN):
	do_viewport.init_channels(depth_texture, calculate_mask(depth, StandardMaterial3D.TEXTURE_CHANNEL_RED), occlusion_texture, calculate_mask(occlusion, occlusion_channel), null, Color(1.0, 0.0, 0.0, 0.0), null, Color(1.0, 0.0, 0.0, 0.0))

func init_mask_texture(color : Color = Color(0.0, 0.0, 0.0, 1.0), texture : Texture2D = null):
	mask_viewport.init(color, texture)

func init_textures(m : StandardMaterial3D):
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
	if m.heightmap_enabled or m.ao_enabled:
		init_do_texture_channels(m.depth_scale if m.heightmap_enabled else 0.0, m.depth_texture, m.ao_light_affect if m.ao_enabled else 1.0, m.ao_texture, m.ao_texture_channel)
	else:
		init_do_texture(Color(0.0, 1.0, 0.0, 0.0), null)

func set_texture_size(s : float):
	if texture_size != s:
		texture_size = s
		texture_to_view_viewport.size = Vector2(s, s)
		for v in viewports.keys():
			viewports[v].set_texture_size(s)
		update_seams_texture()

func update_view(c, t, s):
	camera = c
	transform = t
	viewport_size = s
	brush_params.view_back = Vector3(0.0, 0.0, 1.0) * transform.basis.orthonormalized()
	brush_params.view_right = Vector3(1.0, 0.0, 0.0) * transform.basis.orthonormalized()
	brush_params.view_up = Vector3(0.0, 1.0, 0.0) * transform.basis.orthonormalized()
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
	var mat : ShaderMaterial = view_to_texture_mesh.get_surface_override_material(0)
	if true:
		var shader_file : FileAccess = FileAccess.open("res://material_maker/tools/painter/shaders/view2texture.gdshader", FileAccess.READ)
		if shader_file != null:
			mat.shader.code = shader_file.get_as_text()
	mat.set_shader_parameter("near", camera.near)
	mat.set_shader_parameter("far", camera.far)
	view_to_texture_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	view_to_texture_image = view_to_texture_viewport.get_texture().get_image()
	mat = texture_to_view_mesh.get_surface_override_material(0)
	if true:
		var shader_file : FileAccess = FileAccess.open("res://material_maker/tools/painter/shaders/texture2view.gdshader", FileAccess.READ)
		if shader_file != null:
			mat.shader.code = shader_file.get_as_text()
	mat.set_shader_parameter("model_transform", transform)
	mat.set_shader_parameter("fovy_degrees", camera.fov)
	mat.set_shader_parameter("z_near", camera.near)
	mat.set_shader_parameter("z_far", camera.far)
	mat.set_shader_parameter("texture_size", texture_size)
	mat.set_shader_parameter("texel_tolerance", 16)
	mat.set_shader_parameter("aspect", aspect)
	texture_to_view_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	var renderer = await mm_renderer.request(self)
	texture_to_view_postprocess.set_shader_parameter("texture_size", texture_size)
	texture_to_view_postprocess.set_shader_parameter("input_tex", texture_to_view_viewport.get_texture())
	texture_to_view_postprocess.set_shader_parameter("seams_tex", mesh_seams_tex)
	renderer = await renderer.render_material(self, texture_to_view_postprocess, texture_size)
	renderer.copy_to_texture(texture_to_view_texture)
	renderer.release(self)

# Brush methods

func get_brush_mode() -> String:
	return brush_node.get_parameter_defs()[0].values[brush_node.get_parameter("mode")].value

func set_brush_node(node) -> void:
	brush_node = node
	update_brush(true)

func set_brush_preview_material(m : ShaderMaterial) -> void:
	brush_preview_material = m

func get_brush_preview_shader(mode : String) -> String:
	return mm_preprocessor.preprocess_file("res://material_maker/tools/painter/shaders/brush_%s.gdshader" % mode)

func set_brush_angle(a) -> void:
	brush_params.pattern_angle = a
	update_brush()

func update_brush_params(shader_params : Dictionary) -> void:
	for p in shader_params.keys():
		brush_params[p] = shader_params[p]
		if brush_preview_material != null:
			brush_preview_material.set_shader_parameter(p, brush_params[p])

func show_pattern(b):
	if pattern_shown != b:
		pattern_shown = b
		update_brush()

func update_brush(update_shaders : bool = false):
	#if brush_params.albedo_texture_mode != 2: $Pattern.visible = false
	if brush_preview_material != null:
		if update_shaders:
			#var brush_shader_file : String = "res://material_maker/tools/painter/shaders/brush_%s.gdshader" % get_brush_mode()
			var brush_shader_file : String = "res://material_maker/tools/painter/shaders/brush.gdshader"
			var code : String = get_output_code(1)
			update_shader("painter_%d:brush" % get_instance_id(), brush_preview_material, brush_shader_file, { BRUSH_MODE="\""+get_brush_mode()+"\"", GENERATED_CODE = code })
		var v2t_tex = view_to_texture_viewport.get_texture()
		brush_preview_material.set_shader_parameter("size", viewport_size)
		brush_preview_material.set_shader_parameter("view2tex_tex", v2t_tex)
		brush_preview_material.set_shader_parameter("mesh_inv_uv_tex", mesh_inv_uv_tex)
		brush_preview_material.set_shader_parameter("mesh_aabb_position", mesh_aabb.position)
		brush_preview_material.set_shader_parameter("mesh_aabb_size", mesh_aabb.size)
		brush_preview_material.set_shader_parameter("mesh_normal_tex", mesh_normal_tex)
		brush_preview_material.set_shader_parameter("mesh_tangent_tex", mesh_tangent_tex)
		brush_preview_material.set_shader_parameter("layer_albedo_tex", get_albedo_texture())
		brush_preview_material.set_shader_parameter("layer_mr_tex", get_mr_texture())
		brush_preview_material.set_shader_parameter("layer_emission_tex", get_emission_texture())
		brush_preview_material.set_shader_parameter("layer_normal_tex", get_normal_texture())
		brush_preview_material.set_shader_parameter("layer_do_tex", get_do_texture())
		for p in brush_params.keys():
			brush_preview_material.set_shader_parameter(p, brush_params[p])
		brush_preview_material.set_shader_parameter("pattern_alpha", 0.5 if pattern_shown else 0.0)
	if brush_node == null:
		return
	# Mode
	var mode : String = get_brush_mode()
	for c in [ "albedo", "emission", "normal" ]:
		has_channel[c] = brush_node.get_parameter("has_"+c)
	has_channel["mr"] = brush_node.get_parameter("has_metallic") or brush_node.get_parameter("has_roughness")
	has_channel["do"] = brush_node.get_parameter("has_depth") or brush_node.get_parameter("has_ao")
	has_channel["mask"] = true
	# Update shaders
	if update_shaders:
		for index in viewport_names.size():
			var viewport_name = viewport_names[index]
			var viewport = viewports[viewport_name]
			var shader_file : String = "res://material_maker/tools/painter/shaders/paint.gdshader"
			var code : String = get_output_code(index+1)
			var defines : Dictionary = {}
			defines.GENERATED_CODE = code
			defines.TEXTURE_TYPE = "\""+viewport.get_shader_prefix()+"\""
			defines.BRUSH_MODE = "\""+mode+"\""
			update_shader("painter_%d:%s" % [ get_instance_id(), viewport_name ], viewport.get_paint_material(), shader_file, defines)
			viewport.set_mesh_textures(mesh_aabb, mesh_inv_uv_tex, mesh_normal_tex, mesh_tangent_tex)
			viewport.set_layer_textures( { albedo=get_albedo_texture(), mr=get_mr_texture(), emission=get_emission_texture(), normal=get_normal_texture(), do=get_do_texture(), mask=get_mask_texture()} )
	for v in viewports.keys():
		viewports[v].set_brush(brush_params)

func get_output_code(index : int) -> String:
	if brush_node == null or !is_instance_valid(brush_node):
		brush_node = null
		return ""
	var context : MMGenContext = MMGenContext.new()
	var source_mask : MMGenBase.ShaderCode = brush_node.get_shader_code("uv", 0, context)
	context = MMGenContext.new(context)
	var source : MMGenBase.ShaderCode = brush_node.get_shader_code("uv", index, context)
	var new_code : String = mm_renderer.common_shader
	new_code += "\n"
	for g in source.globals:
		if source_mask.globals.find(g) == -1:
			source_mask.globals.append(g)
	for g in source_mask.globals:
		new_code += g
	new_code += source_mask.uniforms_as_strings()
	new_code += source.uniforms_as_strings()
	"""
	for t in source.textures.keys():
		if !source_mask.textures.has(t):
			source_mask.textures[t] = source.textures[t]
	brush_textures = source_mask.textures
	"""
	new_code += source_mask.defs+"\n"
	new_code += "\nfloat brush_function(vec2 uv) {\n"
	new_code += "float _seed_variation_ = 0.0;\n"
	new_code += source_mask.code+"\n"
	new_code += "vec2 __brush_box = abs(uv-vec2(0.5));\n"
	new_code += "return (max(__brush_box.x, __brush_box.y) < 0.5) ? "+source_mask.output_values.f+" : 0.0;\n"
	new_code += "}\n"
	new_code += source.defs+"\n"
	new_code += "\nvec4 pattern_function(vec2 uv) {\n"
	new_code += "float _seed_variation_ = 0.0;\n"
	new_code += source.code+"\n"
	new_code += "return "+source.output_values.rgba+";\n"
	new_code += "}\n"
	return new_code

func update_shader(buffer_name : String, shader_material : ShaderMaterial, shader_file : String, defines : Dictionary) -> void:
	if shader_material == null:
		print("no shader material")
		return
	mm_deps.buffer_create_shader_material(buffer_name, MMShaderMaterial.new(shader_material), mm_preprocessor.preprocess_file(shader_file, defines))
	if get_parent().has_method("update_procedural_layer"):
		get_parent().update_procedural_layer()

func on_dep_update_value(buffer_name : String, parameter_name : String, value) -> bool:
	if value != null:
		var suffix = buffer_name.right(-(buffer_name.find(":")+1))
		if suffix == "brush":
			brush_preview_material.set_shader_parameter(parameter_name, value)
		else:
			viewports[suffix].paint_material.set_shader_parameter(parameter_name, value)
	if get_parent().has_method("update_procedural_layer"):
		get_parent().update_procedural_layer()
	return false

func paint(shader_params : Dictionary, end_of_stroke : bool = false, emit_end_of_stroke : bool = true) -> void:
	var active_viewports : Array = []
	for v in viewports.keys():
		if has_channel[v]:
			active_viewports.push_back(v)
			viewports[v].do_paint(shader_params, end_of_stroke)
	var finished : bool = false
	while ! finished:
		await get_tree().process_frame
		finished = true
		for v in active_viewports:
			if viewports[v].painting > 0:
				finished = false
				break
	emit_signal("painted")
	if end_of_stroke and emit_end_of_stroke:
		var stroke_state = {}
		for v in active_viewports:
			stroke_state[v] = viewports[v].get_current_state()
		emit_signal("end_of_stroke", stroke_state)

func set_state(s):
	for c in s.keys():
		if viewports.has(c):
			viewports[c].init(Color(1, 1, 1, 1), s[c])
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	emit_signal("painted")


func fill(erase : bool, reset : bool = false, emit_end_of_stroke : bool = true) -> void:
	paint({ brush_pos=Vector2(0, 0), brush_ppos=Vector2(0, 0), erase=erase, pressure=1.0, fill=true, reset=reset }, true, emit_end_of_stroke)

func view_to_texture(position : Vector2) -> Vector2:
	if view_to_texture_image == null:
		return Vector2(-1, -1)
	var position_in_texture : Color = view_to_texture_image.get_pixelv(position*VIEW_TO_TEXTURE_RATIO)
	if position_in_texture.r == position_in_texture.b && position_in_texture.g == position_in_texture.b:
		return Vector2(-1, -1)
	else:
		return Vector2(position_in_texture.r, position_in_texture.g)

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

func save_viewport(v : SubViewport, f : String):
	v.get_texture().get_data().save_png(f)

func debug_get_texture_names():
	if OS.is_debug_build():
		return [ "View to texture", "Texture2D to view", "Seams", "Albedo (current layer)", "Metallic/Roughness (current layer)", "Emission (current layer)", "Normal (current layer)", "Depth/Occlusion (current layer)", "Mask (current layer)", "Inv. UV map", "Mesh normal map", "Mesh tangent map" ]
	else:
		return [ "Albedo (current layer)", "Metallic/Roughness (current layer)", "Emission (current layer)", "Normal (current layer)", "Depth/Occlusion (current layer)", "Mask (current layer)" ]

# Localization strings
# tr("View to texture")
# tr("Texture2D to view")
# tr("Seams")
# tr("Albedo (current layer)")
# tr("Metallic/Roughness (current layer)")
# tr("Emission (current layer)")
# tr("Normal (current layer)")
# tr("Depth/Occlusion (current layer)")
# tr("Mask (current layer)")

func debug_get_texture(ID):
	if ! OS.is_debug_build():
		ID -= 3
	match ID:
		0:
			return view_to_texture_viewport.get_texture()
		1:
			return texture_to_view_texture
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
		9:
			return mesh_inv_uv_tex
		10:
			return mesh_normal_tex
		11:
			return mesh_tangent_tex



	return null
