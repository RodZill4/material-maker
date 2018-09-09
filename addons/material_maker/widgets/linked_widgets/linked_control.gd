tool
extends "res://addons/material_maker/widgets/linked_widgets/linked_control_base.gd"

func add_linked(node, widget):
	if linked_widgets.empty():
		var new_widget = null
		var type
		if widget is SpinBox:
			new_widget = SpinBox.new()
			type = "SpinBox"
		elif widget is ColorPickerButton:
			new_widget = ColorPickerButton.new()
			type = "ColorPickerButton"
		elif widget is Control && widget.filename == "res://addons/material_maker/widgets/gradient_editor.tscn":
			new_widget = preload("res://addons/material_maker/widgets/gradient_editor.tscn").instance()
			type = "GradientEditor"
		elif widget is HSlider:
			new_widget = HSlider.new()
			type = "HSlider"
		elif widget is OptionButton:
			new_widget = OptionButton.new()
			type = "OptionButton"
			for i in range(widget.get_item_count()):
				new_widget.add_item(widget.get_item_text(i), widget.get_item_id(i))
		if new_widget != null:
			add_child(new_widget)
			mirror(new_widget, widget, type)
			new_widget.connect("mouse_entered", self, "_on_mouse_entered")
			new_widget.connect("mouse_exited", self, "_on_mouse_exited")
			new_widget.connect(WIDGETS[type].sig, self, WIDGETS[type].sig_handler)
	linked_widgets.append({ node=node, widget=widget })

func mirror(to, from, type):
	for a in WIDGETS[type].attrs:
		to.set(a, from.get(a))

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
