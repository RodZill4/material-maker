extends Control

@export var distance : float

var moving = false
var hovering : bool = false
var is_selected : bool = false

const OFFSET = -Vector2(0, 0)

func _ready() -> void:
	if OS.get_name() == "Android":
		offset_transform_scale = Vector2(2.5, 2.5)
		offset_transform_visual_only = false
		offset_transform_enabled = true

func _draw() -> void:
	var current_theme : Theme = mm_globals.main_window.theme
	var color : Color = current_theme.get_color("font_color", "Label")
	var selected_color : Color = current_theme.get_color("icon_pressed_color", "Button")
	var adjusted_scale : float = offset_transform_scale.x
	draw_circle(custom_minimum_size*0.5, 3.0 / adjusted_scale, selected_color if is_selected else color)
	if hovering or is_selected:
		draw_circle(custom_minimum_size*0.5, 6.0 / adjusted_scale, color, false, 0.5 / adjusted_scale, true)

func _on_ControlPoint_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_selected = true
				queue_redraw()
				if event.double_click:
					var parent = get_parent()
					var vector : Vector2
					if get_index() == 0:
						vector = parent.position-parent.get_parent().get_child(parent.get_index()-1).position
					else:
						vector = parent.get_parent().get_child(parent.get_index()+1).position-parent.position
					vector = distance*vector.normalized()
					position = vector-OFFSET
					if not event.shift_pressed:
						get_parent().get_child(1-get_index()).position = -vector-OFFSET
					get_parent().update_tangents()
				else:
					moving = true
			else:
				is_selected = false
				queue_redraw()
				moving = false
	elif moving and event is InputEventMouseMotion:
		var vector = get_global_mouse_position()-get_parent().get_global_rect().position+OFFSET
		vector *= sign(vector.x)
		vector = distance*vector.normalized()
		position = vector-OFFSET
		if not event.shift_pressed:
			get_parent().get_child(1-get_index()).position = -vector-OFFSET
		get_parent().update_tangents()


func _on_mouse_entered() -> void:
	hovering = true
	queue_redraw()


func _on_mouse_exited() -> void:
	hovering = false
	queue_redraw()
