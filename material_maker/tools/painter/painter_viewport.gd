extends Viewport

export(String) var shader_prefix = "paint"

onready var rect = $Rect

onready var init_material = preload("res://material_maker/tools/painter/shaders/init.tres").duplicate(true)
onready var init_channels_material = preload("res://material_maker/tools/painter/shaders/init_channels.tres").duplicate(true)
onready var paint_material

var param_tex2view : Texture
var param_mesh_aabb : AABB
var param_mesh_inv_uv_tex : Texture
var param_mesh_normal_tex : Texture
var param_seams : Texture
var param_layer_textures : Dictionary
var brush_params : Dictionary

func _ready() -> void:
	paint_material = ShaderMaterial.new()
	paint_material.shader = Shader.new()

func get_paint_material() -> ShaderMaterial:
	set_paint_shader_params()
	return paint_material

func set_intermediate_textures(tex2view : Texture, seams : Texture):
	param_tex2view = tex2view
	param_seams = seams
	set_paint_shader_params()

func set_mesh_textures(mesh_aabb : AABB, mesh_inv_uv_tex : Texture, mesh_normal_tex : Texture):
	param_mesh_aabb = mesh_aabb
	param_mesh_inv_uv_tex = mesh_inv_uv_tex
	param_mesh_normal_tex = mesh_normal_tex
	set_paint_shader_params()

func set_layer_textures(textures : Dictionary):
	for t in textures.keys():
		param_layer_textures[t] = textures[t]
	set_paint_shader_params()

func set_paint_shader_params():
	paint_material.set_shader_param("tex2view_tex", param_tex2view)
	paint_material.set_shader_param("mesh_aabb_position", param_mesh_aabb.position)
	paint_material.set_shader_param("mesh_aabb_size", param_mesh_aabb.size)
	paint_material.set_shader_param("mesh_inv_uv_tex", param_mesh_inv_uv_tex)
	paint_material.set_shader_param("mesh_normal_tex", param_mesh_normal_tex)
	paint_material.set_shader_param("seams", param_seams)
	paint_material.set_shader_param("texture_size", size.x)
	for t in param_layer_textures.keys():
		paint_material.set_shader_param("layer_"+t+"_tex", param_layer_textures[t])
	for p in brush_params.keys():
		paint_material.set_shader_param(p, brush_params[p])

func set_texture_size(s : float):
	size = Vector2(s, s)
	rect.rect_size = size

func set_brush(parameters : Dictionary):
	brush_params = parameters
	set_paint_shader_params()

func get_paint_shader(mode : String) -> String:
	var file = File.new()
	file.open("res://material_maker/tools/painter/shaders/%s_%s.shader" % [ shader_prefix, mode ], File.READ)
	return file.get_as_text()


func init(color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture = null):
	rect.material = init_material
	init_material.set_shader_param("col", color)
	init_material.set_shader_param("tex", texture)
	render_target_update_mode = Viewport.UPDATE_ONCE
	render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	update_worlds()

func init_channels(r_texture, r_mask, g_texture, g_mask, b_texture, b_mask, a_texture, a_mask):
	rect.material = init_channels_material
	init_channels_material.set_shader_param("r_tex", r_texture)
	init_channels_material.set_shader_param("r_mask", r_mask)
	init_channels_material.set_shader_param("g_tex", g_texture)
	init_channels_material.set_shader_param("g_mask", g_mask)
	init_channels_material.set_shader_param("b_tex", b_texture)
	init_channels_material.set_shader_param("b_mask", b_mask)
	init_channels_material.set_shader_param("a_tex", a_texture)
	init_channels_material.set_shader_param("a_mask", a_mask)
	render_target_update_mode = Viewport.UPDATE_ONCE
	render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	update_worlds()

func do_paint(shader_params):
	rect.material = paint_material
	for p in shader_params.keys():
		paint_material.set_shader_param(p, shader_params[p])
	render_target_update_mode = Viewport.UPDATE_ONCE
	update_worlds()
