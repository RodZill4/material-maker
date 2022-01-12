extends Node

export(String) var shader_prefix = "paint" setget set_shader_prefix

onready var strokepaint_viewport = $StrokePaint
onready var strokepaint_rect: ColorRect = $StrokePaint/Rect

onready var layerpaint_viewport = $LayerPaint
onready var layerpaint_layerrect: ColorRect = $LayerPaint/Layer
onready var layerpaint_strokerect: ColorRect = $LayerPaint/Stroke

onready var init_material = preload("res://material_maker/tools/painter/shaders/init.tres").duplicate(true)
onready var init_channels_material = preload("res://material_maker/tools/painter/shaders/init_channels.tres").duplicate(true)

var paint_material
var layer_material
var stroke_material

var param_tex2view: Texture
var param_mesh_aabb: AABB
var param_mesh_inv_uv_tex: Texture
var param_mesh_normal_tex: Texture
var param_mesh_tangent_tex: Texture
var param_seams: Texture
var param_layer_textures: Dictionary
var brush_params: Dictionary

var painting: int = 0


func _ready() -> void:
	# paint material
	paint_material = ShaderMaterial.new()
	paint_material.shader = Shader.new()
	# layer material in layer viewport
	layer_material = ShaderMaterial.new()
	layer_material.shader = Shader.new()
	layer_material.shader.code = get_parent().get_shader_file("paint_apply_background")
	layerpaint_layerrect.material = layer_material
	# stroke material in layer viewport
	stroke_material = ShaderMaterial.new()
	stroke_material.shader = Shader.new()
	stroke_material.shader.code = get_parent().get_shader_file(shader_prefix + "_apply")
	stroke_material.set_shader_param("tex", strokepaint_viewport.get_texture())
	layerpaint_strokerect.material = stroke_material


func set_shader_prefix(p):
	shader_prefix = p
	if is_inside_tree():
		stroke_material.shader.code = get_parent().get_shader_file(shader_prefix + "_apply")
		stroke_material.set_shader_param("tex", strokepaint_viewport.get_texture())


func get_paint_material() -> ShaderMaterial:
	set_paint_shader_params()
	return paint_material


func set_intermediate_textures(tex2view: Texture, seams: Texture):
	param_tex2view = tex2view
	param_seams = seams
	paint_material.set_shader_param("tex2view_tex", param_tex2view)
	paint_material.set_shader_param("seams", param_seams)


func set_mesh_textures(
	mesh_aabb: AABB, mesh_inv_uv_tex: Texture, mesh_normal_tex: Texture, mesh_tangent_tex: Texture
):
	param_mesh_aabb = mesh_aabb
	param_mesh_inv_uv_tex = mesh_inv_uv_tex
	param_mesh_normal_tex = mesh_normal_tex
	param_mesh_tangent_tex = mesh_tangent_tex
	paint_material.set_shader_param("mesh_aabb_position", param_mesh_aabb.position)
	paint_material.set_shader_param("mesh_aabb_size", param_mesh_aabb.size)
	paint_material.set_shader_param("mesh_inv_uv_tex", param_mesh_inv_uv_tex)
	paint_material.set_shader_param("mesh_normal_tex", param_mesh_normal_tex)
	paint_material.set_shader_param("mesh_tangent_tex", param_mesh_tangent_tex)


func set_layer_textures(textures: Dictionary):
	for t in textures.keys():
		param_layer_textures[t] = textures[t]
		paint_material.set_shader_param("layer_" + t + "_tex", param_layer_textures[t])


func set_paint_shader_params():
	paint_material.set_shader_param("tex2view_tex", param_tex2view)
	paint_material.set_shader_param("seams", param_seams)
	paint_material.set_shader_param("mesh_aabb_position", param_mesh_aabb.position)
	paint_material.set_shader_param("mesh_aabb_size", param_mesh_aabb.size)
	paint_material.set_shader_param("mesh_inv_uv_tex", param_mesh_inv_uv_tex)
	paint_material.set_shader_param("mesh_normal_tex", param_mesh_normal_tex)
	paint_material.set_shader_param("mesh_tangent_tex", param_mesh_tangent_tex)
	paint_material.set_shader_param("texture_size", strokepaint_viewport.size.x)
	for t in param_layer_textures.keys():
		paint_material.set_shader_param("layer_" + t + "_tex", param_layer_textures[t])
	for p in brush_params.keys():
		paint_material.set_shader_param(p, brush_params[p])


func set_texture_size(s: float):
	var size = Vector2(s, s)
	strokepaint_viewport.size = size
	strokepaint_rect.rect_size = size
	layerpaint_viewport.size = size
	layerpaint_layerrect.rect_size = size
	layerpaint_strokerect.rect_size = size


func set_brush(parameters: Dictionary):
	brush_params = parameters
	for p in brush_params.keys():
		paint_material.set_shader_param(p, brush_params[p])


func get_shader_prefix() -> String:
	return shader_prefix


func init(color: Color = Color(0.0, 0.0, 0.0, 0.0), texture: Texture = null):
	strokepaint_rect.material = init_material
	init_material.set_shader_param("col", color)
	init_material.set_shader_param("tex", texture)
	finish_init()


func init_channels(r_texture, r_mask, g_texture, g_mask, b_texture, b_mask, a_texture, a_mask):
	strokepaint_rect.material = init_channels_material
	init_channels_material.set_shader_param("r_tex", r_texture)
	init_channels_material.set_shader_param("r_mask", r_mask)
	init_channels_material.set_shader_param("g_tex", g_texture)
	init_channels_material.set_shader_param("g_mask", g_mask)
	init_channels_material.set_shader_param("b_tex", b_texture)
	init_channels_material.set_shader_param("b_mask", b_mask)
	init_channels_material.set_shader_param("a_tex", a_texture)
	init_channels_material.set_shader_param("a_mask", a_mask)
	finish_init()


func finish_init():
	# Render init texture
	strokepaint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	strokepaint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	strokepaint_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	# Copy image from viewport
	var image = strokepaint_viewport.get_texture().get_data()
	image.lock()
	var texture: ImageTexture = ImageTexture.new()
	texture.create_from_image(image)
	image.unlock()
	layer_material.set_shader_param("tex", texture)
	layerpaint_layerrect.visible = true
	layerpaint_strokerect.visible = false
	# Cleanup stroke viewport
	strokepaint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	strokepaint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	strokepaint_rect.visible = false
	strokepaint_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	layerpaint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	layerpaint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	layerpaint_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	strokepaint_rect.visible = true


func do_paint(shader_params: Dictionary, end_of_stroke: bool = false):
	var reset = false
	painting += 1
	strokepaint_rect.material = paint_material
	layerpaint_strokerect.visible = true
	stroke_material.shader.code = get_parent().get_shader_file(shader_prefix + "_apply")
	stroke_material.set_shader_param("tex", strokepaint_viewport.get_texture())
	for p in shader_params.keys():
		match p:
			"brush_opacity":
				layerpaint_strokerect.self_modulate = Color(1.0, 1.0, 1.0, shader_params[p])
			"erase":
				stroke_material.set_shader_param("erase", shader_params[p])
			"reset":
				reset = shader_params[p]
			_:
				paint_material.set_shader_param(p, shader_params[p])
	strokepaint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	strokepaint_viewport.render_target_clear_mode = (
		Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		if reset
		else Viewport.CLEAR_MODE_NEVER
	)
	strokepaint_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	layerpaint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	layerpaint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	strokepaint_rect.visible = true
	layerpaint_layerrect.visible = !reset
	layerpaint_viewport.update_worlds()
	if end_of_stroke:
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		if false and reset:
			var image = strokepaint_viewport.get_texture().get_data()
			image.lock()
			var texture: ImageTexture = ImageTexture.new()
			texture.create_from_image(image)
			image.unlock()
			layerpaint_strokerect.visible = false
			return
		else:
			var image = layerpaint_viewport.get_texture().get_data()
			image.lock()
			var texture: ImageTexture = ImageTexture.new()
			texture.create_from_image(image)
			image.unlock()
			layer_material.set_shader_param("tex", texture)
			layerpaint_strokerect.visible = true
		strokepaint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		strokepaint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		strokepaint_rect.visible = false
		strokepaint_viewport.update_worlds()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		strokepaint_rect.visible = true
	layerpaint_layerrect.visible = true
	painting -= 1


func get_texture():
	return layerpaint_viewport.get_texture()


func get_current_state():
	return layer_material.get_shader_param("tex")


func get_stroke_texture():
	return strokepaint_viewport.get_texture()
