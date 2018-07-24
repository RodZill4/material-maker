tool
extends GraphNode

var generated = false
var generated_variants = []

var property_widgets = []

func _ready():
	pass

func initialize_properties(object_list):
	property_widgets = object_list
	for o in object_list:
		if o is LineEdit:
			set(o.name, float(o.text))
			o.connect("text_changed", self, "_on_text_changed", [ o.name ])
		elif o is SpinBox:
			set(o.name, o.value)
			o.connect("value_changed", self, "_on_value_changed", [ o.name ])
		elif o is ColorPickerButton:
			set(o.name, o.color)
			o.connect("color_changed", self, "_on_color_changed", [ o.name ])

func update_property_widgets():
	for o in property_widgets:
		if o is LineEdit:
			o.text = str(get(o.name))
		elif o is ColorPickerButton:
			o.color = get(o.name)

func _on_text_changed(new_text, variable):
	set(variable, float(new_text))
	get_parent().get_parent().generate_shader()

func _on_value_changed(new_value, variable):
	set(variable, new_value)
	get_parent().get_parent().generate_shader()

func _on_color_changed(new_color, variable):
	set(variable, new_color)
	get_parent().get_parent().generate_shader()

func get_source(index = 0):
	for c in get_parent().get_children():
		if c != self && c is GraphNode:
			if get_parent().is_node_connected(c.name, 0, name, index):
				return c
	return null

func get_source_f(source):
	var rv
	if source.has("rgb"):
		rv = "dot("+source.rgb+", vec3(1.0, 1.0, 1.0))"
	elif source.has("f"):
		rv = source.f
	else:
		rv = "***error***"
	return rv
	
func get_source_rgb(source):
	var rv
	if source.has("rgb"):
		rv = source.rgb
	elif source.has("f"):
		rv = "vec3("+source.f+")"
	else:
		rv = "***error***"
	return rv

func queue_free():
	get_parent().remove_node(self.name)
	.queue_free()

func serialize_element(e):
	if typeof(e) == TYPE_COLOR:
		return { type= "Color", r=e.r, g=e.g, b=e.b, a=e.a }
	return e
	
func deserialize_element(e):
	if typeof(e) == TYPE_DICTIONARY:
		if e.type == "Color":
			return Color(e.r, e.g, e.b, e.a)
	return e

func serialize():
	var type = get_script().resource_path
	type = type.right(type.find_last("/")+1)
	type = type.left(type.find_last("."))
	var data = { name=name, type=type, node_position={x=offset.x, y=offset.y} }
	for w in property_widgets:
		var v = w.name
		data[v] = serialize_element(get(v))
	return data

func deserialize(data):
	print("deserialize: "+name)
	offset = Vector2(data.node_position.x, data.node_position.y)
	for w in property_widgets:
		var v = w.name
		set(v, deserialize_element(data[v]))
		print("  "+v+" = "+str(deserialize_element(data[v])))
	update_property_widgets()
