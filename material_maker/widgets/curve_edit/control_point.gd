extends Control

var moving : bool = false
var hovering : bool = false
var is_selected : bool = false

var min_x : float
var max_x : float
var min_y : float
var max_y : float

const OFFSET : Vector2 = Vector2(4, 4)

signal moved(index)
signal removed(index)
signal selected(index)

func _ready():
	pass # Replace with function body.

func _draw():
	var current_theme : Theme = mm_globals.main_window.theme
	var color : Color = current_theme.get_color("font_color", "Label")
	var selected_color : Color = current_theme.get_color("icon_pressed_color", "Button")
	for c in get_children():
		if c.visible:
			draw_line(OFFSET, c.position+OFFSET, color, 0.5, true)
	draw_rect(Rect2(Vector2.ZERO, custom_minimum_size), selected_color if is_selected else color, true)
	draw_rect(Rect2(Vector2.ZERO, custom_minimum_size), color.inverted(), false)
	if hovering or moving:
		draw_rect(Rect2(-custom_minimum_size * 0.5, custom_minimum_size * 2.0), color, false, 1.0)
		draw_rect(Rect2(-custom_minimum_size*0.5-Vector2(1.0,1.0),
					custom_minimum_size*2.0+Vector2(2.0,2.0)), color.inverted(), false, 1.0)

func initialize(p : MMCurve.Point) -> void:
	position = get_parent().transform_point(p.p)-OFFSET
	if p.ls != INF:
		$LeftSlope.position = $LeftSlope.distance*(get_parent().size*Vector2(1.0, -p.ls)).normalized()
	if p.rs != INF:
		$RightSlope.position = $RightSlope.distance*(get_parent().size*Vector2(1.0, -p.rs)).normalized()

func set_constraint(x : float, X : float, y : float, Y : float) -> void:
	min_x = x
	max_x = X
	min_y = y
	max_y = Y

func _on_ControlPoint_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				moving = true
				is_selected = true
				emit_signal("selected", get_index())
				queue_redraw()
			else:
				moving = false
				is_selected = false
				queue_redraw()
				get_parent().update_controls()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			emit_signal("removed", get_index())
	elif moving and event is InputEventMouseMotion:
		var new_pos : Vector2 = position + event.relative
		if event.is_command_or_control_pressed():
			if get_parent().axes_density > 1.0:
				var snap : float = 1.0 / (get_parent().axes_density - 1.0)
				new_pos = position + (event.position - custom_minimum_size / 2.0)
				new_pos /= get_parent_control().size
				new_pos = snapped(new_pos, Vector2(snap, snap))
				new_pos *= get_parent_control().size
				new_pos -= custom_minimum_size/2.0
		position = new_pos
		if position.x < min_x:
			position.x = min_x
		elif position.x > max_x:
			position.x = max_x
		if position.y < min_y:
			position.y = min_y
		elif position.y > max_y:
			position.y = max_y
		emit_signal("moved", get_index())

func update_tangents() -> void:
	queue_redraw()
	emit_signal("moved", get_index())
	emit_signal("selected", get_index())


func _on_mouse_entered() -> void:
	queue_redraw()
	hovering = true


func _on_mouse_exited() -> void:
	queue_redraw()
	hovering = false
