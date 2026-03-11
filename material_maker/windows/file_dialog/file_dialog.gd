extends FileDialog

var _content_scale_factor: float = 1.0

signal return_paths(path_list)

var favorites_list : ItemList = null
var recents_list : ItemList = null

func _context_menu_about_to_popup(context_menu : PopupMenu):
	context_menu.position =  get_window().position + Vector2i(
			get_mouse_position() * _content_scale_factor)

func _ready() -> void:
	load_fav_recents()
	if file_mode == FileMode.FILE_MODE_SAVE_FILE:
		ok_button_text = tr("Save")

	use_native_dialog = mm_globals.get_config("ui_use_native_file_dialogs")
	_content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	content_scale_factor = _content_scale_factor
	
	for child in get_children(true):
		if child is PopupMenu:
			child.about_to_popup.connect(_context_menu_about_to_popup.bind(child))
	
	for hbox in get_vbox().get_children():
		if hbox is HBoxContainer:
			for line_edit in hbox.get_children():
				if line_edit is LineEdit:
					var context_menu : PopupMenu = line_edit.get_menu()
					context_menu.about_to_popup.connect(
							_context_menu_about_to_popup.bind(context_menu))

	min_size = _content_scale_factor * get_contents_minimum_size()
	min_size = Vector2i(750, 500) * int(_content_scale_factor)

	# setup left panel(fav/recents) gui input signals
	for n in get_children(true):
		if n is VBoxContainer:
			var left_panel : VSplitContainer = n.get_child(1).get_children()[0]
			favorites_list = left_panel.get_child(0).get_child(1)
			recents_list = left_panel.get_child(1).get_child(1)
			favorites_list.gui_input.connect(_on_favorites_list_gui_input)
			recents_list.gui_input.connect(_on_recents_list_gui_input)

func _on_favorites_list_gui_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		if not favorites_list.get_selected_items().is_empty():
			var fav = get_favorite_list()
			fav.remove_at(favorites_list.get_selected_items()[0])
			favorites_list.remove_item(favorites_list.get_selected_items()[0])
			set_favorite_list(fav)

func _on_recents_list_gui_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		if not recents_list.get_selected_items().is_empty():
			var recents = get_recent_list()
			recents.remove_at(recents_list.get_selected_items()[0])
			recents_list.remove_item(recents_list.get_selected_items()[0])
			set_recent_list(recents)

func _on_FileDialog_file_selected(path) -> void:
	emit_signal("return_paths", [ path ])

func _on_FileDialog_files_selected(paths) -> void:
	emit_signal("return_paths", paths)

func _on_FileDialog_dir_selected(dir) -> void:
	emit_signal("return_paths", [ dir ])

func _on_FileDialog_popup_hide() -> void:
	emit_signal("return_paths", [ ])

func select_files() -> Array:
	mm_globals.main_window.add_dialog(self)
	hide()
	popup_centered()
	var result = await self.return_paths
	queue_free()
	return result

func _on_child_entered_tree(node: Node) -> void:
	if node is ConfirmationDialog or node is AcceptDialog:
		node.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
		var min_size_scale = Vector2(0,0)
		match node.title:
			"Alert!":
				min_size_scale = Vector2(300,60)
			"Create Folder":
				min_size_scale = Vector2(200,100)
			"Please Confirm...":
				min_size_scale = Vector2(430,100)
		node.min_size = min_size_scale * node.content_scale_factor

func _exit_tree() -> void:
	mm_globals.config.set_value("file_dialog", "recents", JSON.stringify(get_recent_list()))
	mm_globals.config.set_value("file_dialog", "favorites", JSON.stringify(get_favorite_list()))

func load_fav_recents() -> void:
	var json = JSON.new()
	if mm_globals.config.has_section_key("file_dialog", "recents"):
		if json.parse(mm_globals.config.get_value("file_dialog", "recents")) == OK:
			set_recent_list(json.data)
	if mm_globals.config.has_section_key("file_dialog", "favorites"):
		if json.parse(mm_globals.config.get_value("file_dialog", "favorites")) == OK:
			set_favorite_list(json.data)
