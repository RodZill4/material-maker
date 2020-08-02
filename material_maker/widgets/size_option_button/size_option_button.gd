extends OptionButton
class_name SizeOptionButton

var min_size : int = 4 setget set_min_size
var max_size : int = 12 setget set_max_size
var size_value : int = 10 setget set_size_value

signal size_value_changed(s)

func _ready() -> void:
	connect("item_selected", self, "_on_item_selected")

func set_min_size(m : int) -> void:
	min_size = m
	update_options()

func set_max_size(m : int) -> void:
	max_size = m
	update_options()

func set_size_value(v : int) -> void:
	size_value = v
	update_options()

func update_options() -> void:
	clear()
	for i in range(min_size, max_size+1):
		var s = pow(2, i)
		add_item("%d×%d" % [ s, s ])
	selected = size_value-min_size

func _on_item_selected(id : int) -> void:
	size_value = id + min_size
	emit_signal("size_value_changed", size_value)
