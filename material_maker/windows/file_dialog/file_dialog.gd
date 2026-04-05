extends FileDialog

signal return_paths(path_list)

var favorites_list : ItemList = null
var recents_list : ItemList = null

var left_panel : VSplitContainer

enum Thumbnail {
	IMAGE,
	PROJECT,
}

func _ready() -> void:
	load_fav_recents()
	if file_mode == FileMode.FILE_MODE_SAVE_FILE:
		ok_button_text = tr("Save")

	if mm_globals.config.has_section_key("file_dialog", "display_mode"):
		display_mode = mm_globals.config.get_value("file_dialog", "display_mode")

	setup_thumbnail_callbacks()

	use_native_dialog = mm_globals.get_config("ui_use_native_file_dialogs")
	content_scale_factor = mm_globals.ui_scale_factor()

	min_size = get_contents_minimum_size().max(Vector2i(750, 500)) * content_scale_factor

	for n in get_children(true):
		if n is VBoxContainer:
			# setup left panel(fav/recents) gui input signals
			left_panel = n.get_child(1).get_children()[0]
			favorites_list = left_panel.get_child(0).get_child(1)
			recents_list = left_panel.get_child(1).get_child(1)
			favorites_list.gui_input.connect(_on_favorites_list_gui_input)
			recents_list.gui_input.connect(_on_recents_list_gui_input)

			# setup display list/thumbnail buttons signals
			var thumb_list_btns : HBoxContainer = n.get_child(1).get_child(1).get_child(0).get_child(3)
			var thumbnail_button : Button = thumb_list_btns.get_child(0)
			var list_button : Button = thumb_list_btns.get_child(1)
			thumbnail_button.pressed.connect(set_thumbnail_mode_callback)
			list_button.pressed.connect(set_list_mode_callback)

func _on_favorites_list_gui_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		if not favorites_list.get_selected_items().is_empty():
			var fav = get_favorite_list()
			fav.remove_at(favorites_list.get_selected_items()[0])
			favorites_list.remove_item(favorites_list.get_selected_items()[0])
			set_favorite_list(fav)
			left_panel.accept_event()

func _on_recents_list_gui_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		if not recents_list.get_selected_items().is_empty():
			var recents = get_recent_list()
			recents.remove_at(recents_list.get_selected_items()[0])
			recents_list.remove_item(recents_list.get_selected_items()[0])
			set_recent_list(recents)
			left_panel.accept_event()

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
		node.content_scale_factor = mm_globals.ui_scale_factor()
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
	mm_globals.config.set_value("file_dialog", "display_mode", display_mode)

	# cleanup thumbnail threads
	should_generate_thumbnails = false
	for t in thumbnail_tasks:
		WorkerThreadPool.wait_for_task_completion(t)

func load_fav_recents() -> void:
	var json = JSON.new()
	if mm_globals.config.has_section_key("file_dialog", "recents"):
		if json.parse(mm_globals.config.get_value("file_dialog", "recents")) == OK:
			set_recent_list(json.data)
	if mm_globals.config.has_section_key("file_dialog", "favorites"):
		if json.parse(mm_globals.config.get_value("file_dialog", "favorites")) == OK:
			set_favorite_list(json.data)

#region thumbnail generation

var default_file_thumbnail : DPITexture = get_theme_icon("file_thumbnail", "FileDialog")
var thumbnail_tasks : PackedInt32Array
var should_generate_thumbnails : bool = true

func thumbnail_callback(path : String) -> Texture2D:
	var tex : Texture2D = ImageTexture.new()
	match path.get_extension().to_lower():
		"bmp", "exr", "hdr", "jpg", "jpeg", "png", "svg", "tga", "webp", "dds":
			thumbnail_tasks.append(WorkerThreadPool.add_task(
					thumbnail_generate.bind(path, tex, Thumbnail.IMAGE)))
		"ptex":
			thumbnail_tasks.append(WorkerThreadPool.add_task(
					thumbnail_generate.bind(path, tex, Thumbnail.PROJECT)))
		_:
			tex = default_file_thumbnail
	return tex

func thumbnail_set(image : Image, tex : Texture2D, task : int) -> void:
	if tex and image and not image.is_invisible():
		tex.set_image(image)

	WorkerThreadPool.wait_for_task_completion(task)
	thumbnail_tasks.erase(task)

func thumbnail_generate(path : String, tex : Texture2D, type : Thumbnail) -> void:
	if not should_generate_thumbnails:
		return
	var img : Image = Image.new()
	match type:
		Thumbnail.IMAGE:
			# load_from_file does not work with dds, see godot issue #113063
			if path.get_extension().to_lower() == "dds":
				img.load_dds_from_buffer(FileAccess.get_file_as_bytes(path))
			else:
				img = Image.load_from_file(path)

			if img != null and maxi(img.get_width(), img.get_height()) > 128:
				@warning_ignore("integer_division")
				img.resize(128, 128 * img.get_height() / img.get_width())
		Thumbnail.PROJECT:
			var f : FileAccess = FileAccess.open(path, FileAccess.READ)
			if JSON.parse_string(f.get_as_text()):
				var ptex : Dictionary = JSON.parse_string(f.get_as_text())
				img = default_file_thumbnail.get_image()
				if ptex and ptex.has("project_thumbnail"):
					img.load_webp_from_buffer(Marshalls.base64_to_raw(ptex.project_thumbnail))
	if img == null:
		img = default_file_thumbnail.get_image()
	if is_instance_valid(self):
		var task_id : int = WorkerThreadPool.get_caller_task_id()
		thumbnail_set.call_deferred(img, tex, task_id)

func set_thumbnail_mode_callback() -> void:
	# Don't display small icon on top of thumbnail
	FileDialog.set_get_thumbnail_callback(thumbnail_callback)
	FileDialog.set_get_icon_callback(Callable())

func set_list_mode_callback() -> void:
	FileDialog.set_get_icon_callback(thumbnail_callback)

func setup_thumbnail_callbacks() -> void:
	if display_mode == DisplayMode.DISPLAY_THUMBNAILS:
		set_thumbnail_mode_callback()
	else:
		set_list_mode_callback()

#endregion
