tool
extends MMGenBase
class_name MMGenGraph

var connections = []

func get_type():
	return "graph"

func get_port_source(gen_name: String, input_index: int) -> OutputPort:
	for c in connections:
		if c.to == gen_name and c.to_port == input_index:
			var src_gen = get_node(c.from)
			if src_gen != null:
				return OutputPort.new(get_node(c.from), c.from_port)
	return null

func remove_generator(generator : MMGenBase):
	var new_connections = []
	for c in connections:
		if c.from != generator.name and c.to != generator.name:
			new_connections.append(c)
	connections = new_connections

func connect_children(from, from_port : int, to, to_port : int):
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
	connections.append({from=from.name, from_port=from_port, to=to.name, to_port=to_port})
	return true

func disconnect_children(from, from_port : int, to, to_port : int):
	while true:
		var remove = -1
		for i in connections.size():
			if connections[i].from == from.name and connections[i].from_port == from_port and connections[i].to == to.name and connections[i].to_port == to_port:
				remove = i
				break
		if remove == -1:
			break
		connections.remove(remove)
	return true