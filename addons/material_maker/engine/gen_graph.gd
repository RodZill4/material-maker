tool
extends MMGenBase
class_name MMGenGraph

var connections = null

func get_port_source(gen_name: String, input_index: int) -> OutputPort:
	for c in connections:
		if c.to == gen_name and c.to_port == input_index:
			return OutputPort.new(get_node(c.from), c.from_port)
	return null
