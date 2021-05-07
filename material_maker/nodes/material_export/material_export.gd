extends MMGraphNodeGeneric

var material_nodes : Array = []

func get_material_nodes() -> Array:
	if material_nodes.empty():
		material_nodes = mm_loader.get_material_nodes()
	return material_nodes

func _on_MaterialExport_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed == true:
		accept_event()
		var menu = PopupMenu.new()
		for n in get_material_nodes():
			menu.add_item(n.label)
		add_child(menu)
		menu.connect("modal_closed", menu, "queue_free")
		menu.connect("id_pressed", self, "_on_menu_id_pressed")
		menu.popup(Rect2(get_global_mouse_position(), menu.get_minimum_size()))

func _on_menu_id_pressed(id : int) -> void:
	yield(get_tree(), "idle_frame")
	generator.model = get_material_nodes()[id].name
	generator.editable = false
	update_generator(mm_loader.predefined_generators[generator.model].shader_model)
