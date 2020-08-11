extends Panel

var recent_files = []

var config_cache : ConfigFile = ConfigFile.new()

var current_tab = null

var updating : bool = false
var need_update : bool = false

onready var projects = $VBoxContainer/Layout/SplitRight/ProjectsPane/Projects

onready var layout = $VBoxContainer/Layout
var library
var preview_2d
var histogram
var preview_3d
var hierarchy

onready var preview_2d_background = $VBoxContainer/Layout/SplitRight/ProjectsPane/Preview2D
onready var preview_2d_background_button = $VBoxContainer/Layout/SplitRight/ProjectsPane/PreviewUI/Preview2DButton
onready var preview_3d_background = $VBoxContainer/Layout/SplitRight/ProjectsPane/Preview3D
onready var preview_3d_background_button = $VBoxContainer/Layout/SplitRight/ProjectsPane/PreviewUI/Preview3DButton
onready var preview_3d_background_panel = $VBoxContainer/Layout/SplitRight/ProjectsPane/PreviewUI/Panel

const RECENT_FILES_COUNT = 15

const THEMES = [ "Dark", "Default", "Light" ]

const MENU = [
	{ menu="File", command="new_material", description="New material" },
	{ menu="File", command="load_material", shortcut="Control+O", description="Load material" },
	{ menu="File", submenu="load_recent", description="Load recent", standalone_only=true },
	{ menu="File" },
	{ menu="File", command="save_material", shortcut="Control+S", description="Save material" },
	{ menu="File", command="save_material_as", shortcut="Control+Shift+S", description="Save material as..." },
	{ menu="File", command="save_all_materials", description="Save all materials..." },
	{ menu="File" },
	{ menu="File", submenu="export_material", description="Export material" },
	#{ menu="File", command="export_material", shortcut="Control+E", description="Export material" },
	{ menu="File" },
	{ menu="File", command="close_material", description="Close material" },
	{ menu="File", command="quit", shortcut="Control+Q", description="Quit" },

	#{ menu="Edit", command="edit_undo", shortcut="Control+Z", description="Undo" },
	#{ menu="Edit", command="edit_redo", shortcut="Control+Shift+Z", description="Redo" },
	#{ menu="Edit" },
	{ menu="Edit", command="edit_cut", shortcut="Control+X", description="Cut" },
	{ menu="Edit", command="edit_copy", shortcut="Control+C", description="Copy" },
	{ menu="Edit", command="edit_paste", shortcut="Control+V", description="Paste" },
	{ menu="Edit", command="edit_duplicate", shortcut="Control+D", description="Duplicate" },
	{ menu="Edit" },
	{ menu="Edit", submenu="set_theme", description="Set theme" },

	{ menu="View", command="view_center", shortcut="C", description="Center view" },
	{ menu="View", command="view_reset_zoom", shortcut="Control+0", description="Reset zoom" },
	{ menu="View" },
	{ menu="View", submenu="show_panes", description="Panes" },

	{ menu="Tools", submenu="create", description="Create" },
	{ menu="Tools", command="create_subgraph", shortcut="Control+G", description="Create group" },
	{ menu="Tools", command="make_selected_nodes_editable", shortcut="Control+W", description="Make selected nodes editable" },
	{ menu="Tools" },
	{ menu="Tools", command="add_to_user_library", description="Add selected node to user library" },
	{ menu="Tools", command="export_library", description="Export the nodes library" },
	
	#{ menu="Tools", command="generate_screenshots", description="Generate screenshots for the library nodes" },

	{ menu="Help", command="show_doc", shortcut="F1", description="User manual" },
	{ menu="Help", command="show_library_item_doc", shortcut="Control+F1", description="Show selected library item documentation" },
	{ menu="Help", command="bug_report", description="Report a bug" },
	{ menu="Help", command="show_reddit", description="Material Maker on reddit" },
	{ menu="Help" },
	{ menu="Help", command="about", description="About" }
]

# warning-ignore:unused_signal
signal quit

func _ready() -> void:
	# Restore the window position/size if values are present in the configuration cache
	config_cache.load("user://cache.ini")
	if config_cache.has_section_key("window", "screen"):
		OS.current_screen = config_cache.get_value("window", "screen")
	if config_cache.has_section_key("window", "maximized"):
		OS.window_maximized = config_cache.get_value("window", "maximized")

	if !OS.window_maximized:
		if config_cache.has_section_key("window", "position"):
			OS.window_position = config_cache.get_value("window", "position")
		if config_cache.has_section_key("window", "size"):
			OS.window_size = config_cache.get_value("window", "size")
	
	# Restore the theme
	var theme_name : String = "default"
	if config_cache.has_section_key("window", "theme"):
		theme_name = config_cache.get_value("window", "theme")
	set_theme(theme_name)

	# In HTML5 export, copy all examples to the filesystem
	if OS.get_name() == "HTML5":
		print("Copying samples")
		var dir : Directory = Directory.new()
		dir.make_dir("/examples")
		dir.open("res://material_maker/examples/")
		dir.list_dir_begin(true)
		while true:
			var f = dir.get_next()
			if f == "":
				break
			if f.ends_with(".ptex"):
				print(f)
				dir.copy("res://material_maker/examples/"+f, "/examples/"+f)
		print("Done")

	# Upscale everything if the display requires it (crude hiDPI support).
	# This prevents UI elements from being too small on hiDPI displays.
	if OS.get_screen_dpi() >= 192 and OS.get_screen_size().x >= 2048:
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(), 2)

	# Set a minimum window size to prevent UI elements from collapsing on each other.
	OS.min_window_size = Vector2(1024, 600)

	# Set window title
	OS.set_window_title(ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/release"))

	layout.load_panes(config_cache)
	library = layout.get_panel("Library")
	preview_2d = layout.get_panel("Preview2D")
	histogram = layout.get_panel("Histogram")
	preview_3d = layout.get_panel("Preview3D")
	preview_3d.connect("need_update", self, "update_preview_3d")
	hierarchy = layout.get_panel("Hierarchy")
	hierarchy.connect("group_selected", self, "on_group_selected")

	# Load recent projects
	load_recents()

	# Create menus
	create_menus(MENU, self, $VBoxContainer/Menu)
	
	new_material()
	
	do_load_materials(OS.get_cmdline_args())
	
	get_tree().connect("files_dropped", self, "on_files_dropped")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

func get_current_graph_edit() -> MMGraphEdit:
	var graph_edit = projects.get_current_tab_control()
	if graph_edit != null and graph_edit is GraphEdit:
		return graph_edit
	return null

func create_menus(menu_def, object, menu_bar) -> void:
	for i in menu_def.size():
		if ! menu_bar.has_node(menu_def[i].menu.split("/")[0]):
			var menu_button = MenuButton.new()
			menu_button.name = menu_def[i].menu
			menu_button.text = menu_def[i].menu
			menu_button.switch_on_hover = true
			menu_bar.add_child(menu_button)
	for m in menu_bar.get_children():
		if ! m is MenuButton:
			continue
		var menu = m.get_popup()
		create_menu(menu_def, object, menu, m.name)
		m.connect("about_to_show", self, "on_menu_about_to_show", [ menu_def, object, m.name, menu ])

func create_menu(menu_def : Array, object : Object, menu : PopupMenu, menu_name : String) -> PopupMenu:
	var is_mac : bool = OS.get_name() == "OSX"
	var submenus = {}
	var menu_name_length = menu_name.length()
	menu.clear()
	menu.connect("id_pressed", self, "on_menu_id_pressed", [ menu_def, object ])
	for i in menu_def.size():
		if menu_def[i].has("standalone_only") and menu_def[i].standalone_only and Engine.editor_hint:
			continue
		if menu_def[i].has("editor_only") and menu_def[i].editor_only and !Engine.editor_hint:
			continue
		if menu_def[i].menu == menu_name:
			if menu_def[i].has("submenu"):
				var submenu = PopupMenu.new()
				var submenu_function = "create_menu_"+menu_def[i].submenu
				if object.has_method(submenu_function):
					submenu.connect("about_to_show", object, submenu_function, [ submenu ]);
				else:
					create_menu(menu_def, object, submenu, menu_def[i].submenu)
				menu.add_child(submenu)
				menu.add_submenu_item(menu_def[i].description, submenu.get_name())
			elif menu_def[i].has("description"):
				var shortcut = 0
				if menu_def[i].has("shortcut"):
					for s in menu_def[i].shortcut.split("+"):
						if s == "Alt":
							shortcut |= KEY_MASK_ALT
						elif s == "Control":
							shortcut |= KEY_MASK_CMD if is_mac else KEY_MASK_CTRL
						elif s == "Shift":
							shortcut |= KEY_MASK_SHIFT
						else:
							shortcut |= OS.find_scancode_from_string(s)
				if menu_def[i].has("toggle") and menu_def[i].toggle:
					menu.add_check_item(menu_def[i].description, i, shortcut)
				else:
					menu.add_item(menu_def[i].description, i, shortcut)
			else:
				menu.add_separator()
		elif menu_def[i].menu.begins_with(menu_name+"/"):
			var submenu_name = menu_def[i].menu.right(menu_name_length+1)
			submenu_name = submenu_name.split("/")[0]
			if ! submenus.has(submenu_name):
				var submenu = PopupMenu.new()
				create_menu(menu_def, object, submenu, menu_name+"/"+submenu_name)
				menu.add_child(submenu)
				menu.add_submenu_item(submenu_name, submenu.get_name())
				submenus[submenu_name] = submenu
	return menu

func on_menu_id_pressed(id, menu_def, object) -> void:
	if menu_def[id].has("command"):
		var command = menu_def[id].command
		if object.has_method(command):
			if menu_def[id].has("toggle") and menu_def[id].toggle:
				object.call(command, !object.call(command))
			else:
				object.call(command)

func on_menu_about_to_show(menu_def, object, name : String, menu : PopupMenu) -> void:
	for i in menu_def.size():
		if menu_def[i].menu != name:
			continue
		if menu_def[i].has("submenu"):
			pass
		elif menu_def[i].has("command"):
			var command = menu_def[i].command+"_is_disabled"
			if object.has_method(command):
				var is_disabled = object.call(command)
				menu.set_item_disabled(menu.get_item_index(i), is_disabled)
			if menu_def[i].has("toggle") and menu_def[i].toggle:
				command = menu_def[i].command
				if object.has_method(command):
					menu.set_item_checked(i, object.call(command))

func create_menu_load_recent(menu) -> void:
	menu.clear()
	if recent_files.empty():
		menu.add_item("No items found", 0)
		menu.set_item_disabled(0, true)
	else:
		for i in recent_files.size():
			menu.add_item(recent_files[i], i)
		if !menu.is_connected("id_pressed", self, "_on_LoadRecent_id_pressed"):
			menu.connect("id_pressed", self, "_on_LoadRecent_id_pressed")

func _on_LoadRecent_id_pressed(id) -> void:
	if !do_load_material(recent_files[id]):
		recent_files.remove(id)

func load_recents() -> void:
	var f = File.new()
	if f.open("user://recent_files.bin", File.READ) == OK:
		recent_files = parse_json(f.get_as_text())
		f.close()

func add_recent(path) -> void:
	while true:
		var index = recent_files.find(path)
		if index >= 0:
			recent_files.remove(index)
		else:
			break
	recent_files.push_front(path)
	while recent_files.size() > RECENT_FILES_COUNT:
		recent_files.pop_back()
	var f = File.new()
	f.open("user://recent_files.bin", File.WRITE)
	f.store_string(to_json(recent_files))
	f.close()


func create_menu_export_material(menu) -> void:
	menu.clear()
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		var material_node = graph_edit.get_material_node()
		for p in material_node.get_export_profiles():
			menu.add_item(p)
		if !menu.is_connected("id_pressed", self, "_on_ExportMaterial_id_pressed"):
			menu.connect("id_pressed", self, "_on_ExportMaterial_id_pressed")

func export_profile_config_key(profile : String) -> String:
	var key = "export_"+profile.to_lower().replace(" ", "_")
	return key

func export_material(file_path : String, profile : String) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit == null:
		return
	config_cache.set_value("path", export_profile_config_key(profile), file_path.get_base_dir())
	var export_prefix = file_path.trim_suffix("."+file_path.get_extension())
	graph_edit.export_material(export_prefix, profile)

func _on_ExportMaterial_id_pressed(id) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit == null:
		return
	var material_node = graph_edit.get_material_node()
	if material_node == null:
		return
	var profile = material_node.get_export_profiles()[id]
	var dialog : FileDialog = FileDialog.new()
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*."+material_node.get_export_extension(profile)+";"+profile+" Material")
	var config_key = export_profile_config_key(profile)
	if config_cache.has_section_key("path", config_key):
		dialog.current_dir = config_cache.get_value("path", config_key)
	add_child(dialog)
	dialog.connect("file_selected", self, "export_material", [ profile ])
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()


func create_menu_set_theme(menu) -> void:
	menu.clear()
	for t in THEMES:
		menu.add_item(t)
	if !menu.is_connected("id_pressed", self, "_on_SetTheme_id_pressed"):
		menu.connect("id_pressed", self, "_on_SetTheme_id_pressed")

func set_theme(theme_name) -> void:
	theme = load("res://material_maker/theme/"+theme_name+".tres")

func _on_SetTheme_id_pressed(id) -> void:
	var theme_name : String = THEMES[id].to_lower()
	set_theme(theme_name)
	config_cache.set_value("window", "theme", theme_name)


func create_menu_show_panes(menu : PopupMenu) -> void:
	menu.clear()
	var panes = layout.get_panel_list()
	for i in range(panes.size()):
		menu.add_check_item(panes[i], i)
		menu.set_item_checked(i, layout.is_pane_visible(panes[i]))
	if !menu.is_connected("id_pressed", self, "_on_ShowPanes_id_pressed"):
		menu.connect("id_pressed", self, "_on_ShowPanes_id_pressed")

func _on_ShowPanes_id_pressed(id) -> void:
	var pane : String = layout.get_panel_list()[id]
	layout.set_pane_visible(pane, !layout.is_pane_visible(pane))
	print(pane)

func create_menu_create(menu) -> void:
	var gens = mm_loader.get_generator_list()
	menu.clear()
	for i in gens.size():
		menu.add_item(gens[i], i)
	if !menu.is_connected("id_pressed", self, "_on_Create_id_pressed"):
		menu.connect("id_pressed", self, "_on_Create_id_pressed")

func _on_Create_id_pressed(id) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		var gens = mm_loader.get_generator_list()
		graph_edit.create_gen_from_type(gens[id])


func new_pane() -> GraphEdit:
	var graph_edit = preload("res://material_maker/panels/graph_edit/graph_edit.tscn").instance()
	graph_edit.node_factory = $NodeFactory
	projects.add_child(graph_edit)
	projects.current_tab = graph_edit.get_index()
	return graph_edit

func new_material() -> void:
	var graph_edit = new_pane()
	graph_edit.new_material()
	graph_edit.update_tab_title()
	hierarchy.update_from_graph_edit(get_current_graph_edit())

func load_material() -> void:
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILES
	dialog.add_filter("*.ptex;Procedural Textures File")
	if config_cache.has_section_key("path", "material"):
		dialog.current_dir = config_cache.get_value("path", "material")
	dialog.connect("files_selected", self, "do_load_materials")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func do_load_materials(filenames) -> void:
	if not filenames.empty():
		config_cache.set_value("path", "material", filenames[0].get_base_dir())
	for f in filenames:
		do_load_material(f, false)
	hierarchy.update_from_graph_edit(get_current_graph_edit())

func do_load_material(filename : String, update_hierarchy : bool = true) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	var node_count = 2 # So test below succeeds if graph_edit is null...
	if graph_edit != null:
		node_count = 0
		for c in graph_edit.get_children():
			if c is GraphNode:
				node_count += 1
				if node_count > 1:
					break
	if node_count > 1:
		graph_edit = new_pane()
	graph_edit.load_file(filename)
	add_recent(filename)
	if update_hierarchy:
		hierarchy.update_from_graph_edit(get_current_graph_edit())

func save_material() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		if graph_edit.save_path != null:
			graph_edit.save_file(graph_edit.save_path)
			add_recent(graph_edit.save_path)
		else:
			save_material_as()

func save_material_as() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		var dialog = FileDialog.new()
		add_child(dialog)
		dialog.rect_min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.mode = FileDialog.MODE_SAVE_FILE
		dialog.add_filter("*.ptex;Procedural Textures File")
		if config_cache.has_section_key("path", "material"):
			dialog.current_dir = config_cache.get_value("path", "material")
		dialog.connect("file_selected", self, "do_save_material")
		dialog.connect("popup_hide", dialog, "queue_free")
		dialog.popup_centered()

func do_save_material(filename : String) -> void:


	get_current_graph_edit().save_file(filename)

func close_material() -> void:
	projects.close_tab()

func quit() -> void:
	dim_window()
	get_tree().quit()

func edit_cut() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.cut()

func edit_undo() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.get_node("UndoRedo").undo()

func edit_undo_is_disabled() -> bool:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		return !graph_edit.get_node("UndoRedo").can_undo()
	return false

func edit_redo() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.get_node("UndoRedo").redo()

func edit_redo_is_disabled() ->  bool:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		return !graph_edit.get_node("UndoRedo").can_redo()
	return false

func edit_cut_is_disabled() -> bool:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	return graph_edit == null or !graph_edit.can_copy()

func edit_copy() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.copy()

func edit_copy_is_disabled() -> bool:
	return edit_cut_is_disabled()

func edit_paste() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.paste()

func edit_paste_is_disabled() -> bool:
	var data = parse_json(OS.clipboard)
	return data == null

func edit_duplicate() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.duplicate_selected()

func edit_duplicate_is_disabled() -> bool:
	return edit_cut_is_disabled()

func view_center() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	graph_edit.center_view()

func view_reset_zoom() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	graph_edit.zoom = 1


func get_selected_nodes() -> Array:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		return graph_edit.get_selected_nodes()
	else:
		return []

func create_subgraph() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.create_subgraph()

func make_selected_nodes_editable() -> void:
	var selected_nodes = get_selected_nodes()
	if !selected_nodes.empty():
		for n in selected_nodes:
			if n.generator.toggle_editable() and n.has_method("update_node"):
				n.update_node()

func add_to_user_library() -> void:
	var selected_nodes = get_selected_nodes()
	if !selected_nodes.empty():
		var dialog = preload("res://material_maker/widgets/line_dialog/line_dialog.tscn").instance()
		dialog.set_value(library.get_selected_item_name())
		dialog.set_texts("New library element", "Select a name for the new library element")
		add_child(dialog)
		dialog.connect("ok", self, "do_add_to_user_library", [ selected_nodes ])
		dialog.connect("popup_hide", dialog, "queue_free")
		dialog.popup_centered()

func do_add_to_user_library(name, nodes) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	var data
	if nodes.size() == 1:
		data = nodes[0].generator.serialize()
		data.erase("node_position")
	elif graph_edit != null:
		data = graph_edit.serialize_selection()
	var dir = Directory.new()
	dir.make_dir("user://library")
	dir.make_dir("user://library/user")
	data.library = "user://library/user.json"
	data.icon = library.get_icon_name(name)
	var result = nodes[0].generator.render(0, 64, true)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	result.save_to_file("user://library/user/"+data.icon+".png")
	result.release()
	library.add_item(data, name, library.get_preview_texture(data))
	library.save_library("user://library/user.json")

func export_library() -> void:
	var dialog : FileDialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.json;JSON files")
	dialog.connect("file_selected", self, "do_export_library")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func do_export_library(path : String) -> void:
	library.export_libraries(path)

func get_doc_dir() -> String:
	var base_dir = OS.get_executable_path().replace("\\", "/").get_base_dir()
	# In release builds, documentation is expected to be located in
	# a subdirectory of the program directory
	var release_doc_path = base_dir.plus_file("doc")
	# In development, documentation is part of the project files.
	# We can use a globalized `res://` path here as the project isn't exported.
	var devel_doc_path = ProjectSettings.globalize_path("res://material_maker/doc/_build/html")
	for p in [ release_doc_path, devel_doc_path ]:
		var file = File.new()
		if file.file_exists(p+"/index.html"):
			return p
	return ""

func show_doc() -> void:
	var doc_dir = get_doc_dir()
	if doc_dir != "":
		OS.shell_open(doc_dir+"/index.html")

func show_doc_is_disabled() -> bool:
	return get_doc_dir() == ""

func show_library_item_doc() -> void:
	var doc_dir : String = get_doc_dir()
	if doc_dir != "":
		var doc_name = library.get_selected_item_doc_name()
		if doc_name != "":
			var doc_path : String = doc_dir+"/node_"+doc_name+".html"
			OS.shell_open(doc_path)

func show_library_item_doc_is_disabled() -> bool:
	return get_doc_dir() == "" or library.get_selected_item_doc_name() == ""

func bug_report() -> void:
	OS.shell_open("https://github.com/RodZill4/godot-procedural-textures/issues")

func show_reddit() -> void:
	OS.shell_open("https://www.reddit.com/r/MaterialMaker/")

func about() -> void:
	var about_box = preload("res://material_maker/windows/about/about.tscn").instance()
	add_child(about_box)
	about_box.connect("popup_hide", about_box, "queue_free")
	about_box.popup_centered()

# Preview

func update_preview() -> void:
	var status
	need_update = true
	if updating:
		return
	updating = true
	while need_update:
		need_update = false
# warning-ignore:void_assignment
		status = update_preview_2d()
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
		status = update_preview_3d([ preview_3d, preview_3d_background ])
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
	updating = false

func update_preview_2d(node = null) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		if node == null:
			for n in graph_edit.get_children():
				if n is GraphNode and n.selected:
					node = n
					break
		if node != null:
			preview_2d.set_generator(node.generator)
			histogram.set_generator(node.generator)
			preview_2d_background.set_generator(node.generator)
		else:
			preview_2d.set_generator(null)
			histogram.set_generator(null)
			preview_2d_background.set_generator(null)

func update_preview_3d(previews : Array) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null and graph_edit.top_generator != null and graph_edit.top_generator.has_node("Material"):
		var gen_material = graph_edit.top_generator.get_node("Material")
		var status = gen_material.render_textures()
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
		for p in previews:
			gen_material.update_materials(p.get_materials())

var selected_node = null
func on_selected_node_change(node) -> void:
	if node != selected_node:
		selected_node = node
		preview_2d.set_generator(node.generator if node != null else null)
		update_preview_2d(node)

func _on_Projects_tab_changed(_tab) -> void:
	var new_tab = projects.get_current_tab_control()
	if new_tab != current_tab:
		if new_tab != null:
			for c in get_incoming_connections():
				if c.method_name == "update_preview" or c.method_name == "update_preview_2d":
					c.source.disconnect(c.signal_name, self, c.method_name)
			new_tab.connect("graph_changed", self, "update_preview")
			if !new_tab.is_connected("node_selected", self, "on_selected_node_change"):
				new_tab.connect("node_selected", self, "on_selected_node_change")
		current_tab = new_tab
		update_preview()
		hierarchy.update_from_graph_edit(get_current_graph_edit())

func on_group_selected(generator) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.edit_subgraph(generator)

func _exit_tree() -> void:
	# Save the window position and size to remember it when restarting the application
	config_cache.set_value("window", "screen", OS.current_screen)
	config_cache.set_value("window", "maximized", OS.window_maximized || OS.window_fullscreen)
	config_cache.set_value("window", "position", OS.window_position)
	config_cache.set_value("window", "size", OS.window_size)
	layout.save_config(config_cache)
	config_cache.save("user://cache.ini")

func _notification(what : int) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		dim_window()

func dim_window() -> void:
	# Darken the UI to denote that the application is currently exiting
	# (it won't respond to user input in this state).
	modulate = Color(0.5, 0.5, 0.5)

func show_background_preview_2d(button_pressed):
	preview_2d_background.visible = button_pressed
	if button_pressed:
		preview_3d_background_button.pressed = false

func show_background_preview_3d(button_pressed):
	preview_3d_background.visible = button_pressed
	preview_3d_background_panel.visible = button_pressed
	if button_pressed:
		preview_2d_background_button.pressed = false


func generate_screenshots():
	var result = library.generate_screenshots(get_current_graph_edit())
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	print(result)

# Handle dropped files

func get_control_at_position(pos : Vector2, parent : Control) -> Control:
	for c in parent.get_children():
		if c is Control and c.visible and c.get_global_rect().has_point(pos):
			return get_control_at_position(pos, c)
	return parent

func on_files_dropped(files : PoolStringArray, _screen) -> void:
	for f in files:
		match f.get_extension():
			"ptex":
				do_load_material(f)
			"bmp", "hdr", "jpg", "jpeg", "png", "svg", "tga", "webp":
				var control : Control = get_control_at_position(get_global_mouse_position(), self)
				while control != self:
					if control.has_method("on_drop_image_file"):
						control.on_drop_image_file(f)
						break
					control = control.get_parent()
				# graph_edit.do_paste({type="image", image=f})

# Use this to investigate the connect bug

func draw_children(p, x):
	for c in p.get_children():
		if c is Control:
			draw_rect(c.get_global_rect(), Color(1.0, 0.0, 0.0), false)
			draw_children(c, x)
			if c.get_global_rect().has_point(x) and !c.visible:
				c.show()
				print(c.get_path())

func _draw_debug():
	draw_children(self, get_global_mouse_position())
