tool
extends Node

var includes

func create_node(type) -> Node:
	var node = null
	var file_name = "res://material_maker/nodes/"+type+".tscn"
	if ResourceLoader.exists(file_name):
		var node_type = load(file_name)
		if node_type != null:
			node = node_type.instance()
	if node == null:
		node = preload("res://material_maker/nodes/generic.tscn").instance()
	return node
