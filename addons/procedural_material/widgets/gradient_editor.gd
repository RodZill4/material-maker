tool
extends Control

class GradientCursor:
	extends ColorRect
	
	const WIDTH = 10
	
	func _ready():
		rect_position = Vector2(0, 15)
		rect_size = Vector2(WIDTH, 20)

	func _gui_input(ev):
		if ev is InputEventMouseButton && ev.doubleclick:
			if ev.button_index == 1:
				get_parent().select_color(self, ev.global_position)
			elif ev.button_index == 2 && get_parent().get_sorted_cursors().size() > 2:
				var parent = get_parent()
				parent.remove_child(self)
				parent.update_shader()
				queue_free()
		elif ev is InputEventMouseMotion && (ev.button_mask & 1) != 0:
			rect_position.x += ev.relative.x
			rect_position.x = min(max(0, rect_position.x), get_parent().rect_size.x-rect_size.x)
			get_parent().update_shader()
	
	func get_position():
		return rect_position.x / (get_parent().rect_size.x - WIDTH)
	
	func set_color(c):
		color = c
		get_parent().update_shader()

	static func sort(a, b):
		if a.get_position() < b.get_position():
			return true
		return false

signal updated

func _ready():
	$Gradient.material = $Gradient.material.duplicate(true)
	add_cursor(0, Color(0, 0, 0))
	add_cursor(rect_size.x-GradientCursor.WIDTH, Color(1, 1, 1))

func add_cursor(x, color):
	var cursor = GradientCursor.new()
	add_child(cursor)
	cursor.rect_position.x = x
	cursor.color = color
	update_shader()

func _gui_input(ev):
	if ev is InputEventMouseButton && ev.button_index == 1 && ev.doubleclick && ev.position.y > 15:
		var p = max(0, min(ev.position.x, rect_size.x-GradientCursor.WIDTH))
		add_cursor(p, get_color(p))

# Showing a color picker popup to change a cursor's color

var active_cursor

func select_color(cursor, position):
	active_cursor = cursor
	$Gradient/Popup/ColorPicker.color = cursor.color
	$Gradient/Popup/ColorPicker.connect("color_changed", cursor, "set_color")
	$Gradient/Popup.rect_position = position
	$Gradient/Popup.popup()

func _on_Popup_popup_hide():
	$Gradient/Popup/ColorPicker.disconnect("color_changed", active_cursor, "set_color")

# Calculating a color from the gradient and generating the shader

func get_sorted_cursors():
	var array = get_children()
	array.erase($Gradient)
	array.sort_custom(GradientCursor, "sort")
	return array

func get_color(x):
	var array = get_sorted_cursors()
	x = x / (rect_size.x - array[0].rect_size.x)
	if x < array[0].get_position():
		return array[0].color
	for i in range(array.size()-1):
		if x < array[i+1].get_position():
			var p0 = array[i].get_position()
			var c0 = array[i].color
			var p1 = array[i+1].get_position()
			var c1 = array[i+1].color
			return c0 + (c1-c0) * (x-p0) / (p1-p0)
	return array[array.size()-1].color

# get_color_in_shader
func gcis(color):
	return "vec3(%.9f,%.9f,%.9f)" % [color.r, color.g, color.b]

func get_shader(name):
	var array = get_sorted_cursors()
	var shader
	shader  = "vec3 "+name+"(float x) {\n"
	shader += "  if (x < %.9f) {\n" % array[0].get_position()
	shader += "    return "+gcis(array[0].color)+";\n"
	for i in range(array.size()-1):
		var p0 = array[i].get_position()
		var c0 = array[i].color
		var p1mp0 = array[i+1].get_position()-p0
		var c1mc0 = array[i+1].color-c0
		if p1mp0 > 0:
			shader += "  } else if (x < %.9f) {\n" % array[i+1].get_position()
			shader += "    return %s+x*%s;\n" % [gcis(c0-c1mc0*(p0/p1mp0)), gcis(c1mc0/p1mp0)]
	shader += "  }\n"
	shader += "  return "+gcis(array[array.size()-1].color)+";\n"
	shader += "}\n"
	return shader

func update_shader():
	var shader
	shader  = "shader_type canvas_item;\n"
	shader += get_shader("gradient")
	shader += "void fragment() { COLOR = vec4(gradient((UV.x-%.9f)*%.9f), 1.0); }" % [ float(GradientCursor.WIDTH)*0.5/float(rect_size.x), rect_size.x/(rect_size.x-GradientCursor.WIDTH) ]
	$Gradient.material.shader.set_code(shader)
	emit_signal("updated")

func serialize():
	var rv = []
	for c in get_sorted_cursors():
		rv.append({ pos= c.get_position(), r= c.color.r, g= c.color.g, b= c.color.b })
	return rv

func deserialize(v):
	for c in get_sorted_cursors():
		remove_child(c)
		c.free()
	for i in v:
		add_cursor(i.pos*(rect_size.x-GradientCursor.WIDTH), Color(i.r, i.g, i.b))
