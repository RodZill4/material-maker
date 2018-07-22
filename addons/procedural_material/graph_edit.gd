tool
extends GraphEdit

func _ready():
	pass

func get_source(node, port):
	for c in get_connection_list():
		if c.to == node && c.to_port == port:
			return { node=c.from, slot=c.from_port }

func remove_node(node):
	for c in get_connection_list():
		if c.from == node or c.to == node:
			disconnect_node(c.from, c.from_port, c.to, c.to_port)