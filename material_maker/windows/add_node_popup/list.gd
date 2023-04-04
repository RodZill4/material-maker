extends VBoxContainer

const NodeSelectionButton := preload("res://material_maker/windows/add_node_popup/node_selection_button.tscn")


signal object_selected(obj)


var button_pool := []


func clear() -> void:
	for bt in get_children():
		bt.disconnect("pressed",Callable(self,"_on_bt_pressed"))
		remove_child(bt)
		button_pool.append(bt)


func add_item(obj, node_path: String, node_name: String, node_icon: Texture2D = null) -> void:
	var bt = NodeSelectionButton.instantiate() if button_pool == [] else button_pool.pop_back()
	add_child(bt)
	bt.tooltip_text = node_path + "/" + name
	bt.set_node(node_name, node_path, node_icon)
	bt.connect("pressed",Callable(self,"_on_bt_pressed").bind(obj))


func _on_bt_pressed(obj) -> void:
	emit_signal("object_selected", obj)


func select_first() -> void:
	if get_child_count() != 0:
		get_children()[0].emit_signal("pressed")
