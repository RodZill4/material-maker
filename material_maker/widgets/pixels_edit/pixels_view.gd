@tool
class_name PixelsView

extends Control


@export var draw_area : bool = true
@export var auto_rescale : bool = true
@export var alpha : float = 1.0

var pixels : MMPixels

var draw_size : Vector2 = Vector2(1, 1)
var draw_offset : Vector2 = Vector2(0, 0)

func _init(v : MMPixels = null) -> void:
	pixels = v

func _ready() -> void:
	if pixels == null:
		pixels = MMPixels.new()
	connect("resized", Callable(self, "_on_resize"))
	_on_resize()

func set_view_rect(do : Vector2, ds : Vector2):
	draw_size = ds
	draw_offset = do
	queue_redraw()

func transform_point(p : Vector2) -> Vector2:
	return draw_offset+p*draw_size

func reverse_transform_point(p : Vector2) -> Vector2:
	return (p-draw_offset)/draw_size

func _draw():
	if draw_area:
		var current_theme : Theme = mm_globals.main_window.theme
		var bg = current_theme.get_stylebox("panel", "Panel").bg_color
		var fg = current_theme.get_color("font_color", "Label")
		var axes_color : Color = bg.lerp(fg, 0.25)
		draw_rect(Rect2(draw_offset, draw_size), axes_color, false)
	var pixel_size : Vector2 = draw_size/Vector2(pixels.size)
	for x in range(pixels.size.x):
		for y in range(pixels.size.y):
			var c : int = pixels.get_color_index(x, y)
			var color : Color = pixels.palette[c]
			color.a *= alpha
			draw_rect(Rect2(draw_offset+draw_size*Vector2(x, y)/Vector2(pixels.size), pixel_size), color, true)

func _on_resize() -> void:
	if auto_rescale:
		var ds : float = min(size.x, size.y)
		set_view_rect(0.5*(size-draw_size), Vector2(ds, ds))
