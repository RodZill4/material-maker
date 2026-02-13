extends Control

# The layer object
var layers

@onready var tree = %Tree


func _ready():
	set_layers(layers)

func set_layers(l) -> void:
	layers = l
	if layers and tree:
		tree.layers = l
		tree.update_from_layers(layers.layers, layers.selected_layer)

func _on_Tree_selection_changed(_old_selected : TreeItem, new_selected : TreeItem) -> void:
	layers.select_layer(new_selected.get_meta("layer"))

func _on_Add_pressed():
	var menu = preload("res://material_maker/panels/layers/add_layer_menu.tscn").instantiate()
	add_child(menu)
	var button_rect = %Buttons/Add.get_global_rect()
	menu.connect("id_pressed", Callable(self, "_on_add_layer_menu"))
	menu.connect("id_pressed", Callable(menu, "queue_free"))
	menu.connect("popup_hide", Callable(menu, "queue_free"))
	menu.popup(Rect2(Vector2(button_rect.position.x, button_rect.end.y) *
		mm_globals.ui_scale_factor(), Vector2(0, 0)))

func _on_add_layer_menu(id):
	layers.add_layer(id)
	layers.get_parent().initialize_layers_history()

func _on_Duplicate_pressed():
	var current = tree.get_selected()
	if current != null:
		layers.duplicate_layer(current.get_meta("layer"))
	layers.get_parent().initialize_layers_history()

func _on_Remove_pressed():
	var current = tree.get_selected()
	if current != null:
		layers.remove_layer(current.get_meta("layer"))

func _on_Up_pressed():
	var current = tree.get_selected()
	if current != null:
		layers.move_layer_up(current.get_meta("layer"))

func _on_Down_pressed():
	var current = tree.get_selected()
	if current != null:
		layers.move_layer_down(current.get_meta("layer"))

func _on_Config_pressed():
	var current = tree.get_selected()
	if current != null:
		var layer : MMLayer = current.get_meta("layer")
		if layer.get_layer_type() == MMLayer.LAYER_MASK:
			return
		var popup = preload("res://material_maker/panels/layers/layer_config_popup.tscn").instantiate()
		popup.content_scale_factor = mm_globals.ui_scale_factor()
		popup.min_size = Vector2(228, 245) * popup.content_scale_factor
		add_child(popup)
		popup.configure_layer(layers, current.get_meta("layer"))
