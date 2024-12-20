extends Control

@export var config_var_suffix : String = ""
@export var style : int = 1:
	set(s):
		s = clamp(s, 0, 3)
		if s != style:
			style = s
			queue_redraw()
			mm_globals.set_config("preview"+config_var_suffix+"_guides_style", style)

@export var grid_size : float = 0.0:
	set(s):
		if s != grid_size:
			grid_size = s
			queue_redraw()
			mm_globals.set_config("preview"+config_var_suffix+"_guides_grid_size", grid_size)
			mm_renderer.set_global_parameter("mm_grid_size"+config_var_suffix, grid_size)

@export var color : Color = Color(0.5, 0.5, 0.5):
	set(c):
		if c != color:
			color = c
			queue_redraw()
			mm_globals.set_config("preview"+config_var_suffix+"_guides_color", color)


const STYLES : Array = [ "None", "Corners", "Lines", "Grid" ]


func _ready():
	config_var_suffix = get_parent().config_var_suffix
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_style"):
		style = mm_globals.get_config("preview"+config_var_suffix+"_guides_style")
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_grid_size"):
		grid_size = mm_globals.get_config("preview"+config_var_suffix+"_guides_grid_size")
	if mm_globals.has_config("preview"+config_var_suffix+"_guides_color"):
		color = mm_globals.get_config("preview"+config_var_suffix+"_guides_color")

func draw_grid(s : int) -> void:
	var parent = get_parent()
	for i in range(s+1):
		var x = float(i) / float(s) - 0.5
		var p : Vector2 = parent.value_to_pos(Vector2(x, x))
		draw_line(Vector2(p.x, 0), Vector2(p.x, size.y), color)
		draw_line(Vector2(0, p.y), Vector2(size.x, p.y), color)

func _draw() -> void:
	var parent = get_parent()
	var p
	match style:
		0:
			pass
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
			draw_line(p, Vector2(p.x, size.y), color)
			p = parent.value_to_pos(Vector2(0.5, 0.52))
			draw_line(p, Vector2(p.x, size.y), color)
			p = parent.value_to_pos(Vector2(0.52, -0.5))
			draw_line(p, Vector2(size.x, p.y), color)
			p = parent.value_to_pos(Vector2(0.52, 0.5))
			draw_line(p, Vector2(size.x, p.y), color)
		2:
			draw_grid(1)
		_:
			draw_grid(int(grid_size))
