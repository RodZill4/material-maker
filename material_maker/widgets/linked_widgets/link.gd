extends Control
class_name MMNodeLink

var end
var source = null
var target = null

var node = null
var param_name : String = ""
var creating : bool = false

func _init(parent):
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	size = parent.size
	clip_contents = true
	parent.add_child(self)

func pick(s, n, pn : String, c : bool = false) -> void:
	source = s
	end = source.get_global_transform() * 0.5*source.size * get_global_transform()
	node = n
	param_name = pn
	creating = c
	set_process_input(true)

func show_link(s, t) -> void:
	set_process_input(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	source = s
	target = t
	queue_redraw()

func closest(rect, point) -> Vector2:
	return Vector2(max(rect.position.x, min(rect.end.x, point.x)), max(rect.position.y, min(rect.end.y, point.y)))

func find_control(gp) -> Dictionary:
	for c in get_parent().get_children():
		if c is GraphNode:
			if c.get("controls") != null:
				for w in c.controls:
					var widget = c.controls[w]
					if is_instance_valid(widget) and Rect2(widget.global_position, widget.size*widget.get_global_transform().get_scale()).has_point(gp):
						return { node=c, widget=widget }
	return {}

func _draw() -> void:
	if ! ( is_instance_valid(source) and is_instance_valid(self) ):
		return
	var start = source.get_global_transform() * 0.5*source.size * get_global_transform()
	var color = Color(1, 0.5, 0.5, 0.5)
	var rect
	if target != null:
		color = Color(0.5, 1, 0.5, 0.5)
		rect = target.get_global_transform() * Rect2(Vector2(0, 0), target.size) * get_global_transform()
		draw_rect(rect, color, false, 2)
		end = closest(rect, start)
	rect = source.get_global_transform() * Rect2(Vector2(0, 0), source.size) * get_global_transform()
	draw_rect(rect, color, false, 2)
	start = closest(rect, end)
	draw_line(start,end,color,1.5)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		set_process_input(false)
		queue_free()
		node.generator.remove_parameter(param_name)
		get_viewport().set_input_as_handled()
		return
	elif event is InputEventMouseMotion:
		var mouse_global_position = get_global_mouse_position()
		var control = find_control(mouse_global_position)
		end = mouse_global_position * get_global_transform()
		target = control.widget if control != null and !control.is_empty() and node.generator.can_link_parameter(param_name, control.node.generator, control.widget.name) else null
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var control = find_control(get_global_mouse_position())
				if !control.is_empty():
					node.link_parameter(param_name, control.node.generator, control.widget.name)
				elif creating:
					node.generator.remove_parameter(param_name)
				set_process_input(false)
				queue_free()
				get_viewport().set_input_as_handled()
				return
	queue_redraw.call_deferred()
