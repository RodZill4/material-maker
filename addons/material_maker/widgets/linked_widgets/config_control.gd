tool
extends "res://addons/material_maker/widgets/linked_widgets/linked_control_base.gd"

var configurations = {}

var current = null
onready var button = null

const Types = preload("res://addons/material_maker/types/types.gd")

func _ready():
	update_options()

func update_options():
	# Seems "clear" might cause crashes, so we create a new button...
	if button != null:
		button.hide()
		button.queue_free()
	button = OptionButton.new()
	button.connect("item_selected", self, "_on_item_selected")
	button.connect("mouse_entered", self, "_on_mouse_entered")
	button.connect("mouse_exited", self, "_on_mouse_exited")
	add_child(button)
	# Create list of configurations
	var keys = configurations.keys()
	keys.sort()
	# if no configuration is selected, select the first one
	if current == null and !keys.empty():
		current = keys[0]
	for c in keys:
		button.add_item(c)
	button.add_separator()
	button.add_item("<add configuration>")
	if current != null:
		button.add_separator()
		button.add_item("<update "+current+">")
		button.add_item("<remove "+current+">")
		for i in range(button.get_item_count()):
			if button.get_item_text(i) == current:
				button.selected = i
				break

func add_linked(node, widget):
	linked_widgets.append({ node=node, widget=widget })

func duplicate_value(value):
	if typeof(value) == TYPE_OBJECT and value.has_method("duplicate"):
		value = value.duplicate()
	return value

func apply_configuration(c):
	for w in configurations[c]:
		var value = duplicate_value(w.value)
		w.widget.set(WIDGETS[get_widget_type(w.widget)].value_attr, value)
		w.node.set(w.widget.name, value)
	var graph_node = get_parent()
	while !(graph_node is GraphNode):
		graph_node = graph_node.get_parent()
	graph_node.update_shaders()

func do_update_configuration(name):
	var configuration = []
	for w in linked_widgets:
		configuration.append({ node=w.node, widget=w.widget, value=duplicate_value(w.node.get(w.widget.name)) })
	configurations[name] = configuration
	current = name
	update_options()

func update_configuration():
	var dialog = preload("res://addons/material_maker/widgets/line_dialog.tscn").instance()
	add_child(dialog)
	dialog.set_texts("Configuration", "Enter a name for the new configuration")
	dialog.connect("ok", self, "do_update_configuration", [])
	dialog.popup_centered()

func _on_item_selected(ID):
	var count = configurations.keys().size()
	if ID >= 0 && ID < count:
		current = button.get_item_text(ID)
		update_options()
		apply_configuration(current)
	elif ID == count+1:
		button.selected = 0
		update_configuration()
	elif ID == count+3:
		do_update_configuration(current)
	else:
		configurations.erase(current)
		current = null
		update_options()

func serialize():
	var data = .serialize()
	data.type = "config_control"
	var data_configurations = {}
	var keys = configurations.keys()
	for k in keys:
		var c = configurations[k]
		var data_configuration = []
		for e in c:
			data_configuration.append({ node=e.node.name, widget=e.widget.name, value=Types.serialize_value(e.value) })
		data_configurations[k] = data_configuration
	data.configurations = data_configurations
	return data

func deserialize(data):
	.deserialize(data)
	graph_edit = get_parent()
	while graph_edit != null && !(graph_edit is GraphEdit):
		graph_edit = graph_edit.get_parent()
	if graph_edit == null:
		return
	var keys = data.configurations.keys()
	for k in keys:
		var c = data.configurations[k]
		var configuration = []
		for e in c:
			var node = graph_edit.get_node(e.node)
			var widget = null
			for w in node.property_widgets:
				if w.name == e.widget:
					widget = w
					break
			configuration.append({ node=node, widget=widget, value=Types.deserialize_value(e.value) })
		configurations[k] = configuration
	update_options()



