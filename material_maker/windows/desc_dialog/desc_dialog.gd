extends Window


signal close(apply)


func edit_descriptions(type : String, short : String, long : String) -> Array:
	title = type+" Description"
	$VBoxContainer/HBoxContainer/ShortDesc.text = short
	$VBoxContainer/LongDesc.text = long
	_on_WindowDialog_minimum_size_changed()
	popup_centered()
	if await self.close:
		short = $VBoxContainer/HBoxContainer/ShortDesc.text
		long = $VBoxContainer/LongDesc.text
	queue_free()
	return [ short, long ]

func _on_OK_pressed():
	emit_signal("close", true)

func _on_Cancel_pressed():
	emit_signal("close", false)

func _on_WindowDialog_popup_hide():
	emit_signal("close", false)


func _on_WindowDialog_minimum_size_changed():
	size = $VBoxContainer.size+Vector2(4, 4)

func _context_menu_about_to_popup(context_menu : PopupMenu) -> void:
	context_menu.position = get_window().position+ Vector2i(
			get_mouse_position() * get_window().content_scale_factor)

func _on_ready() -> void:
	var context_menus : Array[PopupMenu] = [
		$VBoxContainer/LongDesc.get_menu(),
		$VBoxContainer/HBoxContainer/ShortDesc.get_menu()
	]
	for context_menu in context_menus:
		context_menu.about_to_popup.connect(
				_context_menu_about_to_popup.bind(context_menu))
