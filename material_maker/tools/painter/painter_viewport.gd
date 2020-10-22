extends Viewport

export(String) var shader_prefix = "paint"

onready var rect = $Rect

onready var init_material = preload("res://material_maker/tools/painter/shaders/init.tres").duplicate(true)
onready var init_channels_material = preload("res://material_maker/tools/painter/shaders/init_channels.tres").duplicate(true)
onready var paint_material

var param_tex2view : Texture
var param_seams : Texture
var param_brush_size : Vector2
var param_brush_strength : float
var param_pattern_scale : float
var param_texture_angle : float
var param_stamp_mode : bool

func _ready() -> void:
	paint_material = ShaderMaterial.new()
	paint_material.shader = Shader.new()

func get_paint_material() -> ShaderMaterial:
	set_paint_shader_params()
	return paint_material

func set_intermediate_textures(tex2view, seams):
	param_tex2view = tex2view
	param_seams = seams
	set_paint_shader_params()

func set_paint_shader_params():
	paint_material.set_shader_param("tex2view_tex", param_tex2view)
	paint_material.set_shader_param("seams", param_seams)
	paint_material.set_shader_param("brush_size", param_brush_size)
	paint_material.set_shader_param("brush_strength", param_brush_strength)
	paint_material.set_shader_param("pattern_scale", param_pattern_scale)
	paint_material.set_shader_param("pattern_angle", param_texture_angle)
	paint_material.set_shader_param("stamp_mode", param_stamp_mode)

func set_texture_size(s : float):
	size = Vector2(s, s)
	rect.rect_size = size

func set_brush(brush_size, brush_strength, viewport_size):
	param_brush_size = Vector2(brush_size, brush_size)/viewport_size
	param_brush_strength = brush_strength
	set_paint_shader_params()

func get_paint_shader(mode : String) -> String:
	var file = File.new()
	file.open("res://material_maker/tools/painter/shaders/%s_%s.shader" % [ shader_prefix, mode ], File.READ)
	return file.get_as_text()

func set_material(_mode, pattern_scale, pattern_angle, stamp_mode):
	param_pattern_scale = pattern_scale
	param_texture_angle = pattern_angle
	param_stamp_mode = _mode == "stamp"
	set_paint_shader_params()

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

func do_paint(position, prev_position, erase):
	rect.material = paint_material
	paint_material.set_shader_param("brush_pos", position)
	paint_material.set_shader_param("brush_ppos", prev_position)
	paint_material.set_shader_param("erase", erase)
	render_target_update_mode = Viewport.UPDATE_ONCE
	update_worlds()
