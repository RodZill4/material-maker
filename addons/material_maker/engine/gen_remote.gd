tool
extends MMGenBase
class_name MMGenRemote

"""
Remote can be used to control parameters from several generators in the same graph
"""

var widgets = null

func set_widgets(w):
	widgets = w

func get_type():
	return "remote"

func get_type_name():
	return "Remote"

func _serialize(data):
	data.type = "remote"
	data.widgets = widgets
	return data
