extends ScrollContainer

onready var parameters : GridContainer = $Parameters

const GENERIC = preload("res://material_maker/nodes/generic/generic.gd")

var controls : Dictionary = {}
var generator = null
var ignore_parameter_change = ""

func _ready():
	pass

func set_generator(g):
	if g != generator:
		if generator != null and generator.is_connected("parameter_changed", self, "on_parameter_changed"):
			generator.disconnect("parameter_changed", self, "on_parameter_changed")
		generator = g
		if generator != null:
			generator.connect("parameter_changed", self, "on_parameter_changed")
	for c in parameters.get_children():
		parameters.remove_child(c)
		c.free()
	controls = {}
	if generator != null:
		var parameter_labels = {}
		for p in generator.get_parameter_defs():
			if p.has("label"):
				parameter_labels[p.label] = p
		for p in generator.get_parameter_defs():
			if p.has("label"):
				if p.label.left(6) == "Paint " and parameter_labels.has(p.label.right(6)):
					continue
				elif parameter_labels.has("Paint "+p.label):
					var paint_parameter = parameter_labels["Paint "+p.label]
					var control = GENERIC.create_parameter_control(paint_parameter, false)
					control.name = paint_parameter.name
					if control is CheckBox:
						control.text = p.label
					parameters.add_child(control)
					controls[paint_parameter.name] = control
				else:
					var label : Label = Label.new()
					label.text = p.label if p.has("label") else ""
					label.size_flags_horizontal = SIZE_EXPAND_FILL
					parameters.add_child(label)
			else:
				p.add_child(Control.new())
			var control = GENERIC.create_parameter_control(p, false)
			control.name = p.name
			control.size_flags_horizontal = SIZE_FILL
			parameters.add_child(control)
			controls[p.name] = control
		GENERIC.initialize_controls_from_generator(controls, generator, self)
	set_size(get_size()-Vector2(1.0, 1.0))
	set_size(get_size())

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

func _on_float_value_changed(new_value, merge_undo : bool = false, variable : String = "") -> void:
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
