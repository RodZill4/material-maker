tool
extends HBoxContainer

var size_first = 0
var size_last = 12
var size_default = 8

func _ready():
	update_size_configuration()

func get_model_data():
	var data = {}
	data.first = size_first
	data.last = size_last
	data.default = size_default
	return data

func set_model_data(data):
	if data.has("first"):
		size_first = data.first
	if data.has("last"):
		size_last = data.last
	if data.has("default"):
		size_last = data.default
	update_size_configuration()

func update_size_option_button(button, first, last, current):
	button.clear()
	for i in range(first, last+1):
		var s = pow(2, i)
		button.add_item("%dx%d" % [ s, s ])
	button.selected = current - first

func update_size_configuration():
	update_size_option_button($First, 0, size_last, size_first)
	update_size_option_button($Last, size_first, 12, size_last)
	update_size_option_button($Default, size_first, size_last, size_default)

func _on_First_item_selected(ID):
	size_first = ID
	update_size_configuration()

func _on_Last_item_selected(ID):
	size_last = size_first + ID
	update_size_configuration()

func _on_Default_item_selected(ID):
	size_default = size_first + ID
