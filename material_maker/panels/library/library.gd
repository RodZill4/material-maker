extends Control

@export var library_manager_name = ""

var expanded_items : Array = []

@onready var library_manager = get_node("/root/MainWindow/"+library_manager_name)

var category_buttons = {}

@onready var tree : Tree = %Tree
@onready var libraries_button : MenuButton = %Libraries
@onready var filter_line_edit : LineEdit = %Filter
@onready var item_menu : PopupMenu = %ItemMenu

const MINIMUM_ITEM_HEIGHT : int = 30

const MENU_CREATE_LIBRARY : int = 1000
const MENU_LOAD_LIBRARY : int =   1001

func _context_menu_about_to_popup(context_menu : PopupMenu) -> void:
	context_menu.position = get_window().position+ Vector2i(
			get_global_mouse_position() * get_window().content_scale_factor)

func _ready() -> void:
	%Filter.get_menu().about_to_popup.connect(
			_context_menu_about_to_popup.bind(%Filter.get_menu()))
	# Setup tree
	tree.set_column_expand(0, true)
	tree.set_column_expand(1, false)
	tree.set_column_custom_minimum_width(1, 36)
	# Connect
	library_manager.libraries_changed.connect(self.update_tree)
	# Setup section buttons
	for s in library_manager.get_sections():
		var button : TextureButton = TextureButton.new()
		var texture : Texture2D = library_manager.get_section_icon(s)
		button.name = s
		button.texture_normal = texture
		%SectionButtons.add_child(button)
		category_buttons[s] = button
		button.connect("pressed", self._on_Section_Button_pressed.bind(s))
		button.connect("gui_input", self._on_Section_Button_event.bind(s))
	libraries_button.get_popup().id_pressed.connect(self._on_Libraries_id_pressed)
	init_expanded_items()
	update_tree()
	update_theme()

func _notification(what: int) -> void:
	if not is_node_ready():
		return

	if what == NOTIFICATION_THEME_CHANGED:
		update_theme()

func update_theme() -> void:
	libraries_button.icon = get_theme_icon("settings", "MM_Icons")

func init_expanded_items() -> void:
	var f = FileAccess.open("user://expanded_items.bin", FileAccess.READ)
	if f != null:
		var test_json_conv = JSON.new()
		test_json_conv.parse(f.get_as_text())
		var json = test_json_conv.get_data()
		if json != null and json is Array:
			expanded_items = json
			return
	expanded_items = []
	for m in library_manager.get_items(""):
		var n : String = m.name
		var slash_position = n.find("/")
		if slash_position != -1:
			n = m.name.left(slash_position)
		if expanded_items.find(n) == -1:
			expanded_items.push_back(n)

func _exit_tree() -> void:
	var f = FileAccess.open("user://expanded_items.bin", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(expanded_items))

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.is_command_or_control_pressed() and event.keycode == KEY_F:
		filter_line_edit.grab_focus()
		filter_line_edit.select_all()

func get_selected_item_name() -> String:
	return get_item_path(tree.get_selected())

func get_selected_item_doc_name() -> String:
	var doc_name : String = ""
	var item : TreeItem = tree.get_selected()
	if item == null:
		return ""
	while item != tree.get_root():
		if doc_name == "":
			doc_name = item.get_text(0).to_lower()
		else:
			doc_name = item.get_text(0).to_lower()+"_"+doc_name
		item = item.get_parent()
	return doc_name.replace(" ", "_")

func get_expanded_items(item : TreeItem = null) -> PackedStringArray:
	var rv : PackedStringArray = PackedStringArray()
	if item == null:
		item = tree.get_root()
		if item == null:
			return rv
	elif !item.collapsed:
		rv.push_back(get_item_path(item))
	var items : Array[TreeItem] = item.get_children()
	for i in items:
		rv.append_array(get_expanded_items(i))
	return rv

func update_category_button(category : String) -> void:
	if library_manager.is_section_enabled(category):
		category_buttons[category].material = null
		category_buttons[category].tooltip_text = category+"\nLeft click to show\nRight click to disable"
	else:
		category_buttons[category].material = preload("res://material_maker/panels/library/button_greyed.tres")
		category_buttons[category].tooltip_text = category+"\nRight click to enable"

func update_tree() -> void:
	# update category buttons
	for c in category_buttons.keys():
		update_category_button(c)
	# update tree
	var filter : String = filter_line_edit.text.to_lower()
	tree.clear()
	tree.create_item()
	for i in library_manager.get_items(filter):
		var _item := add_item(i.item, i.library_index, i.name, i.icon, null, filter != "")

	tree.queue_redraw()

func add_item(item, library_index : int, item_name : String, item_icon = null, item_parent = null, force_expand = false) -> TreeItem:
	if item_parent == null:
		item.tree_item = item_name
		item_parent = tree.get_root()
	var slash_position = item_name.find("/")
	if slash_position == -1:
		var new_item : TreeItem = null
		for c in item_parent.get_children():
			if c.get_text(0) == item_name:
				new_item = c
				break
		if new_item == null:
			new_item = tree.create_item(item_parent)
			new_item.custom_minimum_height = MINIMUM_ITEM_HEIGHT
			new_item.set_text(0, TranslationServer.translate(item_name))
		new_item.collapsed = !force_expand and expanded_items.find(item.tree_item) == -1
		new_item.set_icon(1, item_icon)
		new_item.set_icon_max_width(1, 28)
		if item.has("type") || item.has("nodes"):
			new_item.set_metadata(0, item)
			new_item.set_metadata(1, library_index)
		return new_item
	else:
		var prefix = TranslationServer.translate(item_name.left(slash_position))
		var suffix = item_name.right(-(slash_position+1))
		var new_parent = null
		for c in item_parent.get_children():
			if c.get_text(0) == prefix:
				new_parent = c
				break
		if new_parent == null:
			new_parent = tree.create_item(item_parent)
			new_parent.custom_minimum_height = MINIMUM_ITEM_HEIGHT
			new_parent.set_text(0, TranslationServer.translate(prefix))
			new_parent.collapsed = !force_expand and expanded_items.find(get_item_path(new_parent)) == -1
		return add_item(item, library_index, suffix, item_icon, new_parent, force_expand)

func get_item_path(item : TreeItem) -> String:
	if item == null:
		return ""
	var item_path = item.get_text(0)
	var item_parent = item.get_parent()
	while item_parent != tree.get_root():
		item_path = item_parent.get_text(0)+"/"+item_path
		item_parent = item_parent.get_parent()
	return item_path

func get_icon_name(item_name : String) -> String:
	return item_name.to_lower().replace("/", "_").replace(" ", "_")

func _on_Filter_text_changed(_filter : String) -> void:
	update_tree()

# Should be moved to library manager
func generate_screenshots(graph_edit : GraphEdit, parent_item : TreeItem = null) -> int:
	var count : int = 0
	if parent_item == null:
		parent_item = tree.get_root()
		var stylebox : StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = Color("303236") # documentation page bg color
		graph_edit.add_theme_stylebox_override("panel", stylebox)
	var items : Array[TreeItem] = parent_item.get_children()
	for item in items:
		if item.get_metadata(0) != null:
			var new_nodes = graph_edit.create_nodes(item.get_metadata(0))
			await get_tree().create_timer(0.05).timeout
			var image = get_viewport().get_texture().get_image()
			var csf = mm_globals.main_window.get_window().content_scale_factor
			image = image.get_region(Rect2(csf*(new_nodes[0].global_position-Vector2(6, 6)),csf*(new_nodes[0].size+Vector2(14, 12))))
			print(get_icon_name(get_item_path(item)))
			image.resize(image.get_size().x/csf, image.get_size().y/csf, Image.INTERPOLATE_LANCZOS)
			image.save_png("res://material_maker/doc/images/node_"+get_icon_name(get_item_path(item))+".png")
			for n in new_nodes:
				graph_edit.remove_node(n)
			count += 1
		var result = await generate_screenshots(graph_edit, item)
		count += result
	if parent_item == null:
		graph_edit.remove_theme_stylebox_override("panel")
	return count

func _on_Tree_item_collapsed(item) -> void:
	var path : String = get_item_path(item)
	if item.collapsed:
		while true:
			var index = expanded_items.find(path)
			if index == -1:
				break
			expanded_items.remove_at(index)
	else:
		expanded_items.push_back(path)


var current_category = ""

func _on_Section_Button_pressed(category : String) -> void:
	if not library_manager.is_section_enabled(category):
		return

	var match_item : TreeItem
	for item in tree.get_root().get_children():
		if item.get_text(0) == category:
			item.select(0)
			item.collapsed = false
			match_item = item
			break

	tree.scroll_to_item(tree.get_last_item(tree.get_root()))
	tree.scroll_to_item(match_item)


func _on_Section_Button_event(event : InputEvent, category : String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if library_manager.toggle_section(category):
			category_buttons[category].material = null
			category_buttons[category].tooltip_text = category+"\nLeft click to show\nRight click to disable"
		else:
			category_buttons[category].material = preload("res://material_maker/panels/library/button_greyed.tres")
			category_buttons[category].tooltip_text = category+"\nRight click to enable"
			if current_category == category:
				current_category = ""

func _on_Libraries_about_to_show():
	var popup : PopupMenu = libraries_button.get_popup()
	var unload : PopupMenu = null
	for c in popup.get_children():
		if c is PopupMenu:
			unload = c
			break
	if unload == null:
		unload = PopupMenu.new()
		unload.name = "Unload"
		popup.add_child(unload)
		unload.id_pressed.connect(self._on_Libraries_Unload_id_pressed)
	popup.clear()
	unload.clear()
	for i in library_manager.get_child_count():
		popup.add_check_item(library_manager.get_child(i).library_name, i)
		popup.set_item_checked(i, library_manager.is_library_enabled(i))
		if i > 1:
			unload.add_item(library_manager.get_child(i).library_name, i)
	popup.add_separator()
	popup.add_item("Create library", MENU_CREATE_LIBRARY)
	popup.add_item("Load library", MENU_LOAD_LIBRARY)
	popup.add_submenu_item("Unload", "Unload")

func on_html5_load_file(file_name, _file_type, file_data):
	match file_name.get_extension():
		"json":
			library_manager.load_library(file_name, file_data)

func _on_Libraries_id_pressed(id : int) -> void:
	print(id)
	match id:
		MENU_CREATE_LIBRARY:
			var dialog = preload("res://material_maker/panels/library/create_lib_dialog.tscn").instantiate()
			add_child(dialog)
			var status = await dialog.enter_info()
			if status.ok:
				library_manager.create_library(status.path, status.name)
		MENU_LOAD_LIBRARY:
			if OS.get_name() == "HTML5":
				pass
				# TODO: Fix this
#				if ! Html5.is_connected("file_loaded",Callable(self,"on_html5_load_file")):
#					Html5.connect("file_loaded",Callable(self,"on_html5_load_file"))
#				Html5.load_file(".json")
			else:
				var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
				dialog.min_size = Vector2(500, 500)
				dialog.access = FileDialog.ACCESS_FILESYSTEM
				dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
				dialog.add_filter("*.json;Material Maker Library")
				var files = await dialog.select_files()
				if files.size() == 1:
					library_manager.load_library(files[0])
		_:
			library_manager.toggle_library(id)

func _on_Libraries_Unload_id_pressed(id : int) -> void:
	library_manager.unload_library(id)

var current_item : TreeItem

func _on_tree_item_mouse_selected(mouse_position : Vector2i, mouse_button_index : int):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_on_Tree_item_rmb_selected(mouse_position)

func _on_Tree_item_rmb_selected(mouse_position : Vector2i):
	current_item = tree.get_item_at_position(mouse_position)
	if current_item.get_metadata(1) != null:
		var library_index : int = current_item.get_metadata(1)
		var read_only : bool = library_manager.get_child(library_index).read_only
		item_menu.set_item_disabled(0, read_only)
		item_menu.set_item_disabled(1, read_only)
		item_menu.set_item_disabled(2, read_only)
		mm_globals.popup_menu(item_menu, self)

func _on_PopupMenu_index_pressed(index):
	var library_index : int = 0
	if current_item:
		library_index = current_item.get_metadata(1)
	var item_path : String = get_item_path(current_item)
	match index:
		0: # Rename
			var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instantiate()
			dialog.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
			dialog.min_size = Vector2(250, 90) * dialog.content_scale_factor
			add_child(dialog)
			var status = await dialog.enter_text("Rename item", "Enter the new name for this item", item_path)
			if status.ok:
				library_manager.rename_item_in_library(library_index, item_path, status.text)
		1: # Update thumbnail
			var main_window = mm_globals.main_window
			var current_node = main_window.get_current_node(main_window.get_current_graph_edit())
			if current_node == null:
				return
			var image : Image = await current_node.generator.render_output(0, Vector2i(64, 64))
			library_manager.update_item_icon_in_library(library_index, item_path, image)
		2: # Delete item
			library_manager.remove_item_from_library(library_index, item_path)
		4: # Define aliases
			var aliases = library_manager.get_aliases(item_path)
			var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instantiate()
			dialog.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
			dialog.min_size = Vector2(400, 90) * dialog.content_scale_factor
			add_child(dialog)
			var status = await dialog.enter_text("Library item aliases", "Updated aliases for "+item_path, aliases)
			if ! status.ok:
				return
			library_manager.set_aliases(item_path, status.text)

func update_from_locale() -> void:
	update_tree()

func _on_GetFromWebsite_pressed():
	var dialog = load("res://material_maker/windows/load_from_website/load_from_website.tscn").instantiate()
	var result = await dialog.select_asset(3, true)
	if result is Dictionary and result.has("index"):
		var graph_edit : MMGraphEdit = mm_globals.main_window.get_current_graph_edit()
		if graph_edit != null:
			mm_loader.get_generator_list()
			await graph_edit.create_gen_from_type("website:%d" % result.index)
