extends Node

onready var view_to_texture_viewport = $View2Texture
onready var view_to_texture_mesh = $View2Texture/PaintedMesh
onready var view_to_texture_camera = $View2Texture/Camera

onready var texture_to_view_viewport = $Texture2View
onready var texture_to_view_mesh = $Texture2View/PaintedMesh
onready var texture_to_view_mesh_white = $Texture2View/PaintedMeshWhite

onready var seams_viewport = $Seams
onready var seams_rect = $Seams/SeamsRect
onready var seams_material = seams_rect.get_material()

onready var albedo_viewport = $AlbedoPaint
onready var mr_viewport = $MRPaint
onready var emission_viewport = $EmissionPaint
onready var depth_viewport = $DepthPaint
onready var viewports = [ albedo_viewport, mr_viewport, emission_viewport, depth_viewport]

var camera
var transform
var viewport_size

var current_brush = {
	node          = null,
	size          = 50.0,
	strength      = 0.5,
	pattern_scale = 10.0,
	pattern_angle = 0.0
}

var has_albedo : bool = false
var has_mr : bool = false
var has_emission : bool = false
var has_depth : bool = false

var brush_preview_material : ShaderMaterial

const VIEW_TO_TEXTURE_RATIO = 2.0

signal colors_picked(brush)
signal painted()

func _ready():
	var v2t_tex = view_to_texture_viewport.get_texture()
	var t2v_tex = texture_to_view_viewport.get_texture()
	var seams_tex = seams_viewport.get_texture()
	# add View2Texture as input of Texture2View (to ignore non-visible parts of the mesh)
	texture_to_view_mesh.get_surface_material(0).set_shader_param("view2texture", v2t_tex)
	# Add Texture2ViewWithoutSeams as input to all painted textures
	for index in range(4):
		viewports[index].set_intermediate_textures(t2v_tex, seams_tex)
	# Add Texture2View as input to seams texture
	seams_material.set_shader_param("tex", t2v_tex)

func update_seams_texture():
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	texture_to_view_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	seams_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	seams_viewport.update_worlds()

func set_mesh(m : Mesh):
	var mat : Material
	mat = texture_to_view_mesh.get_surface_material(0)
	texture_to_view_mesh.mesh = m
	texture_to_view_mesh.set_surface_material(0, mat)
	mat = texture_to_view_mesh_white.get_surface_material(0)
	texture_to_view_mesh_white.mesh = m
	texture_to_view_mesh_white.set_surface_material(0, mat)
	mat = view_to_texture_mesh.get_surface_material(0)
	view_to_texture_mesh.mesh = m
	view_to_texture_mesh.set_surface_material(0, mat)
	update_seams_texture()

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
	
func init_depth_texture(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture = null):
	depth_viewport.init(color, texture)

func init_textures(m : SpatialMaterial):
	init_albedo_texture(m.albedo_color, m.albedo_texture)
	init_mr_texture_channels(m.metallic, m.metallic_texture, m.metallic_texture_channel, m.roughness, m.roughness_texture, m.roughness_texture_channel)
	if m.emission_enabled:
		var emission_color = m.emission
		emission_color.a = 1.0
		init_emission_texture(emission_color, m.emission_texture)
	else:
		init_emission_texture(Color(0.0, 0.0, 0.0), null)
	if m.depth_enabled:
		init_depth_texture(Color(1.0, 1.0, 1.0), m.depth_texture)
	else:
		init_depth_texture(Color(0.0, 0.0, 0.0), null)

func set_texture_size(s : float):
	texture_to_view_viewport.size = Vector2(s, s)
	for index in range(4):
		viewports[index].set_texture_size(s)

func update_view(c, t, s):
	camera = c
	transform = t
	viewport_size = s
	update_tex2view()
	update_brush()

func update_tex2view():
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
	material.set_shader_param("model_transform", transform)
	material.set_shader_param("fovy_degrees", camera.fov)
	material.set_shader_param("z_near", camera.near)
	material.set_shader_param("z_far", camera.far)
	material.set_shader_param("aspect", aspect)
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	texture_to_view_viewport.update_worlds()

# Brush methods

func get_brush_mode() -> String:
	return current_brush.node.get_parameter_defs()[0].values[current_brush.node.get_parameter("mode")].value

func set_brush_node(node) -> void:
	current_brush.node = node
	update_brush(true)

func set_brush_preview_material(m : ShaderMaterial) -> void:
	brush_preview_material = m

func get_brush_preview_shader(mode : String) -> String:
	var file = File.new()
	file.open("res://material_maker/tools/painter/shaders/brush_%s.shader" % mode, File.READ)
	return file.get_as_text()

func edit_brush(s):
	current_brush.size += s.x*0.1
	current_brush.size = clamp(current_brush.size, 0.0, 250.0)
	if get_brush_mode() == "stamp":
		current_brush.pattern_angle += fmod(s.y*0.01, 2.0*PI)
	else:
		current_brush.strength += s.y*0.01
		current_brush.strength = clamp(current_brush.strength, 0.0, 0.99999)
	update_brush()

func edit_pattern(s):
	current_brush.pattern_scale += s.x*0.1
	current_brush.pattern_scale = clamp(current_brush.pattern_scale, 0.1, 25.0)
	current_brush.pattern_angle += fmod(s.y*0.01, 2.0*PI)
	update_brush()

func set_brush_angle(a) -> void:
	current_brush.pattern_angle = a
	update_brush()

func show_pattern(b):
	pass
	# TODO: add parameter in shaders
	#$Pattern.visible = b and brush_node.get_parameter("mode") == 1

func update_brush(update_shaders = false):
	#if current_brush.albedo_texture_mode != 2: $Pattern.visible = false
	var brush_size_vector = Vector2(current_brush.size, current_brush.size)/viewport_size
	if brush_preview_material != null:
		brush_preview_material.set_shader_param("brush_size", brush_size_vector)
		brush_preview_material.set_shader_param("brush_strength", current_brush.strength)
		brush_preview_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
		brush_preview_material.set_shader_param("pattern_angle", current_brush.pattern_angle)
		brush_preview_material.set_shader_param("brush_texture", null)
	if update_shaders:
		var code : String = get_output_code(1)
		update_shader(brush_preview_material, get_brush_preview_shader(get_brush_mode()), code)
	if current_brush.node == null:
		return
	# Mode
	var mode : String = get_brush_mode()
	has_albedo = current_brush.node.get_parameter("has_albedo")
	has_mr = current_brush.node.get_parameter("has_metallic") or current_brush.node.get_parameter("has_roughness")
	has_emission = current_brush.node.get_parameter("has_emission")
	has_depth = current_brush.node.get_parameter("has_depth")
	# Update shaders
	if update_shaders:
		for index in range(4):
			update_shader(viewports[index].get_paint_material(), viewports[index].get_paint_shader(mode), get_output_code(index+1))
		update_shader(brush_preview_material, get_brush_preview_shader(mode), get_output_code(1))
	for index in range(4):
		viewports[index].set_material(mode, current_brush.pattern_scale, current_brush.pattern_angle, true)
	if viewport_size != null:
		for index in range(4):
			viewports[index].set_brush(current_brush.size, current_brush.strength, viewport_size)
		brush_preview_material.set_shader_param("brush_size", Vector2(current_brush.size, current_brush.size)/viewport_size)
		brush_preview_material.set_shader_param("brush_strength", current_brush.strength)

func do_on_brush_changed():
	update_brush(true)

func get_output_code(index : int) -> String:
	if current_brush.node == null:
		return ""
	var context : MMGenContext = MMGenContext.new()
	var source_mask = current_brush.node.get_shader_code("uv", 0, context)
	context = MMGenContext.new(context)
	var source = current_brush.node.get_shader_code("uv", index, context)
	var new_code : String = mm_renderer.common_shader
	new_code += "\n"
	for g in source.globals:
		if source_mask.globals.find(g) == -1:
			source_mask.globals.append(g)
	for g in source_mask.globals:
		new_code += g
	new_code += source_mask.defs+"\n"
	new_code += "\nfloat brush_function(vec2 uv) {\n"
	new_code += source_mask.code+"\n"
	new_code += "vec2 __brush_box = abs(uv-vec2(0.5));\n"
	new_code += "return (max(__brush_box.x, __brush_box.y) < 0.5) ? "+source_mask.f+" : 0.0;\n"
	new_code += "}\n"
	new_code += source.defs+"\n"
	new_code += "\nvec4 pattern_function(vec2 uv) {\n"
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


func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	for index in range(4):
		mm_renderer.update_float_parameters(viewports[index].paint_material, parameter_changes)
	mm_renderer.update_float_parameters(brush_preview_material, parameter_changes)

func paint(position, prev_position, erase, pressure):
	if has_albedo:
		albedo_viewport.do_paint(position, prev_position, erase, pressure)
	if has_mr:
		mr_viewport.do_paint(position, prev_position, erase, pressure)
	if has_emission:
		emission_viewport.do_paint(position, prev_position, erase, pressure)
	if has_depth:
		depth_viewport.do_paint(position, prev_position, erase, pressure)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	emit_signal("painted")

func pick_color(position):
	var view_to_texture_image = view_to_texture_viewport.get_texture().get_data()
	view_to_texture_image.lock()
	var position_in_texture = view_to_texture_image.get_pixelv(position*VIEW_TO_TEXTURE_RATIO)
	position_in_texture = Vector2(position_in_texture.r, position_in_texture.g)
	var albedo_image = get_albedo_texture().get_data()
	albedo_image.lock()
	current_brush.albedo_color = albedo_image.get_pixelv(position_in_texture*albedo_image.get_size())
	var mr_image = get_mr_texture().get_data()
	mr_image.lock()
	var mr = mr_image.get_pixelv(position_in_texture*mr_image.get_size())
	current_brush.metallic = mr.r
	current_brush.roughness = mr.g
	var emission_image = get_emission_texture().get_data()
	emission_image.lock()
	current_brush.emission_color = emission_image.get_pixelv(position_in_texture*emission_image.get_size())
	emit_signal("colors_picked", current_brush)

func get_albedo_texture():
	return albedo_viewport.get_texture()

func get_mr_texture():
	return mr_viewport.get_texture()

func get_emission_texture():
	return emission_viewport.get_texture()

func get_depth_texture():
	return depth_viewport.get_texture()

func save_viewport(v : Viewport, f : String):
	v.get_texture().get_data().save_png(f)

func debug_get_texture_names():
	return [ "View to texture", "Texture to view", "Seams", "Albedo (current layer)", "Metallic/Roughness (current layer)", "Emission (current layer)", "Depth (current layer)" ]

func debug_get_texture(ID):
	match ID:
		0:
			return view_to_texture_viewport.get_texture()
		1:
			return texture_to_view_viewport.get_texture()
		2:
			return seams_viewport.get_texture()
		3:
			return albedo_viewport.get_texture()
		4:
			return mr_viewport.get_texture()
		5:
			return emission_viewport.get_texture()
		6:
			return depth_viewport.get_texture()
	return null
