tool
extends Node

var includes

func _ready():
	pass

func create_node(type):
	var node = null
	if File.new().file_exists("res://addons/material_maker/nodes/"+type+".mmn"):
		node = preload("res://addons/material_maker/nodes/node_generic.gd").new()
		node.model = type
	else:
		var node_type = load("res://addons/material_maker/nodes/"+type+".tscn")
		if node_type != null:
			node = node_type.instance()
	return node
