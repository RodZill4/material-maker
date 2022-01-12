extends Control
class_name MMNodeLink

var end
var source = null
var target = null

var node = null
var param_name: String = ""
var creating: bool = false


func _init(parent) -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	rect_size = parent.rect_size
	rect_clip_content = true
	parent.add_child(self)


func pick(s, n, pn: String, c: bool = false) -> void:
	source = s
	end = get_global_transform().xform_inv(
		source.get_global_transform().xform(0.5 * source.rect_size)
	)
	node = n
	param_name = pn
	creating = c
	set_process_input(true)


func show_link(s, t) -> void:
	set_process_input(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	source = s
	target = t
	update()


func closest(rect, point) -> Vector2:
	return Vector2(
		max(rect.position.x, min(rect.end.x, point.x)),
		max(rect.position.y, min(rect.end.y, point.y))
	)


func find_control(gp) -> Dictionary:
	for c in get_parent().get_children():
		if c is GraphNode:
			if c.get("controls") != null:
				for w in c.controls:
					var widget = c.controls[w]
					if (
						is_instance_valid(widget)
						and Rect2(widget.rect_global_position, widget.rect_size * widget.get_global_transform().get_scale()).has_point(
							gp
						)
					):
						return {node = c, widget = widget}
	return {}


func _draw() -> void:
	var start = get_global_transform().xform_inv(
		source.get_global_transform().xform(0.5 * source.rect_size)
	)
	var color = Color(1, 0.5, 0.5, 0.5)
	var rect
	if target != null:
		color = Color(0.5, 1, 0.5, 0.5)
		rect = get_global_transform().xform_inv(
			target.get_global_transform().xform(Rect2(Vector2(0, 0), target.rect_size))
		)
		draw_rect(rect, color, false, 2)
		end = closest(rect, start)
	rect = get_global_transform().xform_inv(
		source.get_global_transform().xform(Rect2(Vector2(0, 0), source.rect_size))
	)
	draw_rect(rect, color, false, 2)
	start = closest(rect, end)
	draw_line(start, end, color, 1.5, true)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		set_process_input(false)
		queue_free()
		node.generator.remove_parameter(param_name)
	if event is InputEventMouseMotion:
		var control = find_control(event.global_position)
		end = get_global_transform().xform_inv(event.global_position)
		target = (
			control.widget
			if (
				control != null
				and !control.empty()
				and node.generator.can_link_parameter(
					param_name, control.node.generator, control.widget.name
				)
			)
			else null
		)
		update()
	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				var control = find_control(event.global_position)
				if !control.empty():
					node.link_parameter(param_name, control.node.generator, control.widget.name)
				elif creating:
					node.generator.remove_parameter(param_name)
			set_process_input(false)
			queue_free()
	get_tree().set_input_as_handled()
