extends VBoxContainer

export var library_manager_name = ""
export var base_library_name = "base.json"
export var user_library_name = "user.json"

var expanded_items : Array = []

onready var library_manager = get_node("/root/MainWindow/"+library_manager_name)

var category_buttons = {}

onready var tree : Tree = $Tree
onready var filter_line_edit : LineEdit = $Filter/Filter


const MENU_CREATE_LIBRARY : int = 1000
const MENU_LOAD_LIBRARY : int =   1001


func _ready() -> void:
	# Setup tree
	tree.set_column_expand(0, true)
	tree.set_column_expand(1, false)
	tree.set_column_min_width(1, 36)
	# Connect
	library_manager.connect("libraries_changed", self, "update_tree")
	# Setup section buttons
	for s in library_manager.get_sections():
		var button : TextureButton = TextureButton.new()
		var texture : Texture = library_manager.get_section_icon(s)
		button.name = s
		button.texture_normal = texture
		$SectionButtons.add_child(button)
		category_buttons[s] = button
		button.connect("pressed", self, "_on_Section_Button_pressed", [ s ])
		button.connect("gui_input", self, "_on_Section_Button_event", [ s ])
	$Libraries.get_popup().connect("id_pressed", self, "_on_Libraries_id_pressed")
	init_expanded_items()
	update_tree()

func init_expanded_items() -> void:
	var f = File.new()
	if f.open("user://expanded_items.bin", File.READ) == OK:
		expanded_items = parse_json(f.get_as_text())
		f.close()
	else:
		expanded_items = []
		for m in library_manager.get_items(""):
			var n : String = m.name
			var slash_position = n.find("/")
			if slash_position != -1:
				n = m.name.left(slash_position)
			if expanded_items.find(n) == -1:
				expanded_items.push_back(n)

func _exit_tree() -> void:
	var f = File.new()
	if f.open("user://expanded_items.bin", File.WRITE) == OK:
		f.store_string(to_json(expanded_items))
		f.close()

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.command and event.scancode == KEY_F:
		filter_line_edit.grab_focus()
		filter_line_edit.select_all()

func get_selected_item_name() -> String:
	return get_item_path(tree.get_selected())

func get_selected_item_doc_name() -> String:
	var name : String = ""
	var item : TreeItem = tree.get_selected()
	if item == null:
		return ""
	while item != tree.get_root():
		if name == "":
			name = item.get_text(0).to_lower()
		else:
			name = item.get_text(0).to_lower()+"_"+name
		item = item.get_parent()
	return name.replace(" ", "_")

func get_expanded_items(item : TreeItem = null) -> PoolStringArray:
	var rv : PoolStringArray = PoolStringArray()
	if item == null:
		item = tree.get_root()
		if item == null:
			return rv
	elif !item.collapsed:
		rv.push_back(get_item_path(item))
	var i = item.get_children()
	while i != null:
		rv.append_array(get_expanded_items(i))
		i = i.get_next()
	return rv

func update_category_button(category : String) -> void:
	if library_manager.is_section_enabled(category):
		category_buttons[category].material = null
		category_buttons[category].hint_tooltip = category+"\nLeft click to show\nRight click to disable"
	else:
		category_buttons[category].material = preload("res://material_maker/panels/library/button_greyed.tres")
		category_buttons[category].hint_tooltip = category+"\nRight click to enable"

func update_tree() -> void:
	# update category buttons
	for c in category_buttons.keys():
		update_category_button(c)
	# update tree
	var filter : String = $Filter/Filter.text.to_lower()
	tree.clear()
	tree.create_item()
	for i in library_manager.get_items(filter):
		add_item(i.item, i.library_index, i.name, i.icon, null, filter != "")
	$Tree.update()

func add_item(item, library_index : int, item_name : String, item_icon = null, item_parent = null, force_expand = false) -> TreeItem:
	if item_parent == null:
		item.tree_item = item_name
		item_parent = tree.get_root()
	var slash_position = item_name.find("/")
	if slash_position == -1:
		var new_item : TreeItem = null
		var c = item_parent.get_children()
		while c != null:
			if c.get_text(0) == item_name:
				new_item = c
				break
			c = c.get_next()
		if new_item == null:
			new_item = tree.create_item(item_parent)
			new_item.set_text(0, TranslationServer.translate(item_name))
		new_item.collapsed = !force_expand and expanded_items.find(item.tree_item) == -1
		new_item.set_icon(1, item_icon)
		new_item.set_icon_max_width(1, 32)
		if item.has("type") || item.has("nodes"):
			new_item.set_metadata(0, item)
			new_item.set_metadata(1, library_index)
		return new_item
	else:
		var prefix = TranslationServer.translate(item_name.left(slash_position))
		var suffix = item_name.right(slash_position+1)
		var new_parent = null
		var c = item_parent.get_children()
		while c != null:
			if c.get_text(0) == prefix:
				new_parent = c
				break
			c = c.get_next()
		if new_parent == null:
			new_parent = tree.create_item(item_parent)
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
func generate_screenshots(graph_edit, item : TreeItem = null) -> int:
	var count : int = 0
	if item == null:
		item = tree.get_root()
	item = item.get_children()
	while item != null:
		if item.get_metadata(0) != null:
			var timer : Timer = Timer.new()
			add_child(timer)
			var new_nodes = graph_edit.create_nodes(item.get_metadata(0))
			timer.wait_time = 0.05
			timer.one_shot = true
			timer.start()
			yield(timer, "timeout")
			var image = get_viewport().get_texture().get_data()
			image.flip_y()
			image = image.get_rect(Rect2(new_nodes[0].rect_global_position-Vector2(1, 2), new_nodes[0].rect_size+Vector2(4, 4)))
			print(get_icon_name(get_item_path(item)))
			image.save_png("res://material_maker/doc/images/node_"+get_icon_name(get_item_path(item))+".png")
			for n in new_nodes:
				graph_edit.remove_node(n)
			timer.queue_free()
			count += 1
		var result = generate_screenshots(graph_edit, item)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		count += result
		item = item.get_next()
	return count

func _on_Tree_item_collapsed(item) -> void:
	var path : String = get_item_path(item)
	if item.collapsed:
		while true:
			var index = expanded_items.find(path)
			if index == -1:
				break
			expanded_items.remove(index)
	else:
		expanded_items.push_back(path)


func _on_SectionButtons_resized():
	$SectionButtons.columns = $SectionButtons.rect_size.x / 33

var current_category = ""

func _on_Section_Button_pressed(category : String) -> void:
	var item : TreeItem = $Tree.get_root().get_children()
	while item != null:
		if item.get_text(0) == category:
			item.select(0)
			item.collapsed = false
			$Tree.ensure_cursor_is_visible()
			break
		item = item.get_next()

func _on_Section_Button_event(event : InputEvent, category : String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_RIGHT:
		if library_manager.toggle_section(category):
			category_buttons[category].material = null
			category_buttons[category].hint_tooltip = category+"\nLeft click to show\nRight click to disable"
		else:
			category_buttons[category].material = preload("res://material_maker/panels/library/button_greyed.tres")
			category_buttons[category].hint_tooltip = category+"\nRight click to enable"
			if current_category == category:
				current_category = ""

func _on_Libraries_about_to_show():
	var popup : PopupMenu = $Libraries.get_popup()
	var unload : PopupMenu = null
	for c in popup.get_children():
		if c is PopupMenu:
			unload = c
			break
	if unload == null:
		unload = PopupMenu.new()
		unload.name = "Unload"
		popup.add_child(unload)
		unload.connect("id_pressed", self, "_on_Libraries_Unload_id_pressed")
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

func _on_Libraries_id_pressed(id : int) -> void:
	match id:
		MENU_CREATE_LIBRARY:
			var dialog = preload("res://material_maker/panels/library/create_lib_dialog.tscn").instance()
			add_child(dialog)
			var status = dialog.enter_info()
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
			if status.ok:
				library_manager.create_library(status.path, status.name)
		MENU_LOAD_LIBRARY:
			var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
			add_child(dialog)
			dialog.rect_min_size = Vector2(500, 500)
			dialog.access = FileDialog.ACCESS_FILESYSTEM
			dialog.mode = FileDialog.MODE_OPEN_FILE
			dialog.add_filter("*.json;Material Maker Library")
			var files = dialog.select_files()
			while files is GDScriptFunctionState:
				files = yield(files, "completed")
			if files.size() == 1:
				library_manager.load_library(files[0])
		_:
			library_manager.toggle_library(id)

func _on_Libraries_Unload_id_pressed(id : int) -> void:
	library_manager.unload_library(id)

var current_item : TreeItem

func _on_Tree_item_rmb_selected(position):
	current_item = $Tree.get_item_at_position(position)
	$PopupMenu.popup(Rect2(get_global_mouse_position(), $PopupMenu.get_minimum_size()))

func _on_PopupMenu_about_to_show():
	var library_index : int = current_item.get_metadata(1)
	var read_only : bool = library_manager.get_child(library_index).read_only
	$PopupMenu.set_item_disabled(0, read_only)
	$PopupMenu.set_item_disabled(1, read_only)
	$PopupMenu.set_item_disabled(2, read_only)

func _on_PopupMenu_index_pressed(index):
	var library_index : int = current_item.get_metadata(1)
	var item_path : String = get_item_path(current_item)
	match index:
		0: # Rename
			var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
			add_child(dialog)
			var status = dialog.enter_text("Rename item", "Enter the new name for this item", item_path)
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
			if status.ok:
				library_manager.rename_item_in_library(library_index, item_path, status.text)
		1: # Update thumbnail
			var main_window = get_node("/root/MainWindow")
			var current_node = main_window.get_current_node(main_window.get_current_graph_edit())
			if current_node == null:
				return
			var result = current_node.generator.render(self, 0, 64, true)
			while result is GDScriptFunctionState:
				result = yield(result, "completed")
			var image : Image = result.get_image()
			result.release(self)
			library_manager.update_item_icon_in_library(library_index, item_path, image)
		2: # Delete item
			library_manager.remove_item_from_library(library_index, item_path)
		4: # Define aliases
			var aliases = library_manager.get_aliases(item_path)
			var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
			add_child(dialog)
			var status = dialog.enter_text("Library item aliases", "Updated aliases for "+item_path, aliases)
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
			if ! status.ok:
				return
			library_manager.set_aliases(item_path, status.text)


func update_from_locale() -> void:
	update_tree()
