extends MMGraphNodeGeneric

var material_nodes : Array = []

func get_material_nodes() -> Array:
	if material_nodes.empty():
		material_nodes = mm_loader.get_material_nodes()
	return material_nodes

func _on_MaterialExport_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed == true:
		# modify the event so it's not handled by the GraphEdit node
		event.pressed = false
		# puts
		var menu = PopupMenu.new()
		for n in get_material_nodes():
			menu.add_item(n.label)
		add_child(menu)
		menu.connect("modal_closed", menu, "queue_free")
		menu.connect("id_pressed", self, "_on_menu_id_pressed")
		menu.popup(Rect2(get_global_mouse_position(), menu.get_minimum_size()))

func _on_menu_id_pressed(id : int) -> void:
	print(get_material_nodes()[id])
	yield(get_tree(), "idle_frame")
	update_generator(mm_loader.predefined_generators[get_material_nodes()[id].name].shader_model)
