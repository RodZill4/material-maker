tool
extends MMGenBase
class_name MMGenRemote

"""
Remote can be used to control parameters from several generators in the same graph
"""

var widgets = null

func set_widgets(w):
	widgets = w
	var i = 0
	for w in widgets:
		var param_name = "param"+str(i)
		if !parameters.has(param_name):
			parameters["param"+str(i)] = 0
		i += 1

func get_type():
	return "remote"

func get_type_name():
	return "Remote"

func get_parameter_defs():
	var rv = []
	var i = 0
	for w in widgets:
		match w.type:
			"config_control":
				var p = { name="param"+str(i), label=w.label, type="enum", values=[] }
				var configurations = w.configurations.keys()
				configurations.sort()
				for c in configurations:
					p.values.push_back({ name=c, value=c })
				rv.append(p)
				i += 1
			"linked_control":
				var linked = w.linked_widgets[0]
				var gen = get_parent().get_node(linked.node)
				if gen != null:
					var gen_params = gen.get_parameter_defs()
					for pd in gen_params:
						if pd.name == linked.widget:
							var p = pd.duplicate(true)
							p.name = "param"+str(i)
							p.label = w.label
							rv.append(p)
							break
				i += 1
			_:
				print(w.type)
	return rv

func set_parameter(p, v):
	var parent = get_parent()
	var param_index = p.trim_prefix("param").to_int()
	var widget = widgets[param_index]
	match widget.type:
		"linked_control":
			for w in widget.linked_widgets:
				parent.get_node(w.node).set_parameter(w.widget, v)
		"config_control":
			if v < widget.configurations.size():
				var configurations = widget.configurations.keys()
				configurations.sort()
				for w in widget.configurations[configurations[v]]:
					var node = parent.get_node(w.node)
					if node != null:
						print(w.value)
						print(MMType.deserialize_value(w.value))
						node.set_parameter(w.widget, MMType.deserialize_value(w.value))
			else:
				# incorrect configuration index
				print("error: incorrect config control parameter value")
				return
	.set_parameter(p, v)
	if name == "gen_parameters":
		get_parent().parameters[p] = v

func _serialize(data):
	data.type = "remote"
	data.widgets = widgets
	return data

func create_linked_control(label):
	var index = widgets.size()
	widgets.push_back({ label=label, type="linked_control", linked_widgets=[] })
	return index

func create_config_control(label):
	var index = widgets.size()
	widgets.push_back({ label=label, type="config_control", linked_widgets=[], configurations={} })
	return index

func can_link_parameter(index, generator, param):
	return true
	
func link_parameter(index, generator, param):
	if !can_link_parameter(index, generator, param):
		return
	var widget = widgets[index]
	widget.linked_widgets.push_back({ node=generator.name, widget=param })
	if widget.linked_widgets.size() == 1:
		match widget.type:
			"linked_control":
				parameters["param"+str(index)] = generator.parameters[param]
			"config_control":
				parameters["param"+str(index)] = 0
	emit_signal("parameter_changed", "", null)

func remove_parameter(index):
	for i in range(index, widgets.size()-2):
		parameters["param"+str(i)] = parameters["param"+str(i+1)]
	widgets.remove(index)
	emit_signal("parameter_changed", "", null)

func add_configuration(index, config_name):
	var widget = widgets[index]
	if widget.type == "config_control":
		widget.configurations[config_name] = []
		var configurations = widget.configurations.keys()
		configurations.sort()
		parameters["param"+str(index)] =configurations.find(config_name)
		update_configuration(index, config_name)

func update_configuration(index, config_name):
	var widget = widgets[index]
	if widget.type == "config_control":
		var c = []
		var parent = get_parent()
		for w in widget.linked_widgets:
			var g = parent.get_node(w.node)
			if g != null:
				print(g.parameters[w.widget])
				var value = MMType.serialize_value(g.parameters[w.widget])
				print(value)
				c.push_back({ node=w.node, widget=w.widget, value=value })
		widget.configurations[config_name] = c
		emit_signal("parameter_changed", "", null)

func remove_configuration(index, config_name):
	var widget = widgets[index]
	if widget.type == "config_control":
		widget.configurations.erase(config_name)
		emit_signal("parameter_changed", "", null)
