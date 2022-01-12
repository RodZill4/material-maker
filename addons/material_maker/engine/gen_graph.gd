tool
extends MMGenBase
class_name MMGenGraph

var label: String = "Graph"
var shortdesc = ""
var longdesc = ""
var connections = []

var editable: bool = false

var transmits_seed: bool = true

signal graph_changed
signal connections_changed(removed_connections, added_connections)
signal hierarchy_changed


func emit_hierarchy_changed():
	var top = self
	while top.get_parent() != null and top.get_parent().get_script() == get_script():
		top = top.get_parent()
	top.emit_signal("hierarchy_changed")


func fix_remotes() -> void:
	for c in get_children():
		if c is MMGenRemote:
			c.fix()


func _post_load() -> void:
	fix_remotes()


func has_randomness() -> bool:
	if !transmits_seed:
		return false
	for c in get_children():
		if c.has_randomness() and !c.is_seed_locked():
			return true
	return false


func set_position(p, force_recalc_seed = false) -> void:
	position = p


func set_seed(s: float) -> bool:
	if .set_seed(s) and transmits_seed:
		for c in get_children():
			if c is MMGenBase:
				c.set_seed(c.seed_value)
		return true
	return false


func get_type() -> String:
	return "graph"


func get_type_name() -> String:
	return label


func set_type_name(l) -> void:
	if l != label:
		label = l
		emit_hierarchy_changed()


func toggle_editable() -> bool:
	editable = !editable
	if editable:
		model = null
	return true


func is_editable() -> bool:
	return editable


func get_description() -> String:
	var desc_list: PoolStringArray = PoolStringArray()
	if shortdesc == "":
		desc_list.push_back(TranslationServer.translate(shortdesc))
	if longdesc == "":
		desc_list.push_back(TranslationServer.translate(longdesc))
	return desc_list.join("\n")


func get_parameter_defs() -> Array:
	if has_node("gen_parameters"):
		return get_node("gen_parameters").get_parameter_defs()
	return []


func set_parameter(n: String, v) -> void:
	.set_parameter(n, v)
	if has_node("gen_parameters"):
		get_node("gen_parameters").set_parameter(n, v)


func get_input_defs() -> Array:
	if has_node("gen_inputs"):
		return get_node("gen_inputs").get_output_defs()
	return []


func get_output_defs(_show_hidden: bool = false) -> Array:
	if has_node("gen_outputs"):
		return get_node("gen_outputs").get_input_defs()
	return []


func source_changed(input_index: int) -> void:
	if has_node("gen_inputs"):
		get_node("gen_inputs").source_changed(input_index)


func all_sources_changed() -> void:
	if has_node("gen_inputs"):
		var inputs = get_node("gen_inputs")
		for i in inputs.get_input_defs().size():
			inputs.source_changed(i)


func get_port_source(gen_name: String, input_index: int) -> OutputPort:
	var rv = null
	if gen_name == "gen_inputs":
		var parent = get_parent()
		if parent != null and parent.get_script() == get_script():
			rv = parent.get_port_source(name, input_index)
	else:
		for c in connections:
			if c.to == gen_name and c.to_port == input_index:
				var src_gen = get_node(c.from)
				if src_gen != null:
					if src_gen.get_script() == get_script():
						rv = src_gen.get_port_source("gen_outputs", c.from_port)
					else:
						rv = OutputPort.new(src_gen, c.from_port)
	if rv != null and rv.generator.name == "gen_inputs":
		rv = get_port_source("gen_inputs", rv.output_index)
	return rv


func get_port_targets(gen_name: String, output_index: int) -> Array:
	var rv = []
	for c in connections:
		if c.from == gen_name and c.from_port == output_index:
			var tgt_gen = get_node(c.to)
			if tgt_gen != null:
				rv.push_back(InputPort.new(tgt_gen, c.to_port))
	return rv


func add_generator(generator: MMGenBase) -> bool:
	var name = generator.name
	if generator.name == "Material" or generator.name == "Brush":
		if has_node(generator.name):
			# Cannot create a material if it exists already
			return false
		else:
			var parent = get_parent()
			if parent != null and parent is Object and parent.get_script() == get_script():
				# Material is always in top level graph
				return false
	elif name == "":
		name = generator.get_type() + "_1"
	if has_node(name):
		var name_prefix: String
		var regex = RegEx.new()
		regex.compile("^(.*_)\\d+$")
		var result = regex.search(generator.name)
		if result:
			name_prefix = result.get_string(1)
		else:
			name_prefix = generator.name + "_"
		var index = 1
		while has_node(name):
			index += 1
			name = name_prefix + str(index)
	generator.name = name
	add_child(generator)
	if generator.get_script() == get_script():
		emit_hierarchy_changed()
	emit_signal("graph_changed")
	return true


func remove_generator(generator: MMGenBase) -> bool:
	if !generator.can_be_deleted():
		return false
	var new_connections = []
	var old_connections = []
	for c in connections:
		if c.from == generator.name:
			old_connections.append(c)
		elif c.to != generator.name:
			new_connections.append(c)
	connections = new_connections
	# Notify target nodes that their input vanished
	for c in old_connections:
		get_node(c.to).source_changed(c.to_port)
	remove_child(generator)
	fix_remotes()
	if generator.get_script() == get_script():
		emit_hierarchy_changed()
	generator.queue_free()
	emit_signal("graph_changed")
	return true


func replace_generator(old: MMGenBase, new: MMGenBase) -> void:
	new.name = old.name
	new.position = old.position
	remove_child(old)
	add_child(new)
	if old.get_script() == get_script() or new.get_script() == get_script():
		emit_hierarchy_changed()
	old.free()
	emit_signal("graph_changed")


func get_connected_inputs(generator) -> Array:
	var rv: Array = []
	for c in connections:
		if c.to == generator.name:
			rv.push_back(c.to_port)
	return rv


func get_connected_outputs(generator) -> Array:
	var rv: Array = []
	for c in connections:
		if c.from == generator.name:
			rv.push_back(c.from_port)
	return rv


func connect_children(from, from_port: int, to, to_port: int) -> bool:
	# check the new connection does not create a loop
	var spreadlist = [InputPort.new(to, to_port)]
	while !spreadlist.empty():
		var input: InputPort = spreadlist.pop_front()
		for o in input.generator.follow_input(input.input_index):
			if o.generator == from and o.output_index == from_port:
				return false
			for t in o.generator.get_parent().get_port_targets(o.generator.name, o.output_index):
				spreadlist.push_back(t)
	# disconnect target
	while true:
		var remove = -1
		for i in connections.size():
			if connections[i].to == to.name and connections[i].to_port == to_port:
				remove = i
				break
		if remove == -1:
			break
		connections.remove(remove)
	# create new connection
	connections.append({from = from.name, from_port = from_port, to = to.name, to_port = to_port})
	to.source_changed(to_port)
	return true


func disconnect_children_ext(from_name: String, from_port: int, to_name: String, to, to_port: int) -> bool:
	var new_connections: Array = []
	for c in connections:
		if (
			c.from != from_name
			or c.from_port != from_port
			or c.to != to_name
			or c.to_port != to_port
		):
			new_connections.push_back(c)
		else:
			to.source_changed(to_port)
	connections = new_connections
	return true


func disconnect_children_by_name(from_name: String, from_port: int, to_name: String, to_port: int) -> bool:
	return disconnect_children_ext(from_name, from_port, to_name, get_node(to_name), to_port)


func disconnect_children(from, from_port: int, to, to_port: int) -> bool:
	return disconnect_children_ext(from.name, from_port, to.name, to, to_port)


func reconnect_inputs(generator, reconnects: Dictionary) -> bool:
	var new_connections: Array = []
	var added_connections: Array = []
	var removed_connections: Array = []
	for c in connections:
		if c.to == generator.name and reconnects.has(c.to_port):
			removed_connections.push_back(c.duplicate(true))
			if reconnects[c.to_port] < 0:
				continue
			c.to_port = reconnects[c.to_port]
			added_connections.push_back(c.duplicate(true))
		new_connections.push_back(c)
	connections = new_connections
	if !removed_connections.empty():
		emit_signal("connections_changed", removed_connections, added_connections)
	return true


func reconnect_outputs(generator, reconnects: Dictionary) -> bool:
	var new_connections: Array = []
	var added_connections: Array = []
	var removed_connections: Array = []
	for c in connections:
		if c.from == generator.name and reconnects.has(c.from_port):
			removed_connections.push_back(c.duplicate(true))
			if reconnects[c.from_port] < 0:
				continue
			c.from_port = reconnects[c.from_port]
			added_connections.push_back(c.duplicate(true))
		new_connections.push_back(c)
	connections = new_connections
	if !removed_connections.empty():
		emit_signal("connections_changed", removed_connections, added_connections)
	return true


func get_named_parameters() -> Dictionary:
	var named_parameters: Dictionary = {}
	for c in get_children():
		if c is MMGenRemote:
			var remote_named_parameters = c.get_named_parameters()
			for k in remote_named_parameters.keys():
				named_parameters[k] = {id = remote_named_parameters[k], value = c.get_parameter(k)}
	return named_parameters


func get_globals() -> String:
	var globals: String = ""
	for c in get_children():
		if c is MMGenRemote:
			globals += c.get_globals()
	return globals


func _get_shader_code(uv: String, output_index: int, context: MMGenContext) -> Dictionary:
	var outputs = get_node("gen_outputs")
	if outputs != null:
		var rv = outputs._get_shader_code(uv, output_index, context)
		while rv is GDScriptFunctionState:
			print("This should never NEVER happen")
			rv = yield(rv, "completed")
		return rv
	return {globals = [], defs = "", code = "", textures = {}}


func edit(node) -> void:
	node.get_parent().call_deferred("update_view", self)


func check_input_connects(node) -> void:
	var new_connections: Array = []
	var removed_connections: Array = []
	for c in connections:
		if c.to == node.name:
			if c.to_port >= node.get_input_defs().size():
				removed_connections.push_back(c.duplicate(true))
				continue
			var input_type = node.get_input_defs()[c.to_port].type
			var output_type = get_node(c.from).get_output_defs()[c.from_port].type
			if (
				mm_io_types.types[input_type].slot_type != mm_io_types.types[output_type].slot_type
				and mm_io_types.types[output_type].slot_type != 42
			):
				removed_connections.push_back(c.duplicate(true))
				continue
		new_connections.push_back(c)
	if !removed_connections.empty():
		emit_signal("connections_changed", removed_connections, [])
		connections = new_connections


func create_subgraph(gens: Array) -> MMGenGraph:
	# Remove material, gen_inputs and gen_outputs nodes
	var generators = []
	var center = Vector2(0, 0)
	var left_bound = 65535
	var right_bound = -65536
	var upper_bound = 65536
	var count = 0
	# Filter group nodes and calculate boundin box
	for g in gens:
		if (
			g.name != "Material"
			and g.name != "Brush"
			and g.name != "gen_inputs"
			and g.name != "gen_outputs"
		):
			generators.push_back(g)
			var p = g.position
			center += p
			count += 1
			if left_bound > p.x:
				left_bound = p.x
			if right_bound < p.x:
				right_bound = p.x
			if upper_bound > p.y:
				upper_bound = p.y
	if count == 0:
		return null
	center /= count
	# Create a new graph and add it to the current one
	var new_graph = get_script().new()
	new_graph.name = "graph"
	add_generator(new_graph)
	new_graph.position = center
	# Add grouped generators and keep their names
	var names: Array = []
	for g in generators:
		names.push_back(g.name)
		remove_child(g)
		new_graph.add_generator(g)
	# Create inputs and outputs generators
	var gen_inputs = MMGenIOs.new()
	gen_inputs.name = "gen_inputs"
	gen_inputs.position = Vector2(left_bound - 500, center.y)
	new_graph.add_generator(gen_inputs)
	var gen_outputs = MMGenIOs.new()
	gen_outputs.name = "gen_outputs"
	gen_outputs.position = Vector2(right_bound + 300, center.y)
	new_graph.add_generator(gen_outputs)
	# Process connections
	var new_graph_connections = []
	var my_new_connections = []
	var inputs = []
	var outputs = []
	for c in connections:
		var src_name = c.from + "." + str(c.from_port)
		if names.find(c.from) != -1 and names.find(c.to) != -1:
			new_graph_connections.push_back(c)
		elif names.find(c.from) != -1:
			var port_index = outputs.find(src_name)
			if port_index == -1:
				port_index = outputs.size()
				outputs.push_back(src_name)
				var type = new_graph.get_node(c.from).get_output_defs()[c.from_port].type
				gen_outputs.ports.push_back({name = "port" + str(port_index), type = type})
			my_new_connections.push_back(
				{from = new_graph.name, from_port = port_index, to = c.to, to_port = c.to_port}
			)
			new_graph_connections.push_back(
				{from = c.from, from_port = c.from_port, to = "gen_outputs", to_port = port_index}
			)
		elif names.find(c.to) != -1:
			var port_index = inputs.find(src_name)
			if port_index == -1:
				port_index = inputs.size()
				inputs.push_back(src_name)
				var type = get_node(c.from).get_output_defs()[c.from_port].type
				gen_inputs.ports.push_back({name = "port" + str(port_index), type = type})
			my_new_connections.push_back(
				{from = c.from, from_port = c.from_port, to = new_graph.name, to_port = port_index}
			)
			new_graph_connections.push_back(
				{from = "gen_inputs", from_port = port_index, to = c.to, to_port = c.to_port}
			)
		else:
			my_new_connections.push_back(c)
	connections = my_new_connections
	new_graph.connections = new_graph_connections
	var found_remote = false
	var remote_script = load("res://addons/material_maker/engine/gen_remote.gd")
	for g in generators:
		if g.get_script() == remote_script:
			g.name = "gen_parameters"
			found_remote = true
			new_graph.parameters = g.parameters.duplicate(true)
			break
	if !found_remote:
		var gen_parameters = remote_script.new()
		gen_parameters.name = "gen_parameters"
		gen_parameters.position = Vector2(center.x - 200, upper_bound - 300)
		new_graph.add_child(gen_parameters)
	fix_remotes()
	new_graph.fix_remotes()
	emit_hierarchy_changed()
	return new_graph


func _serialize(data: Dictionary) -> Dictionary:
	data.label = label
	data.shortdesc = shortdesc
	data.longdesc = longdesc
	data.nodes = []
	for c in get_children():
		data.nodes.append(c.serialize())
	data.connections = connections
	return data


func _deserialize(data: Dictionary) -> void:
	if data.has("label"):
		label = data.label
	if data.has("shortdesc"):
		shortdesc = data.shortdesc
	if data.has("longdesc"):
		longdesc = data.longdesc
	var nodes = data.nodes if data.has("nodes") else []
	mm_loader.add_to_gen_graph(self, nodes, data.connections if data.has("connections") else [])


func apply_diff_from(graph: MMGenGraph) -> void:
	shortdesc = graph.shortdesc
	longdesc = graph.longdesc

	var child_names = []
	for c in get_children():
		child_names.append([c.name, c.get_type()])

	child_names.sort_custom(self, "compare_name_and_type")

	var other_child_names = []
	for c in graph.get_children():
		other_child_names.append([c.name, c.get_type()])

	other_child_names.sort_custom(self, "compare_name_and_type")

	var added = []
	var removed = []
	var maybe_changed = []

	var idx1 = 0
	var idx2 = 0

	while idx1 < child_names.size() && idx2 < other_child_names.size():
		if child_names[idx1] == other_child_names[idx2]:
			maybe_changed.append(child_names[idx1])
			idx1 += 1
			idx2 += 1
		elif compare_name_and_type(child_names[idx1], other_child_names[idx2]):
			remove_generator(get_node(child_names[idx1][0]))
			idx1 += 1
		else:
			var gen = graph.get_node(other_child_names[idx2][0]).serialize()
			add_generator(mm_loader.create_gen(gen))
			idx2 += 1

	while idx1 < child_names.size():
		remove_generator(get_node(child_names[idx1][0]))
		idx1 += 1

	while idx2 < other_child_names.size():
		var gen = graph.get_node(other_child_names[idx2][0]).serialize()
		add_generator(mm_loader.create_gen(gen))
		idx2 += 1

	for child in maybe_changed:
		if child[1] == "graph":
			var node = get_node(child[0])
			var other_node = graph.get_node(child[0])

			node.apply_diff_from(other_node)
			continue

		var node = get_node(child[0])
		var other_node = graph.get_node(child[0])

		node.position = other_node.position
		if other_node.seed_locked:
			node.seed_locked = true
			node.seed_value = other_node.seed_value

		var node_seed = node.seed_value

		var node_serialized = node.serialize()
		var other_node_serialized = other_node.serialize()
		node_serialized.erase("seed")
		other_node_serialized.erase("seed")

		if node_serialized.hash() != other_node_serialized.hash():
			node.deserialize(other_node_serialized)
			node.seed_value = node_seed
			node.get_tree().call_group("generator_node", "on_generator_changed", node)

	diff_connections(graph)
	fix_remotes()


func diff_connections(graph: MMGenGraph):
	var cons = [] + connections
	cons.sort_custom(self, "compare_connection")
	var other_cons = [] + graph.connections
	other_cons.sort_custom(self, "compare_connection")

	var new_connections: Array = []
	var added_connections: Array = []
	var removed_connections: Array = []

	var idx1 = 0
	var idx2 = 0

	while idx1 < cons.size() && idx2 < other_cons.size():
		if cons[idx1].hash() == other_cons[idx2].hash():
			new_connections.append(cons[idx1])
			idx1 += 1
			idx2 += 1
		elif compare_connection(cons[idx1], other_cons[idx2]):
			removed_connections.append(cons[idx1])
			idx1 += 1
		else:
			added_connections.append(other_cons[idx2])
			new_connections.append(other_cons[idx2])
			idx2 += 1

	while idx1 < cons.size():
		removed_connections.append(cons[idx1])
		idx1 += 1

	while idx2 < other_cons.size():
		added_connections.append(other_cons[idx2])
		new_connections.append(other_cons[idx2])
		idx2 += 1

	connections = new_connections
	emit_signal("connections_changed", removed_connections, added_connections)


func compare_name_and_type(a, b):
	if a[0] < b[0]:
		return true
	elif a[0] > b[0]:
		return false

	return a[1] < b[1]


func compare_connection(a, b):
	if a.from < b.from:
		return true
	elif a.from > b.from:
		return false

	if a.from_port < b.from_port:
		return true
	elif a.from_port > b.from_port:
		return false

	if a.to < b.to:
		return true
	elif a.to > b.to:
		return false

	return a.to_port < b.to_port
