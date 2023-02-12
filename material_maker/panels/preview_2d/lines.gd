extends Control

@export var config_var_suffix : String = ""
var _real_style : int = 1
@export var style : int :
	get:
		return _real_style
	set(s):
		set_style(s)

var _real_grid_size : float = 0.0
@export var grid_size : float :
	get:
		return _real_grid_size
	set(s):
		set_grid_size(s)

var _real_color : Color = Color(0.5, 0.5, 0.5)
@export var color : Color :
	get:
		return _real_color
	set(c):
		set_color(c)


const STYLES : Array = [ "None", "Corners", "Lines", "Grid4x4", "Grid8x8", "Grid10x10", "Grid16x16" ]

func _ready():
	# todo
	return
	config_var_suffix = get_parent().config_var_suffix
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_style"):
		_real_style = mm_globals.get_config("preview"+config_var_suffix+"_guides_style")
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_grid_size"):
		_real_grid_size = mm_globals.get_config("preview"+config_var_suffix+"_guides_grid_size")
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_color"):
		_real_color = mm_globals.get_config("preview"+config_var_suffix+"_guides_color")
	set_grid_size(_real_grid_size, false)
	set_color(_real_color, false)
	set_style(_real_style)

func draw_grid(s : int) -> void:
	_real_grid_size = s
	var parent = get_parent()
	print(parent)
	for i in range(s+1):
		var x = float(i) / float(s) - 0.5
		var p : Vector2 = parent.value_to_pos(Vector2(x, x))
		draw_line(Vector2(p.x, 0), Vector2(p.x, size.y), _real_color)
		draw_line(Vector2(0, p.y), Vector2(size.x, p.y), _real_color)

func _draw() -> void:
	var parent = get_parent()
	var p
	match _real_style:
		1:
			p = parent.value_to_pos(Vector2(-0.5, -0.52))
			draw_line(p, Vector2(p.x, 0), _real_color)
			p = parent.value_to_pos(Vector2(0.5, -0.52))
			draw_line(p, Vector2(p.x, 0), _real_color)
			p = parent.value_to_pos(Vector2(-0.52, -0.5))
			draw_line(p, Vector2(0, p.y), _real_color)
			p = parent.value_to_pos(Vector2(-0.52, 0.5))
			draw_line(p, Vector2(0, p.y), _real_color)
			p = parent.value_to_pos(Vector2(-0.5, 0.52))
			draw_line(p, Vector2(p.x, size.y), _real_color)
			p = parent.value_to_pos(Vector2(0.5, 0.52))
			draw_line(p, Vector2(p.x, size.y), _real_color)
			p = parent.value_to_pos(Vector2(0.52, -0.5))
			draw_line(p, Vector2(size.x, p.y), _real_color)
			p = parent.value_to_pos(Vector2(0.52, 0.5))
			draw_line(p, Vector2(size.x, p.y), _real_color)
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
			draw_grid(int(_real_grid_size))

func set_style(s : int) -> void:
	_real_style = s
	queue_redraw()
	mm_globals.set_config("preview"+config_var_suffix+"_guides_style", s)
	var mm_grid_size : int
	match _real_style:
		2:
			mm_grid_size = 1
		3:
			mm_grid_size = 4
		4:
			mm_grid_size = 8
		5:
			mm_grid_size = 10
		6:
			mm_grid_size = 16
		1000:
			mm_grid_size = _real_grid_size
		_:
			mm_grid_size = 128
	mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, mm_grid_size)

func show_grid(value) -> void:
	set_grid_size(value, false)
	set_style(1000)

func set_color(c : Color, up : bool = true) -> void:
	_real_color = c
	if up:
		queue_redraw()
	mm_globals.set_config("preview"+config_var_suffix+"_guides_color", c)
	
func set_grid_size(s : float, up : bool = true) -> void:
	_real_grid_size = s
	if up:
		queue_redraw()
	mm_globals.set_config("preview"+config_var_suffix+"_guides_grid_size", s)
