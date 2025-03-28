extends FileDialog


var left_panel = null
var volume_option = null

var _context_menu: PopupMenu = null

var _content_scale_factor: float = 1.0

const DIALOG_HACK : bool = true


signal return_paths(path_list)

func _context_menu_about_to_popup():
	_context_menu.position =  get_window().position + Vector2i( get_mouse_position() * _content_scale_factor)

func _ready() -> void:
	_content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	content_scale_factor = _content_scale_factor
	min_size = _content_scale_factor * Vector2(650, 500)
	
	for child in get_children():
		if child is PopupMenu:
			_context_menu = child
			_context_menu.about_to_popup.connect(_context_menu_about_to_popup)

	if DIALOG_HACK:
		var vbox = get_vbox()
		var hbox = HSplitContainer.new()
		add_child(hbox)
		remove_child(vbox)
		left_panel = preload("res://material_maker/windows/file_dialog/left_panel.tscn").instantiate()
		hbox.add_child(left_panel)
		left_panel.connect("open_directory",Callable(self,"set_current_dir"))
		hbox.add_child(vbox)
		# todo vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fav_button = preload("res://material_maker/windows/file_dialog/fav_button.tscn").instantiate()
		vbox.get_child(0).add_child(fav_button)
		fav_button.connect("pressed",Callable(self,"add_favorite"))
		if OS.get_name() == "Windows":
			volume_option = vbox.get_child(0).get_child(3)
			if ! volume_option is OptionButton:
				volume_option = null

func get_full_current_dir() -> String:
	var prefix = ""
	if volume_option != null and volume_option.visible:
		prefix = volume_option.get_item_text(volume_option.selected)
	return prefix+get_current_dir()

func _on_FileDialog_file_selected(path) -> void:
	if DIALOG_HACK:
		left_panel.add_recent(get_full_current_dir())
	emit_signal("return_paths", [ path ])

func _on_FileDialog_files_selected(paths) -> void:
	if DIALOG_HACK:
		left_panel.add_recent(get_full_current_dir())
	emit_signal("return_paths", paths)

func _on_FileDialog_dir_selected(dir) -> void:
	emit_signal("return_paths", [ dir ])

func _on_FileDialog_popup_hide() -> void:
	emit_signal("return_paths", [ ])

func select_files() -> Array:
	mm_globals.main_window.add_dialog(self)
	popup_centered()
	var result = await self.return_paths
	queue_free()
	return result

func add_favorite():
	if DIALOG_HACK:
		left_panel.add_favorite(get_full_current_dir())

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
