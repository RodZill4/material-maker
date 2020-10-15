tool
extends Viewport

export(ShaderMaterial) var paint = preload("res://material_maker/tools/painter/paint.tres")

onready var rect = $Rect

onready var init_material = preload("res://material_maker/tools/painter/init.tres").duplicate(true)
onready var init_channels_material = preload("res://material_maker/tools/painter/init_channels.tres").duplicate(true)
onready var paint_material = paint.duplicate(true)

func set_intermediate_textures(tex2view, seams):
	paint_material.set_shader_param("tex2view_tex", tex2view)
	paint_material.set_shader_param("seams", seams)

func set_texture_size(s : float):
	size = Vector2(s, s)
	rect.rect_size = size

func set_brush(brush_size, brush_strength, viewport_size):
	var brush_size_vector = Vector2(brush_size, brush_size)/viewport_size
	paint_material.set_shader_param("brush_size", brush_size_vector)
	paint_material.set_shader_param("brush_strength", brush_strength)

func set_material(color, texture, channel_mask, pattern_scale, texture_angle, stamp_mode, texture_mask):
	paint_material.set_shader_param("brush_color", color)
	paint_material.set_shader_param("brush_texture", texture)
	paint_material.set_shader_param("brush_channelmask", channel_mask)
	paint_material.set_shader_param("pattern_scale", pattern_scale)
	paint_material.set_shader_param("texture_angle", texture_angle)
	paint_material.set_shader_param("stamp_mode", stamp_mode)
	paint_material.set_shader_param("texture_mask", texture_mask)

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

func paint(position, prev_position, erase):
	rect.material = paint_material
	paint_material.set_shader_param("brush_pos", position)
	paint_material.set_shader_param("brush_ppos", prev_position)
	paint_material.set_shader_param("erase", erase)
	render_target_update_mode = Viewport.UPDATE_ONCE
	update_worlds()
