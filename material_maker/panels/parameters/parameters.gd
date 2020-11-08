extends GridContainer

const GENERIC = preload("res://material_maker/nodes/generic/generic.gd")

var controls : Dictionary = {}
var generator = null
var ignore_parameter_change = ""

func _ready():
	pass

func set_generator(g):
	if g != generator:
		if generator != null:
			generator.disconnect("parameter_changed", self, "on_parameter_changed")
		generator = g
		if generator != null:
			generator.connect("parameter_changed", self, "on_parameter_changed")
	for c in get_children():
		remove_child(c)
		c.free()
	controls = {}
	if generator != null:
		for p in generator.get_parameter_defs():
			var label : Label = Label.new()
			label.text = p.label if p.has("label") else ""
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			add_child(label)
			var control = GENERIC.create_parameter_control(p, false)
			control.name = p.name
			control.size_flags_horizontal = SIZE_FILL
			add_child(control)
			controls[p.name] = control
		GENERIC.initialize_controls_from_generator(controls, generator, self)

func on_parameter_changed(p : String, v) -> void:
	if ignore_parameter_change == p:
		return
	if p == "__update_all__":
		set_generator(generator)
	else:
		GENERIC.update_control_from_parameter(controls, p, v)

func _on_text_changed(new_text, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_text)
	ignore_parameter_change = ""

func _on_value_changed(new_value, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_value)
	ignore_parameter_change = ""

func _on_color_changed(new_color, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_color)
	ignore_parameter_change = ""

func _on_file_changed(new_file, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_file)
	ignore_parameter_change = ""

func _on_gradient_changed(new_gradient, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_gradient.duplicate())
	ignore_parameter_change = ""
