tool
extends Control
class_name MMNodeLink

var end
var source = null
var target = null

var generator = null
var param_name : String = ""
var creating : bool = false

func _init(parent) -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	rect_size = parent.rect_size
	rect_clip_content = true
	parent.add_child(self)

func pick(s, g, n : String, c : bool = false) -> void:
	source = s
	end = get_global_transform().xform_inv(source.get_global_transform().xform(0.5*source.rect_size))
	generator = g
	param_name = n
	creating = c
	set_process_input(true)

func show_link(s, t) -> void:
	set_process_input(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	source = s
	target = t
	update()

func closest(rect, point) -> Vector2:
	return Vector2(max(rect.position.x, min(rect.end.x, point.x)), max(rect.position.y, min(rect.end.y, point.y)))

func find_control(gp):
	for c in get_parent().get_children():
		if c is GraphNode:
			if c.get("controls") != null:
				for w in c.controls:
					var widget = c.controls[w]
					if Rect2(widget.rect_global_position, widget.rect_size*widget.get_global_transform().get_scale()).has_point(gp):
						return { node=c, widget=widget }
	return null

func _draw() -> void:
	#draw_rect(Rect2(rect_position, rect_size), Color(1.0, 0.0, 0.0, 0.2))
	#draw_rect(Rect2(rect_position, rect_size), Color(1.0, 1.0, 0.0), false)
	var start = get_global_transform().xform_inv(source.get_global_transform().xform(0.5*source.rect_size))
	var color = Color(1, 0.5, 0.5, 0.5)
	var rect
	if target != null:
		color = Color(0.5, 1, 0.5, 0.5)
		rect = get_global_transform().xform_inv(target.get_global_transform().xform(Rect2(Vector2(0, 0), target.rect_size)))
		draw_rect(rect, color, false)
		end = closest(rect, start)
	rect = get_global_transform().xform_inv(source.get_global_transform().xform(Rect2(Vector2(0, 0), source.rect_size)))
	draw_rect(rect, color, false)
	start = closest(rect, end)
	draw_line(start, end, color, 1, true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			set_process_input(false)
			queue_free()
	elif event is InputEventMouseMotion:
		var control = find_control(event.global_position)
		end = get_global_transform().xform_inv(event.global_position)
		target = control.widget if control != null and generator.can_link_parameter(param_name, control.node.generator, control.widget.name) else null
		update()
	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				var control = find_control(event.global_position)
				if control != null:
					generator.link_parameter(param_name, control.node.generator, control.widget.name)
				elif creating:
					generator.remove_parameter(param_name)
			set_process_input(false)
			queue_free()
	get_tree().set_input_as_handled()
