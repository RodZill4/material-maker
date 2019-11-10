tool
extends Control
class_name MMGradientEditor

class GradientCursor:
	extends Control

	var color : Color

	const WIDTH : int = 10

	func _ready() -> void:
		rect_position = Vector2(0, 15)
		rect_size = Vector2(WIDTH, 15)

	func _draw() -> void:
		var polygon : PoolVector2Array = PoolVector2Array([Vector2(0, 5), Vector2(WIDTH/2, 0), Vector2(WIDTH, 5), Vector2(WIDTH, 15), Vector2(0, 15)])
		var c = color
		c.a = 1.0
		draw_colored_polygon(polygon, c)

	func _gui_input(ev) -> void:
		if ev is InputEventMouseButton:
			if ev.button_index == BUTTON_LEFT && ev.doubleclick:
				get_parent().select_color(self, ev.global_position)
			elif ev.button_index == BUTTON_RIGHT && get_parent().get_sorted_cursors().size() > 2:
				var parent = get_parent()
				parent.remove_child(self)
				parent.update_value()
				queue_free()
		elif ev is InputEventMouseMotion && (ev.button_mask & 1) != 0:
			rect_position.x += ev.relative.x
			rect_position.x = min(max(0, rect_position.x), get_parent().rect_size.x-rect_size.x)
			get_parent().update_value()

	func get_position() -> Vector2:
		return rect_position.x / (get_parent().rect_size.x - WIDTH)

	func set_color(c) -> void:
		color = c
		get_parent().update_value()
		update()

	static func sort(a, b) -> bool:
		return a.get_position() < b.get_position()

var value = null setget set_value
export var embedded : bool = true

signal updated(value)

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

func get_drag_data(position : Vector2):
	var data = MMType.serialize_value(value)
	var preview = ColorRect.new()
	preview.rect_size = Vector2(64, 24)
	preview.material = $Gradient.material
	set_drag_preview(preview)
	return data

func can_drop_data(position : Vector2, data) -> bool:
	return get_gradient_from_data(data) != null

func drop_data(position : Vector2, data) -> void:
	var gradient = get_gradient_from_data(data)
	if gradient != null:
		set_value(MMType.deserialize_value(gradient))

func set_value(v) -> void:
	value = v
	for c in get_children():
		if c is GradientCursor:
			remove_child(c)
			c.free()
	for p in value.points:
		add_cursor(p.v*(rect_size.x-GradientCursor.WIDTH), p.c)
	$Interpolation.selected = value.interpolation
	update_shader()

func update_value() -> void:
	value.clear()
	for c in get_children():
		if c is GradientCursor:
			value.add_point(c.rect_position.x/(rect_size.x-GradientCursor.WIDTH), c.color)
	update_shader()

func add_cursor(x, color) -> void:
	var cursor = GradientCursor.new()
	add_child(cursor)
	cursor.rect_position.x = x
	cursor.color = color

func _gui_input(ev) -> void:
	if ev is InputEventMouseButton && ev.button_index == 1 && ev.doubleclick:
		if ev.position.y > 15:
			var p = clamp(ev.position.x, 0, rect_size.x-GradientCursor.WIDTH)
			add_cursor(p, get_gradient_color(p))
			update_value()
		elif embedded:
			var popup = load("res://addons/material_maker/widgets/gradient_popup.tscn").instance()
			add_child(popup)
			var popup_size = popup.rect_size
			popup.popup(Rect2(ev.global_position, Vector2(0, 0)))
			popup.set_global_position(ev.global_position-Vector2(popup_size.x / 2, popup_size.y))
			popup.init(value)
			popup.connect("updated", self, "set_value")

# Showing a color picker popup to change a cursor's color

var active_cursor

func select_color(cursor, position) -> void:
	active_cursor = cursor
	$Gradient/Popup/ColorPicker.color = cursor.color
	$Gradient/Popup/ColorPicker.connect("color_changed", cursor, "set_color")
	$Gradient/Popup.rect_position = position
	$Gradient/Popup.popup()

func _on_Popup_popup_hide() -> void:
	$Gradient/Popup/ColorPicker.disconnect("color_changed", active_cursor, "set_color")

# Calculating a color from the gradient and generating the shader

func get_sorted_cursors() -> Array:
	var array = []
	for c in get_children():
		if c is GradientCursor:
			array.append(c)
	array.sort_custom(GradientCursor, "sort")
	return array

func get_gradient_color(x) -> Color:
	return value.get_color(x / (rect_size.x - GradientCursor.WIDTH))

func update_shader() -> void:
	var shader
	shader  = "shader_type canvas_item;\n"
	shader += value.get_shader("gradient")
	shader += "void fragment() { COLOR = gradient(UV.x); }"
	$Gradient.material.shader.set_code(shader)
	emit_signal("updated", value)

func _on_Interpolation_item_selected(ID) -> void:
	value.interpolation = ID
	update_shader()
