extends Control

class GradientCursor:
	extends Control

	var color : Color
	var sliding : bool = false

	@onready var label : Label = get_parent().get_node("Value")

	const WIDTH : int = 10

	func _ready() -> void:
		position = Vector2(0, 15)
		size = Vector2(WIDTH, 15)

	func _draw() -> void:
# warning-ignore:integer_division
		var polygon : PackedVector2Array = PackedVector2Array([Vector2(0, 5), Vector2(WIDTH/2, 0), Vector2(WIDTH, 5), Vector2(WIDTH, 15), Vector2(0, 15), Vector2(0, 5)])
		var c = color
		c.a = 1.0
		draw_colored_polygon(polygon, c)
		draw_polyline(polygon, Color(0.0, 0.0, 0.0) if color.v > 0.5 else Color(1.0, 1.0, 1.0))

	func _gui_input(ev : InputEvent) -> void:
		if ev is InputEventMouseButton:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.double_click:
					get_parent().select_color(self, ev.global_position)
				elif ev.pressed:
					get_parent().continuous_change = false
					sliding = true
					label.visible = true
					label.text = "%.03f" % get_caret_column()
				else:
					sliding = false
					label.visible = false
			elif ev.button_index == MOUSE_BUTTON_RIGHT and get_parent().get_sorted_cursors().size() > 2:
				var parent = get_parent()
				parent.remove_child(self)
				parent.continuous_change = false
				parent.update_from_value()
				queue_free()
		elif ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and sliding:
			position.x += get_local_mouse_position().x
			if ev.is_command_or_control_pressed():
				position.x = round(get_caret_column()*20.0)*0.05*(get_parent().size.x - WIDTH)
			position.x = min(max(0, position.x), get_parent().size.x-size.x)
			get_parent().update_from_value()
			label.text = "%.03f" % get_caret_column()

	func get_caret_column() -> float:
		return position.x / (get_parent().size.x - WIDTH)

	func set_color(c) -> void:
		color = c
		get_parent().update_from_value()
		queue_redraw()

	static func sort(a, b) -> bool:
		return a.get_position() < b.get_position()

	func _can_drop_data(_position, data) -> bool:
		return typeof(data) == TYPE_COLOR

	func _drop_data(_position, data) -> void:
		set_color(data)


var actual_value : MMGradient = null
var value : MMGradient = null :
	get:
		return actual_value
	set(new_value):
		set_value(new_value)
@export var embedded : bool = true

var continuous_change = true
var popup = null

signal updated(value, cc)


func _ready() -> void:
	$Gradient.material = $Gradient.material.duplicate(true)
	set_value(MMGradient.new())

func get_gradient_from_data(data):
	if typeof(data) == TYPE_ARRAY:
		return data
	elif typeof(data) == TYPE_DICTIONARY:
		if data.has("parameters") and data.parameters.has("gradient"):
			return data.parameters.gradient
		if data.has("type") and data.type == "Gradient":
			return data
	return null

func _get_drag_data(_position : Vector2):
	var data = MMType.serialize_value(value)
	var preview = ColorRect.new()
	preview.size = Vector2(64, 24)
	preview.material = $Gradient.material
	set_drag_preview(preview)
	return data

func _can_drop_data(_position : Vector2, data) -> bool:
	return get_gradient_from_data(data) != null

func _drop_data(_position : Vector2, data) -> void:
	var gradient = get_gradient_from_data(data)
	if gradient != null:
		set_value_and_update(MMType.deserialize_value(gradient), false)

func set_value(v : MMGradient, from_popup : bool = false) -> void:
	actual_value = v
	for c in get_children():
		if c is GradientCursor:
			remove_child(c)
			c.free()
	for p in value.points:
		add_cursor(p.v*(size.x-GradientCursor.WIDTH), p.c)
	$Interpolation.selected = value.interpolation
	update_shader()
	if !from_popup and popup != null:
		popup.init(value)

func update_from_value() -> void:
	var cursors : Array = []
	for c in get_children():
		if c is GradientCursor:
			cursors.append(c)
	if true or cursors.size() != value.points.size():
		value.clear()
		for c in get_children():
			if c is GradientCursor:
				value.add_point(c.position.x/(size.x-GradientCursor.WIDTH), c.color)
		update_shader()
	else:
		for i in cursors.size():
			var c = cursors[i]
			var p : float = c.position.x/(size.x-GradientCursor.WIDTH)
			value.points[i].v = p
			$Gradient.material.set_shader_parameter("p__%d_pos" % i, p)
			value.points[i].c = c.color
			$Gradient.material.set_shader_parameter("p__%d_col" % i, c.color)
	emit_signal("updated", value, continuous_change)
	continuous_change = true

func set_value_and_update(v, cc : bool = true) -> void:
	if ! cc:
		continuous_change = false
	set_value(v, true)
	update_from_value()

func add_cursor(x, color) -> void:
	var cursor = GradientCursor.new()
	add_child(cursor)
	cursor.position.x = x
	cursor.color = color

func _gui_input(ev) -> void:
	if ev is InputEventMouseButton and ev.button_index == 1 and ev.double_click:
		if ev.position.y > 15:
			var p = clamp(ev.position.x, 0, size.x-GradientCursor.WIDTH)
			add_cursor(p, get_gradient_color(p))
			continuous_change = false
			update_from_value()
		elif embedded:
			popup = load("res://material_maker/widgets/gradient_editor/gradient_popup.tscn").instantiate()
			add_child(popup)
			var popup_size = popup.size
			popup.popup(Rect2(ev.global_position, Vector2(0, 0)))
			popup.set_global_position(ev.global_position-Vector2(popup_size.x / 2, popup_size.y))
			popup.init(value)
			popup.connect("updated",Callable(self,"set_value_and_update"))
			popup.connect("popup_hide",Callable(popup,"queue_free"))

# Showing a color picker popup to change a cursor's color

var active_cursor

func select_color(cursor, at_position) -> void:
	active_cursor = cursor
	var color_picker_popup = preload("res://material_maker/widgets/color_picker_popup/color_picker_popup.tscn").instantiate()
	add_child(color_picker_popup)
	var color_picker = color_picker_popup.get_node("ColorPicker")
	color_picker.color = cursor.color
	color_picker.connect("color_changed",Callable(cursor,"set_color"))
	color_picker_popup.position = at_position
	color_picker_popup.connect("popup_hide",Callable(color_picker_popup,"queue_free"))
	color_picker_popup.connect("popup_hide",Callable(self,"on_close_popup"))
	color_picker_popup.popup()

# Calculating a color from the gradient and generating the shader

func get_sorted_cursors() -> Array:
	var array = []
	for c in get_children():
		if c is GradientCursor:
			array.append(c)
	array.sort_custom(Callable(GradientCursor,"sort"))
	return array

func get_gradient_color(x) -> Color:
	return value.get_color(x / (size.x - GradientCursor.WIDTH))

func update_shader() -> void:
	var shader
	shader = "shader_type canvas_item;\n"
	shader += value.get_shader_params("")
	shader += value.get_shader("")
	shader += "void fragment() { COLOR = _gradient_fct(UV.x); }"
	$Gradient.material.shader.set_code(shader)

func _on_Interpolation_item_selected(ID) -> void:
	value.interpolation = ID
	update_shader()
	emit_signal("updated", value, false)

func _on_Control_resized():
	if value != null:
		set_value(value)

func on_close_popup():
	popup = null
