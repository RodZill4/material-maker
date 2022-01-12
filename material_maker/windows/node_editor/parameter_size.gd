extends HBoxContainer

var size_first: int = 0
var size_last: int = 13
var size_default: int = 10


func _ready() -> void:
	update_size_configuration()


func get_model_data() -> Dictionary:
	return {
		first = size_first,
		last = size_last,
		default = size_default,
	}


func set_model_data(data) -> void:
	if data.has("first"):
		size_first = data.first
	if data.has("last"):
		size_last = data.last
	if data.has("default"):
		size_default = data.default
	update_size_configuration()


func update_size_configuration() -> void:
	if size_first > size_last:
		var tmp: int = size_first
		size_first = size_last
		size_last = tmp
	size_default = int(clamp(size_default, size_first, size_last))
	$First.min_size = 0
	$First.max_size = size_last
	$First.size_value = size_first
	$Last.min_size = size_first
	$Last.max_size = 13
	$Last.size_value = size_last
	$Default.min_size = size_first
	$Default.max_size = size_last
	$Default.size_value = size_default


func _on_First_item_selected(ID) -> void:
	size_first = ID
	update_size_configuration()


func _on_Last_item_selected(ID) -> void:
	size_last = ID
	update_size_configuration()


func _on_Default_item_selected(ID) -> void:
	size_default = ID
