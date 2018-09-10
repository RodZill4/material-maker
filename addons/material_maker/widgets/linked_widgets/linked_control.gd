tool
extends "res://addons/material_maker/widgets/linked_widgets/linked_control_base.gd"

var control = null

func add_linked(node, widget):
	if linked_widgets.empty():
		control = null
		var type
		if widget is SpinBox:
			control = SpinBox.new()
			type = "SpinBox"
		elif widget is ColorPickerButton:
			control = ColorPickerButton.new()
			type = "ColorPickerButton"
		elif widget is Control && widget.filename == "res://addons/material_maker/widgets/gradient_editor.tscn":
			control = preload("res://addons/material_maker/widgets/gradient_editor.tscn").instance()
			type = "GradientEditor"
		elif widget is HSlider:
			control = HSlider.new()
			type = "HSlider"
		elif widget is OptionButton:
			control = OptionButton.new()
			type = "OptionButton"
			for i in range(widget.get_item_count()):
				control.add_item(widget.get_item_text(i), widget.get_item_id(i))
		if control != null:
			add_child(control)
			mirror(control, widget, type)
			control.connect("mouse_entered", self, "_on_mouse_entered")
			control.connect("mouse_exited", self, "_on_mouse_exited")
			control.connect(WIDGETS[type].sig, self, WIDGETS[type].sig_handler)
	else:
		if !can_link_to(widget):
			return
	linked_widgets.append({ node=node, widget=widget })

func can_link_to(c):
	if c == null:
		return false
	var widget_type = get_widget_type(c)
	if control == null:
		return widget_type != null
	elif widget_type != get_widget_type(control):
		return false
	else:
		for l in linked_widgets:
			if l.widget == c:
				return false
		var winfo = WIDGETS[widget_type]
		for a in winfo.attrs:
			if c.get(a) != control.get(a):
				return false
	return true

func mirror(to, from, type):
	var winfo = WIDGETS[type]
	for a in winfo.attrs:
		to.set(a, from.get(a))
	to.set(winfo.value_attr, from.get(winfo.value_attr))

func update_shaders():
	var graph_edit = get_parent()
	while !(graph_edit is GraphEdit):
		graph_edit = graph_edit.get_parent()
	graph_edit.send_changed_signal()

func _on_value_changed(v):
	for l in linked_widgets:
		l.widget.value = v
		l.node.set(l.widget.name, v)
	update_shaders()

func _on_color_changed(c):
	for l in linked_widgets:
		l.widget.color = c
		l.node.set(l.widget.name, c)
	update_shaders()

func _on_item_selected(i):
	for l in linked_widgets:
		l.widget.selected = i
		l.node.set(l.widget.name, i)
	update_shaders()

func _on_gradient_updated(g):
	for l in linked_widgets:
		l.widget.value = g
	update_shaders()

func serialize():
	var data = .serialize()
	data.type = "linked_control"
	return data
