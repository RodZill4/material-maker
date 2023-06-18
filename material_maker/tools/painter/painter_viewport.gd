extends Node

@export var shader_prefix: String = "paint": set = set_shader_prefix


@onready var strokepaint_viewport = $StrokePaint
@onready var strokepaint_rect : ColorRect = $StrokePaint/Rect

@onready var layerpaint_viewport = $LayerPaint
@onready var layerpaint_layerrect : ColorRect = $LayerPaint/Layer
@onready var layerpaint_strokerect : ColorRect = $LayerPaint/Stroke

@onready var init_material = preload("res://material_maker/tools/painter/shaders/init.tres").duplicate(true)
@onready var init_channels_material = preload("res://material_maker/tools/painter/shaders/init_channels.tres").duplicate(true)

var paint_material
var layer_material
var stroke_material

var param_tex2view : Texture2D
var param_mesh_aabb : AABB
var param_mesh_inv_uv_tex : Texture2D
var param_mesh_normal_tex : Texture2D
var param_mesh_tangent_tex : Texture2D
var param_seams : Texture2D
var param_layer_textures : Dictionary
var brush_params : Dictionary

var painting : int = 0

func _ready() -> void:
	# paint material
	paint_material = ShaderMaterial.new()
	paint_material.shader = Shader.new()
	# layer material in layer viewport
	layer_material = ShaderMaterial.new()
	layer_material.shader = Shader.new()
	layer_material.shader.code = mm_preprocessor.preprocess_file("res://material_maker/tools/painter/shaders/paint_apply_background.gdshader")
	layerpaint_layerrect.material = layer_material
	# stroke material in layer viewport
	stroke_material = ShaderMaterial.new()
	stroke_material.shader = Shader.new()
	stroke_material.shader.code = mm_preprocessor.preprocess_file("res://material_maker/tools/painter/shaders/%s_apply.gdshader" % shader_prefix)
	stroke_material.set_shader_parameter("tex", strokepaint_viewport.get_texture())
	layerpaint_strokerect.material = stroke_material

func set_shader_prefix(p):
	shader_prefix = p
	if is_inside_tree():
		stroke_material.shader.code = mm_preprocessor.preprocess_file("res://material_maker/tools/painter/shaders/%s_apply.gdshader" % shader_prefix)
		stroke_material.set_shader_parameter("tex", strokepaint_viewport.get_texture())

func get_paint_material() -> ShaderMaterial:
	set_paint_shader_params()
	return paint_material

func set_intermediate_textures(tex2view : Texture2D, seams : Texture2D):
	param_tex2view = tex2view
	param_seams = seams
	paint_material.set_shader_parameter("tex2view_tex", param_tex2view)
	paint_material.set_shader_parameter("seams", param_seams)

func set_mesh_textures(mesh_aabb : AABB, mesh_inv_uv_tex : Texture2D, mesh_normal_tex : Texture2D, mesh_tangent_tex : Texture2D):
	param_mesh_aabb = mesh_aabb
	param_mesh_inv_uv_tex = mesh_inv_uv_tex
	param_mesh_normal_tex = mesh_normal_tex
	param_mesh_tangent_tex = mesh_tangent_tex
	paint_material.set_shader_parameter("mesh_aabb_position", param_mesh_aabb.position)
	paint_material.set_shader_parameter("mesh_aabb_size", param_mesh_aabb.size)
	paint_material.set_shader_parameter("mesh_inv_uv_tex", param_mesh_inv_uv_tex)
	paint_material.set_shader_parameter("mesh_normal_tex", param_mesh_normal_tex)
	paint_material.set_shader_parameter("mesh_tangent_tex", param_mesh_tangent_tex)

func set_layer_textures(textures : Dictionary):
	for t in textures.keys():
		param_layer_textures[t] = textures[t]
		paint_material.set_shader_parameter("layer_"+t+"_tex", param_layer_textures[t])

func set_paint_shader_params():
	paint_material.set_shader_parameter("tex2view_tex", param_tex2view)
	paint_material.set_shader_parameter("seams", param_seams)
	paint_material.set_shader_parameter("mesh_aabb_position", param_mesh_aabb.position)
	paint_material.set_shader_parameter("mesh_aabb_size", param_mesh_aabb.size)
	paint_material.set_shader_parameter("mesh_inv_uv_tex", param_mesh_inv_uv_tex)
	paint_material.set_shader_parameter("mesh_normal_tex", param_mesh_normal_tex)
	paint_material.set_shader_parameter("mesh_tangent_tex", param_mesh_tangent_tex)
	paint_material.set_shader_parameter("texture_size", strokepaint_viewport.size.x)
	for t in param_layer_textures.keys():
		paint_material.set_shader_parameter("layer_"+t+"_tex", param_layer_textures[t])
	for p in brush_params.keys():
		paint_material.set_shader_parameter(p, brush_params[p])

func set_texture_size(s : float):
	var size = Vector2(s, s)
	strokepaint_viewport.size = size
	strokepaint_rect.size = size
	layerpaint_viewport.size = size
	layerpaint_layerrect.size = size
	layerpaint_strokerect.size = size

func set_brush(parameters : Dictionary):
	brush_params = parameters
	for p in brush_params.keys():
		paint_material.set_shader_parameter(p, brush_params[p])

func get_shader_prefix() -> String:
	return shader_prefix

func init(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture2D = null):
	strokepaint_rect.material = init_material
	init_material.set_shader_parameter("col", color)
	init_material.set_shader_parameter("tex", texture)
	finish_init()

func init_channels(r_texture, r_mask, g_texture, g_mask, b_texture, b_mask, a_texture, a_mask):
	strokepaint_rect.material = init_channels_material
	init_channels_material.set_shader_parameter("r_tex", r_texture)
	init_channels_material.set_shader_parameter("r_mask", r_mask)
	init_channels_material.set_shader_parameter("g_tex", g_texture)
	init_channels_material.set_shader_parameter("g_mask", g_mask)
	init_channels_material.set_shader_parameter("b_tex", b_texture)
	init_channels_material.set_shader_parameter("b_mask", b_mask)
	init_channels_material.set_shader_parameter("a_tex", a_texture)
	init_channels_material.set_shader_parameter("a_mask", a_mask)
	finish_init()

func finish_init():
	# Render init texture
	strokepaint_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	strokepaint_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	# Copy image from viewport
	var image = strokepaint_viewport.get_texture().get_image()
	false # image.lock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	var texture : ImageTexture = ImageTexture.new()
	texture.set_image(image)
	false # image.unlock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	layer_material.set_shader_parameter("tex", texture)
	layerpaint_layerrect.visible = true
	layerpaint_strokerect.visible = false
	# Cleanup stroke viewport
	strokepaint_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	strokepaint_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	strokepaint_rect.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	layerpaint_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	layerpaint_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	strokepaint_rect.visible = true

func do_paint(shader_params : Dictionary, end_of_stroke : bool = false):
	var reset = false
	painting += 1
	strokepaint_rect.material = paint_material
	layerpaint_strokerect.visible = true
	stroke_material.shader.code = mm_preprocessor.preprocess_file("res://material_maker/tools/painter/shaders/%s_apply.gdshader" % shader_prefix)
	stroke_material.set_shader_parameter("tex", strokepaint_viewport.get_texture())
	for p in shader_params.keys():
		match p:
			"brush_opacity":
				layerpaint_strokerect.color = Color(1.0, 1.0, 1.0, shader_params[p])
			"erase":
				stroke_material.set_shader_parameter("erase", shader_params[p])
			"reset":
				reset = shader_params[p]
			_:
				paint_material.set_shader_parameter(p, shader_params[p])
	strokepaint_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	strokepaint_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE if reset else SubViewport.CLEAR_MODE_NEVER
	await get_tree().process_frame
	await get_tree().process_frame
	layerpaint_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	layerpaint_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	strokepaint_rect.visible = true
	layerpaint_layerrect.visible = !reset
	if end_of_stroke:
		await get_tree().process_frame
		await get_tree().process_frame
		if false and reset:
			var image = strokepaint_viewport.get_texture().get_data()
			var texture : ImageTexture = ImageTexture.new()
			texture.set_image(image)
			layerpaint_strokerect.visible = false
			return
		else:
			var image = layerpaint_viewport.get_texture().get_image()
			var texture : ImageTexture = ImageTexture.new()
			texture.set_image(image)
			layer_material.set_shader_parameter("tex", texture)
			layerpaint_strokerect.visible = true
		strokepaint_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
		strokepaint_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		strokepaint_rect.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		strokepaint_rect.visible = true
	layerpaint_layerrect.visible = true
	painting -= 1

func get_texture():
	return layerpaint_viewport.get_texture()

func get_current_state():
	return layer_material.get_shader_parameter("tex")

func get_stroke_texture():
	return strokepaint_viewport.get_texture()
