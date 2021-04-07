extends Control

var moving : bool = false

var min_x : float
var max_x : float
var min_y : float
var max_y : float

const OFFSET : Vector2 = Vector2(3, 3)

signal moved(index)
signal removed(index)

func _ready():
	pass # Replace with function body.

func _draw():
	var current_theme : Theme = mm_globals.get_main_window().theme
	var color : Color = current_theme.get_color("font_color", "Label")
	for c in get_children():
		if c.visible:
			draw_line(OFFSET, c.rect_position+OFFSET, color)
	draw_rect(Rect2(0, 0, 7, 7), color)

func initialize(p : MMCurve.Point) -> void:
	rect_position = get_parent().transform_point(p.p)-OFFSET
	if p.ls != INF:
		$LeftSlope.rect_position = $LeftSlope.distance*(get_parent().rect_size*Vector2(1.0, -p.ls)).normalized()
	if p.rs != INF:
		$RightSlope.rect_position = $RightSlope.distance*(get_parent().rect_size*Vector2(1.0, -p.rs)).normalized()

func set_constraint(x : float, X : float, y : float, Y : float) -> void:
	min_x = x
	max_x = X
	min_y = y
	max_y = Y

func _on_ControlPoint_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				moving = true
			else:
				moving = false
				get_parent().update_controls()
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			emit_signal("removed", get_index())
	elif moving and event is InputEventMouseMotion:
		rect_position += event.relative
		if rect_position.x < min_x:
			rect_position.x = min_x
		elif rect_position.x > max_x:
			rect_position.x = max_x
		if rect_position.y < min_y:
			rect_position.y = min_y
		elif rect_position.y > max_y:
			rect_position.y = max_y
		emit_signal("moved", get_index())

func update_tangents() -> void:
	update()
	emit_signal("moved", get_index())
