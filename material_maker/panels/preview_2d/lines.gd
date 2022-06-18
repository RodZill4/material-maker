extends Control

export var config_var_suffix : String = ""
export var style : int = 1 setget set_style
export var grid_size : float = 0.0 setget set_grid_size
export var color : Color = Color(0.5, 0.5, 0.5) setget set_color

const STYLES : Array = [ "None", "Corners", "Lines", "Grid4x4", "Grid8x8", "Grid10x10", "Grid16x16" ]

func _ready():
	config_var_suffix = get_parent().config_var_suffix
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_style"):
		style = mm_globals.get_config("preview"+config_var_suffix+"_guides_style")
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_grid_size"):
		grid_size = mm_globals.get_config("preview"+config_var_suffix+"_guides_grid_size")
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_color"):
		color = mm_globals.get_config("preview"+config_var_suffix+"_guides_color")
	set_grid_size(grid_size, false)
	set_color(color, false)
	set_style(style)

func draw_grid(size : int) -> void:
	grid_size = size
	var parent = get_parent()
	for i in range(size+1):
		var x = float(i) / float(size) - 0.5
		var p = parent.value_to_pos(Vector2(x, x))
		draw_line(Vector2(p.x, 0), Vector2(p.x, rect_size.y), color)
		draw_line(Vector2(0, p.y), Vector2(rect_size.x, p.y), color)

func _draw() -> void:
	var parent = get_parent()
	var p
	match style:
		1:
			p = parent.value_to_pos(Vector2(-0.5, -0.52))
			draw_line(p, Vector2(p.x, 0), color)
			p = parent.value_to_pos(Vector2(0.5, -0.52))
			draw_line(p, Vector2(p.x, 0), color)
			p = parent.value_to_pos(Vector2(-0.52, -0.5))
			draw_line(p, Vector2(0, p.y), color)
			p = parent.value_to_pos(Vector2(-0.52, 0.5))
			draw_line(p, Vector2(0, p.y), color)
			p = parent.value_to_pos(Vector2(-0.5, 0.52))
			draw_line(p, Vector2(p.x, rect_size.y), color)
			p = parent.value_to_pos(Vector2(0.5, 0.52))
			draw_line(p, Vector2(p.x, rect_size.y), color)
			p = parent.value_to_pos(Vector2(0.52, -0.5))
			draw_line(p, Vector2(rect_size.x, p.y), color)
			p = parent.value_to_pos(Vector2(0.52, 0.5))
			draw_line(p, Vector2(rect_size.x, p.y), color)
		2:
			draw_grid(1)
		3:
			draw_grid(4)
		4:
			draw_grid(8)
		5:
			draw_grid(10)
		6:
			draw_grid(16)
		1000:
			draw_grid(int(grid_size))

func set_style(s : int) -> void:
	style = s
	update()
	mm_globals.set_config("preview"+config_var_suffix+"_guides_style", s)
	match style:
		1:
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, 128)
		2:
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, 1)
		3:
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, 4)
		4:
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, 8)
		5:
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, 10)
		6:
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, 16)
		1000:
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, grid_size)
		_:
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, 128)

func show_grid(value) -> void:
	set_grid_size(value, false)
	set_style(1000)

func set_color(c : Color, up : bool = true) -> void:
	color = c
	if up:
		update()
	mm_globals.set_config("preview"+config_var_suffix+"_guides_color", c)
	
func set_grid_size(s : float, up : bool = true) -> void:
	grid_size = s
	if up:
		update()
	mm_globals.set_config("preview"+config_var_suffix+"_guides_grid_size", s)
