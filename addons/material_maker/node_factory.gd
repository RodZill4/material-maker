tool
extends Node

var includes

func _ready():
	pass

func create_node(type):
	var node = null
	var node_type = load("res://addons/material_maker/nodes/"+type+".tscn")
	if node_type != null:
		node = node_type.instance()
	else:
		node = preload("res://addons/material_maker/nodes/generic.tscn").instance()
	return node
