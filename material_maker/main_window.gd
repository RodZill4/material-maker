extends Panel

var quitting : bool = false

var recent_files = []

var config_cache : ConfigFile = ConfigFile.new()

var current_tab = null

var updating : bool = false
var need_update : bool = false

# The resolution scale to use for 3D previews.
# Values above 1.0 enable supersampling. This has a significant performance cost
# but greatly improves texture rendering quality, especially when using
# specular/parallax mapping and when viewed at oblique angles.
var preview_rendering_scale_factor := 2.0

# The number of subdivisions to use for tesselated 3D previews. Higher values
# result in more detailed bumps but are more demanding to render.
# This doesn't apply to non-tesselated 3D previews which use parallax occlusion mapping.
var preview_tesselation_detail := 256

onready var node_library_manager = $NodeLibraryManager
onready var brush_library_manager = $BrushLibraryManager

onready var projects = $VBoxContainer/Layout/SplitRight/ProjectsPanel/Projects

onready var layout = $VBoxContainer/Layout
var library
var preview_2d : Array
var histogram
var preview_3d
var hierarchy
var brushes

onready var preview_2d_background = $VBoxContainer/Layout/SplitRight/ProjectsPanel/BackgroundPreviews/Preview2D
onready var preview_2d_background_button = $VBoxContainer/Layout/SplitRight/ProjectsPanel/PreviewUI/Preview2DButton
onready var preview_3d_background = $VBoxContainer/Layout/SplitRight/ProjectsPanel/BackgroundPreviews/Preview3D
onready var preview_3d_background_button = $VBoxContainer/Layout/SplitRight/ProjectsPanel/PreviewUI/Preview3DButton
onready var preview_3d_background_panel = $VBoxContainer/Layout/SplitRight/ProjectsPanel/PreviewUI/Panel

const FPS_LIMIT_MIN = 20
const FPS_LIMIT_MAX = 500
const IDLE_FPS_LIMIT_MIN = 1
const IDLE_FPS_LIMIT_MAX = 100

const RECENT_FILES_COUNT = 15

const THEMES = [ "Dark", "Default", "Light" ]

const MENU = [
	{ menu="File", command="new_material", shortcut="Control+N", description="New material" },
	{ menu="File", command="new_paint_project", shortcut="Control+Shift+N", description="New paint project" },
	{ menu="File", command="load_project", shortcut="Control+O", description="Load" },
	{ menu="File", command="load_material_from_website", description="Load material from website" },
	{ menu="File", submenu="load_recent", description="Load recent", standalone_only=true },
	{ menu="File" },
	{ menu="File", command="save_project", shortcut="Control+S", description="Save" },
	{ menu="File", command="save_project_as", shortcut="Control+Shift+S", description="Save as..." },
	{ menu="File", command="save_all_projects", description="Save all..." },
	{ menu="File" },
	{ menu="File", submenu="export_material", description="Export material" },
	#{ menu="File", command="export_material", shortcut="Control+E", description="Export material" },
	{ menu="File" },
	{ menu="File", command="close_project", shortcut="Control+Shift+Q", description="Close" },
	{ menu="File", command="quit", shortcut="Control+Q", description="Quit" },

	{ menu="Edit", command="edit_undo", shortcut="Control+Z", description="Undo" },
	{ menu="Edit", command="edit_redo", shortcut="Control+Shift+Z", description="Redo" },
	{ menu="Edit" },
	{ menu="Edit", command="edit_cut", shortcut="Control+X", description="Cut" },
	{ menu="Edit", command="edit_copy", shortcut="Control+C", description="Copy" },
	{ menu="Edit", command="edit_paste", shortcut="Control+V", description="Paste" },
	{ menu="Edit", command="edit_duplicate", shortcut="Control+D", description="Duplicate" },
	{ menu="Edit" },
	{ menu="Edit", command="edit_select_all", shortcut="Control+A", description="Select All" },
	{ menu="Edit", command="edit_select_none", shortcut="Control+Shift+A", description="Select None" },
	{ menu="Edit", command="edit_select_invert", shortcut="Control+I", description="Invert Selection" },
	{ menu="Edit" },
	{ menu="Edit", command="edit_load_selection", description="Load Selection" },
	{ menu="Edit", command="edit_save_selection", description="Save Selection" },
	{ menu="Edit" },
	{ menu="Edit", submenu="set_theme", description="Set theme" },
	{ menu="Edit", command="edit_preferences", description="Preferences" },

	{ menu="View", command="view_center", shortcut="C", description="Center view" },
	{ menu="View", command="view_reset_zoom", shortcut="Control+0", description="Reset zoom" },
	{ menu="View" },
	{ menu="View", command="toggle_side_panels", shortcut="Control+Space", description="Show/Hide side panels" },
	{ menu="View", submenu="show_panels", description="Panels" },

	{ menu="Tools", submenu="create", description="Create" },
	{ menu="Tools", command="create_subgraph", shortcut="Control+G", description="Create group" },
	{ menu="Tools", command="make_selected_nodes_editable", shortcut="Control+W", description="Make selected nodes editable" },
	{ menu="Tools" },
	{ menu="Tools", submenu="add_selection_to_library", description="Add selected node to library", mode="material" },
	{ menu="Tools", submenu="add_brush_to_library", description="Add current brush to library", mode="paint" },
	{ menu="Tools", command="generate_graph_screenshot", description="Create a screenshot of the current graph", mode="material" },
	{ menu="Tools", command="paint_project_settings", description="Paint project settings", mode="paint" },
	{ menu="Tools", submenu="paint_environment", description="Set painting environment", mode="paint" },
	{ menu="Tools" },
	{ menu="Tools", command="environment_editor", description="Environment editor" },
	#{ menu="Tools", command="generate_screenshots", description="Generate screenshots for the library nodes", mode="material" },

	{ menu="Help", command="show_doc", shortcut="F1", description="User manual" },
	{ menu="Help", command="show_library_item_doc", shortcut="Control+F1", description="Show selected library item documentation" },
	{ menu="Help", command="bug_report", description="Report a bug" },
	{ menu="Help" },
	{ menu="Help", command="about", description="About" }
]

const DEFAULT_CONFIG = {
	locale = "",
	confirm_quit = true,
	confirm_close_project = true,
	vsync = true,
	fps_limit = 145,
	idle_fps_limit = 20,
	ui_scale = 0,
	ui_3d_preview_resolution = 2.0,
	ui_3d_preview_tesselation_detail = 256,
	ui_3d_preview_sun_shadow = false,
	bake_ray_count = 64,
	bake_ao_ray_dist = 128.0,
	bake_ao_ray_bias = 0.005,
	bake_denoise_radius = 3
}

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)

	# Load and nitialize config
	config_cache.load("user://cache.ini")
	for k in DEFAULT_CONFIG.keys():
		if ! config_cache.has_section_key("config", k):
			config_cache.set_value("config", k, DEFAULT_CONFIG[k])

	if get_config("locale") == "":
		config_cache.set_value("config", "locale", TranslationServer.get_locale())

	on_config_changed()

	# Restore the window position/size if values are present in the configuration cache
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

	# Set a minimum window size to prevent UI elements from collapsing on each other.
	OS.min_window_size = Vector2(1024, 600)

	# Set window title
	OS.set_window_title(ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/actual_release"))

	layout.load_panels(config_cache)
	library = get_panel("Library")
	preview_2d = [ get_panel("Preview2D"), get_panel("Preview2D (2)") ]
	histogram = get_panel("Histogram")
	preview_3d = get_panel("Preview3D")
	preview_3d.connect("need_update", self, "update_preview_3d")
	hierarchy = get_panel("Hierarchy")
	hierarchy.connect("group_selected", self, "on_group_selected")
	brushes = get_panel("Brushes")

	# Load recent projects
	load_recents()

	# Create menus
	create_menus(MENU, self, $VBoxContainer/TopBar/Menu)

	new_material()

	do_load_projects(OS.get_cmdline_args())

	get_tree().connect("files_dropped", self, "on_files_dropped")

	mm_renderer.connect("render_queue", $VBoxContainer/TopBar/RenderCounter, "on_counter_change")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

func get_config(key : String):
	if ! config_cache.has_section_key("config", key):
		return DEFAULT_CONFIG[key]
	return config_cache.get_value("config", key)

func on_config_changed() -> void:
	OS.vsync_enabled = get_config("vsync")
	# Convert FPS to microseconds per frame.
	# Clamp the FPS to reasonable values to avoid locking up the UI.
	OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(get_config("fps_limit"), FPS_LIMIT_MIN, FPS_LIMIT_MAX)) * 1_000_000
	# locale
	var locale = get_config("locale")
	if locale != "" and locale != TranslationServer.get_locale():
		TranslationServer.set_locale(locale)
		get_tree().call_group("updated_from_locale", "update_from_locale")

	var scale = get_config("ui_scale")
	if scale <= 0:
		# If scale is set to 0 (auto), scale everything if the display requires it (crude hiDPI support).
		# This prevents UI elements from being too small on hiDPI displays.
		scale = 2 if OS.get_screen_dpi() >= 192 and OS.get_screen_size().x >= 2048 else 1
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(), scale)

	# Clamp to reasonable values to avoid crashes on startup.
	preview_rendering_scale_factor = clamp(get_config("ui_3d_preview_resolution"), 1.0, 2.0)
	preview_tesselation_detail = clamp(get_config("ui_3d_preview_tesselation_detail"), 16, 1024)

func get_panel(panel_name : String) -> Control:
	return layout.get_panel(panel_name)

func get_current_project() -> Control:
	return projects.get_current_tab_control()

func get_current_graph_edit() -> MMGraphEdit:
	var graph_edit = projects.get_current_tab_control()
	if graph_edit != null and graph_edit.has_method("get_graph_edit"):
		return graph_edit.get_graph_edit()
	return null

func get_share_button():
	return $VBoxContainer/TopBar/Share

# Modes

var current_mode : String = ""

func get_current_mode() -> String:
	return current_mode

func set_current_mode(mode : String) -> void:
	current_mode = mode
	layout.change_mode(current_mode)
	create_menus(MENU, self, $VBoxContainer/TopBar/Menu)

# Menus

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
		#m.connect("about_to_show", self, "on_menu_about_to_show", [ menu_def, object, m.name, menu ])

func create_menu(menu_def : Array, object : Object, menu : PopupMenu, menu_name : String) -> PopupMenu:
	var mode = ""
	if object.has_method("get_current_mode"):
		mode = object.get_current_mode()
	var is_mac : bool = OS.get_name() == "OSX"
	var submenus = {}
	var menu_name_length = menu_name.length()
	menu.clear()

	if !menu.is_connected("id_pressed", self, "on_menu_id_pressed"):
		menu.connect("id_pressed", self, "on_menu_id_pressed", [ menu_def, object ])
	for i in menu_def.size():
		if menu_def[i].has("standalone_only") and menu_def[i].standalone_only and Engine.editor_hint:
			continue
		if menu_def[i].has("editor_only") and menu_def[i].editor_only and !Engine.editor_hint:
			continue
		if menu_def[i].has("mode") and menu_def[i].mode != mode:
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
	if !menu.is_connected("about_to_show", self, "on_menu_about_to_show"):
		menu.connect("about_to_show", self, "on_menu_about_to_show", [ menu_def, object, menu_name, menu ])
	return menu

func on_menu_id_pressed(id, menu_def, object) -> void:
	if menu_def[id].has("command"):
		var command = menu_def[id].command
		if object.has_method(command):
			var parameters = []
			if menu_def[id].has("command_parameter"):
				parameters.append(menu_def[id].command_parameter)
			if menu_def[id].has("toggle") and menu_def[id].toggle:
				parameters.append(!object.callv(command, parameters))
			object.callv(command, parameters)

func on_menu_about_to_show(menu_def, object, name : String, menu : PopupMenu) -> void:
	var mode = ""
	if object.has_method("get_current_mode"):
		mode = object.get_current_mode()
	for i in menu_def.size():
		if menu_def[i].menu != name:
			continue
		if menu_def[i].has("submenu"):
			pass
		elif menu_def[i].has("command"):
			var item : int = menu.get_item_index(i)
			var command = menu_def[i].command+"_is_disabled"
			if object.has_method(command):
				var is_disabled = object.call(command)
				menu.set_item_disabled(item, is_disabled)
			if menu_def[i].has("mode"):
				menu.set_item_disabled(item, menu_def[i].mode != mode)
			if menu_def[i].has("toggle") and menu_def[i].toggle:
				command = menu_def[i].command
				var parameters = []
				if menu_def[i].has("command_parameter"):
					parameters.append(menu_def[i].command_parameter)
				if object.has_method(command):
					menu.set_item_checked(item, object.callv(command, parameters))

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
	if !do_load_project(recent_files[id]):
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


func create_menu_export_material(menu : PopupMenu, prefix : String = "") -> void:
	if prefix == "":
		menu.clear()
		menu.set_size(Vector2(0, 0))
		for sm in menu.get_children():
			menu.remove_child(sm)
			sm.free()
	var project = get_current_project()
	if project != null:
		var material_node = project.get_material_node()
		var prefix_len = prefix.length()
		var submenus = []
		for id in range(material_node.get_export_profiles().size()):
			var p : String = material_node.get_export_profiles()[id]
			if p.left(prefix_len) != prefix:
				continue
			p = p.right(prefix_len)
			var slash_position = p.find("/")
			if slash_position == -1:
				menu.add_item(p, id)
			else:
				var submenu_name = p.left(slash_position)
				if submenus.find(submenu_name) == -1:
					var submenu = PopupMenu.new()
					submenu.name = submenu_name
					menu.add_child(submenu)
					create_menu_export_material(submenu, p.left(slash_position+1))
					menu.add_submenu_item(submenu_name, submenu_name, id)
					submenus.push_back(submenu_name)
		if !menu.is_connected("id_pressed", self, "_on_ExportMaterial_id_pressed"):
			menu.connect("id_pressed", self, "_on_ExportMaterial_id_pressed")

func export_profile_config_key(profile : String) -> String:
	var key = "export_"+profile.to_lower().replace(" ", "_")
	return key

func export_material(file_path : String, profile : String) -> void:
	var project = get_current_project()
	if project == null:
		return
	config_cache.set_value("path", export_profile_config_key(profile), file_path.get_base_dir())
	var export_prefix = file_path.trim_suffix("."+file_path.get_extension())
	project.export_material(export_prefix, profile)

func _on_ExportMaterial_id_pressed(id) -> void:
	var project = get_current_project()
	if project == null:
		return
	var material_node = project.get_material_node()
	if material_node == null:
		return
	var profile = material_node.get_export_profiles()[id]
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*."+material_node.get_export_extension(profile)+";"+profile+" Material")
	var config_key = export_profile_config_key(profile)
	if config_cache.has_section_key("path", config_key):
		dialog.current_dir = config_cache.get_value("path", config_key)
	add_child(dialog)
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		export_material(files[0], profile)


func create_menu_set_theme(menu) -> void:
	menu.clear()
	for t in THEMES:
		menu.add_item(t)
	if !menu.is_connected("id_pressed", self, "_on_SetTheme_id_pressed"):
		menu.connect("id_pressed", self, "_on_SetTheme_id_pressed")

func set_theme(theme_name) -> void:
	theme = load("res://material_maker/theme/"+theme_name+".tres")
	$NodeFactory.on_theme_changed()

func _on_SetTheme_id_pressed(id) -> void:
	var theme_name : String = THEMES[id].to_lower()
	set_theme(theme_name)
	config_cache.set_value("window", "theme", theme_name)


func create_menu_show_panels(menu : PopupMenu) -> void:
	menu.clear()
	var panels = layout.get_panel_list()
	for i in range(panels.size()):
		menu.add_check_item(panels[i], i)
		menu.set_item_checked(i, layout.is_panel_visible(panels[i]))
	if !menu.is_connected("id_pressed", self, "_on_ShowPanels_id_pressed"):
		menu.connect("id_pressed", self, "_on_ShowPanels_id_pressed")

func _on_ShowPanels_id_pressed(id) -> void:
	var panel : String = layout.get_panel_list()[id]
	layout.set_panel_visible(panel, !layout.is_panel_visible(panel))


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


func new_graph_panel() -> GraphEdit:
	var graph_edit = preload("res://material_maker/panels/graph_edit/graph_edit.tscn").instance()
	graph_edit.node_factory = $NodeFactory
	projects.add_child(graph_edit)
	projects.current_tab = graph_edit.get_index()
	return graph_edit

func new_material() -> void:
	var graph_edit = new_graph_panel()
	graph_edit.new_material()
	graph_edit.update_tab_title()
	hierarchy.update_from_graph_edit(get_current_graph_edit())

func new_paint_project(obj_file_name = null) -> void:
	# Prevent opening the New Paint Project dialog several times by pressing the keyboard shortcut.
	if get_node_or_null("NewPainterWindow") != null:
		return

	var new_painter_dialog = preload("res://material_maker/windows/new_painter/new_painter.tscn").instance()
	add_child(new_painter_dialog)
	var result = new_painter_dialog.ask(obj_file_name)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	if result == null:
		return
	var paint_panel = load("res://material_maker/panels/paint/paint.tscn").instance()
	projects.add_child(paint_panel)
	paint_panel.init_project(result.mesh, result.mesh_filename, result.size, result.project_filename)
	projects.current_tab = paint_panel.get_index()

func load_project() -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILES
	dialog.add_filter("*.ptex;Procedural Textures File")
	dialog.add_filter("*.mmpp;Model Painting File")
	if config_cache.has_section_key("path", "project"):
		dialog.current_dir = config_cache.get_value("path", "project")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		do_load_projects(files)

func do_load_projects(filenames) -> void:
	var file_name : String = ""
	for f in filenames:
		var file = File.new()
		if file.open(f, File.READ) != OK:
			continue
		file_name = file.get_path_absolute()
		file.close()
		do_load_project(file_name)
	if file_name != "":
		config_cache.set_value("path", "project", file_name.get_base_dir())

func do_load_project(file_name) -> void:
	var status : bool = false
	match file_name.get_extension():
		"ptex":
			status = do_load_material(file_name, false)
			hierarchy.update_from_graph_edit(get_current_graph_edit())
		"mmpp":
			status = do_load_painting(file_name)
	if status:
		add_recent(file_name)

func do_load_material(filename : String, update_hierarchy : bool = true) -> bool:
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
		graph_edit = new_graph_panel()
	graph_edit.load_file(filename)
	if update_hierarchy:
		hierarchy.update_from_graph_edit(get_current_graph_edit())
	return true

func do_load_painting(filename : String) -> bool:
	var paint_panel = load("res://material_maker/panels/paint/paint.tscn").instance()
	projects.add_child(paint_panel)
	var status : bool = paint_panel.load_project(filename)
	projects.current_tab = paint_panel.get_index()
	return status

func load_material_from_website() -> void:
	var dialog = load("res://material_maker/windows/load_from_website/load_from_website.tscn").instance()
	add_child(dialog)
	var result = dialog.select_material()
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	if result == "":
		return
	new_material()
	var graph_edit = get_current_graph_edit()
	var new_generator = mm_loader.create_gen(JSON.parse(result).result)
	graph_edit.set_new_generator(new_generator)
	hierarchy.update_from_graph_edit(graph_edit)

func save_project(project : Control = null) -> bool:
	if project == null:
		project = get_current_project()
	if project != null:
		return project.save()
	return false

func save_project_as(project : Control = null) -> bool:
	if project == null:
		project = get_current_project()
	if project != null:
		return project.save_as()
	return false

func save_all_projects() -> void:
	for i in range(projects.get_tab_count()):
		var result = projects.get_tab(i).save()
		while result is GDScriptFunctionState:
			result = yield(result, "completed")

func close_project() -> void:
	projects.close_tab()

func quit() -> void:
	if quitting:
		return
	quitting = true
	var dialog = preload("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instance()
	dialog.dialog_text = "Quit Material Maker?"
	dialog.add_cancel("Cancel")
	add_child(dialog)
	if get_config("confirm_quit"):
		var result = dialog.ask()
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == "cancel":
			quitting = false
			return
	if get_config("confirm_close_project"):
		var result = $VBoxContainer/Layout/SplitRight/ProjectsPanel/Projects.check_save_tabs()
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		if !result:
			quitting = false
			return
	dim_window()
	get_tree().quit()
	quitting = false


func edit_cut() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.cut()

func edit_undo() -> void:
	var project = get_current_project()
	if project != null and project.get("undoredo") != null:
		project.undoredo.undo()

func edit_undo_is_disabled() -> bool:
	var project = get_current_project()
	if project != null and project.get("undoredo") != null:
		return !project.undoredo.can_undo()
	return true

func edit_redo() -> void:
	var project = get_current_project()
	if project != null and project.get("undoredo") != null:
		project.undoredo.redo()

func edit_redo_is_disabled() ->  bool:
	var project = get_current_project()
	if project != null and project.get("undoredo") != null:
		return !project.undoredo.can_redo()
	return true

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
	return validate_json(OS.clipboard) == ""

func edit_duplicate() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.duplicate_selected()

func edit_select_all() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.select_all()

func edit_select_none() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.select_none()

func edit_select_invert() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.select_invert()

func edit_duplicate_is_disabled() -> bool:
	return edit_cut_is_disabled()

func edit_load_selection() -> void:
	var graph_edit = get_current_graph_edit()
	if graph_edit == null:
		return
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.mms;Material Maker Selection")
	if config_cache.has_section_key("path", "selection"):
		dialog.current_dir = config_cache.get_value("path", "selection")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		config_cache.set_value("path", "selection", files[0].get_base_dir())
		var file = File.new()
		if file.open(files[0], File.READ) == OK:
			graph_edit.do_paste(parse_json(file.get_as_text()))
			file.close()

func edit_save_selection() -> void:
	var graph_edit = get_current_graph_edit()
	if graph_edit == null:
		return
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.mms;Material Maker Selection")
	if config_cache.has_section_key("path", "selection"):
		dialog.current_dir = config_cache.get_value("path", "selection")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		config_cache.set_value("path", "selection", files[0].get_base_dir())
		var file = File.new()
		if file.open(files[0], File.WRITE) == OK:
			file.store_string(to_json(graph_edit.serialize_selection()))
			file.close()

func edit_preferences() -> void:
	var dialog = load("res://material_maker/windows/preferences/preferences.tscn").instance()
	add_child(dialog)
	dialog.connect("config_changed", self, "on_config_changed")
	dialog.edit_preferences(config_cache)

func view_center() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	graph_edit.center_view()

func view_reset_zoom() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	graph_edit.zoom = 1

func toggle_side_panels() -> void:
	$VBoxContainer/Layout.toggle_side_panels()


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

func create_menu_add_to_library(menu, manager, function) -> void:
	var gens = mm_loader.get_generator_list()
	menu.clear()
	for i in manager.get_child_count():
		var library = manager.get_child(i)
		if ! library.read_only:
			menu.add_item(library.library_name, i)
	if !menu.is_connected("id_pressed", self, function):
		menu.connect("id_pressed", self, function)

func create_menu_add_selection_to_library(menu) -> void:
	create_menu_add_to_library(menu, node_library_manager, "add_selection_to_library")

func add_selection_to_library(index) -> void:
	var selected_nodes = get_selected_nodes()
	if selected_nodes.empty():
		return
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
	add_child(dialog)
	var current_item_name = ""
	if library.is_inside_tree():
		current_item_name = library.get_selected_item_name()
	var status = dialog.enter_text("New library element", "Select a name for the new library element", current_item_name)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	if ! status.ok:
		return
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	var data
	if selected_nodes.size() == 1:
		data = selected_nodes[0].generator.serialize()
		data.erase("node_position")
	elif graph_edit != null:
		data = graph_edit.serialize_selection()
	# Create thumbnail
	var result = selected_nodes[0].generator.render(self, 0, 64, true)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	var image : Image = result.get_image()
	result.release(self)
	node_library_manager.add_item_to_library(index, status.text, image, data)

func create_menu_add_brush_to_library(menu) -> void:
	create_menu_add_to_library(menu, brush_library_manager, "add_brush_to_library")

func add_brush_to_library(index) -> void:
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
	add_child(dialog)
	var status = dialog.enter_text("New library element", "Select a name for the new library element", brushes.get_selected_item_name())
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	if ! status.ok:
		return
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	var data = graph_edit.top_generator.serialize()
	# Create thumbnail
	var result = get_current_project().get_brush_preview()
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	var image : Image = Image.new()
	image.copy_from(result.get_data())
	image.resize(32, 32)
	brush_library_manager.add_item_to_library(index, status.text, image, data)

func paint_project_settings():
	var dialog = load("res://material_maker/panels/paint/paint_project_settings.tscn").instance()
	add_child(dialog)
	dialog.edit_settings(get_current_project())

func create_menu_paint_environment(menu) -> void:
	get_node("/root/MainWindow/EnvironmentManager").create_environment_menu(menu)
	if !menu.is_connected("id_pressed", self, "_on_PaintEnvironment_id_pressed"):
		menu.connect("id_pressed", self, "_on_PaintEnvironment_id_pressed")

func _on_PaintEnvironment_id_pressed(id) -> void:
	var paint = get_current_project()
	if paint != null:
		paint.set_environment(id)


func environment_editor() -> void:
	add_child(load("res://material_maker/windows/environment_editor/environment_editor.tscn").instance())

# -----------------------------------------------------------------------
#                             Help menu
# -----------------------------------------------------------------------

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
		var dir : Directory = Directory.new()
		var doc_name = library.get_selected_item_doc_name()
		while doc_name != "":
			var doc_path : String = doc_dir+"/node_"+doc_name+".html"
			if dir.file_exists(doc_path):
				OS.shell_open(doc_path)
				break
			doc_name = doc_name.left(doc_name.rfind("_"))

func show_library_item_doc_is_disabled() -> bool:
	return get_doc_dir() == "" or !library.is_inside_tree() or library.get_selected_item_doc_name() == ""

func bug_report() -> void:
	OS.shell_open("https://github.com/RodZill4/godot-procedural-textures/issues")

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

func get_current_node(graph_edit : MMGraphEdit) -> Node:
	for n in graph_edit.get_children():
		if n is GraphNode and n.selected:
			return n
	return null

func update_preview_2d() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		for i in range(2):
			var preview = graph_edit.get_current_preview(i)
			if preview != null:
				preview_2d[i].set_generator(preview.generator, preview.output_index)
				if i == 0:
					histogram.set_generator(preview.generator, preview.output_index)
					preview_2d_background.set_generator(preview.generator, preview.output_index)
			else:
				preview_2d[i].set_generator(null)
				if i == 0:
					histogram.set_generator(null)
					preview_2d_background.set_generator(null)

func update_preview_3d(previews : Array, sequential = false) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null and graph_edit.top_generator != null and graph_edit.top_generator.has_node("Material"):
		var gen_material = graph_edit.top_generator.get_node("Material")
		var status = gen_material.update()
		if sequential:
			while status is GDScriptFunctionState:
				yield(status, "completed")
		for p in previews:
			status = gen_material.update_materials(p.get_materials(), sequential)
			if sequential:
				while status is GDScriptFunctionState:
					status = yield(status, "completed")

func on_preview_changed(graph) -> void:
	if graph == get_current_graph_edit():
		update_preview_2d()

func _on_Projects_tab_changed(_tab) -> void:
	var project = get_current_project()
	if project.has_method("project_selected"):
		project.call("project_selected")
	var new_tab = projects.get_current_tab_control()
	if new_tab != current_tab:
		for c in get_incoming_connections():
			if c.method_name == "update_preview" or c.method_name == "update_preview_2d":
				c.source.disconnect(c.signal_name, self, c.method_name)
		var new_graph_edit = null
		if new_tab is GraphEdit:
			new_graph_edit = new_tab
			$VBoxContainer/Layout/SplitRight/ProjectsPanel/BackgroundPreviews.show()
			$VBoxContainer/Layout/SplitRight/ProjectsPanel/PreviewUI.show()
			set_current_mode("material")
		else:
			if new_tab.has_method("get_graph_edit"):
				new_graph_edit = new_tab.get_graph_edit()
			$VBoxContainer/Layout/SplitRight/ProjectsPanel/BackgroundPreviews.hide()
			$VBoxContainer/Layout/SplitRight/ProjectsPanel/PreviewUI.hide()
			set_current_mode("paint")
		current_tab = new_tab
		if new_graph_edit != null:
			new_graph_edit.connect("graph_changed", self, "update_preview")
			if !new_graph_edit.is_connected("preview_changed", self, "on_preview_changed"):
				new_graph_edit.connect("preview_changed", self, "on_preview_changed")
			update_preview()
		if new_tab is GraphEdit:
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
	match what:
		MainLoop.NOTIFICATION_WM_FOCUS_OUT:
			# Limit FPS to decrease CPU/GPU usage while the window is unfocused.
			OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(get_config("idle_fps_limit"), IDLE_FPS_LIMIT_MIN, IDLE_FPS_LIMIT_MAX)) * 1_000_000
		MainLoop.NOTIFICATION_WM_FOCUS_IN:
			# Return to the normal FPS limit when the window is focused.
			OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(get_config("fps_limit"), FPS_LIMIT_MIN, FPS_LIMIT_MAX)) * 1_000_000
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			yield(get_tree(), "idle_frame")
			quit()


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

func generate_graph_screenshot():
	# Prompt for a target PNG file
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image file")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() != 1:
		return
	# Generate the image
	var graph_edit : GraphEdit = get_current_graph_edit()
	var minimap_save : bool = graph_edit.minimap_enabled
	graph_edit.minimap_enabled = false
	var save_scroll_offset : Vector2 = graph_edit.scroll_offset
	var save_zoom : float = graph_edit.zoom
	graph_edit.zoom = 1
	yield(get_tree(), "idle_frame")
	var graph_edit_rect = graph_edit.get_global_rect()
	graph_edit_rect = Rect2(graph_edit_rect.position+Vector2(15, 80), graph_edit_rect.size-Vector2(30, 180))
	var graph_rect = null
	for c in graph_edit.get_children():
		if c is GraphNode:
			var node_rect = Rect2(c.rect_global_position, c.rect_size)
			if graph_rect == null:
				graph_rect = node_rect
			else:
				graph_rect = graph_rect.expand(node_rect.position)
				graph_rect = graph_rect.expand(node_rect.end)
	graph_rect = graph_rect.grow_individual(50, 20, 50, 80)
	var image : Image = Image.new()
	image.create(graph_rect.size.x, graph_rect.size.y, false, get_viewport().get_texture().get_data().get_format())
	var origin = graph_edit.scroll_offset+graph_rect.position-graph_edit_rect.position
	var small_image : Image = Image.new()
	small_image.create(graph_edit_rect.size.x, graph_edit_rect.size.y, false, get_viewport().get_texture().get_data().get_format())
	for x in range(0, graph_rect.size.x, graph_edit_rect.size.x):
		for y in range(0, graph_rect.size.y, graph_edit_rect.size.y):
			graph_edit.scroll_offset = origin+Vector2(x, y)
			var timer : Timer = Timer.new()
			add_child(timer)
			timer.wait_time = 0.05
			timer.one_shot = true
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
			small_image.blit_rect(get_viewport().get_texture().get_data(), graph_edit_rect, Vector2(0, 0))
			small_image.flip_y()
			image.blit_rect(small_image, Rect2(Vector2(0, 0), graph_edit_rect.size), Vector2(x, y))
	graph_edit.scroll_offset = save_scroll_offset
	graph_edit.zoom = save_zoom
	image.save_png(files[0])
	graph_edit.minimap_enabled = minimap_save

# Handle dropped files

func get_controls_at_position(pos : Vector2, parent : Control) -> Array:
	var return_value = []
	for c in parent.get_children():
		if c is Control and c.visible and c.get_global_rect().has_point(pos):
			for n in get_controls_at_position(pos, c):
				return_value.append(n)
	if return_value.empty():
		return_value.append(parent)
	return return_value

func on_files_dropped(files : PoolStringArray, _screen) -> void:
	var file : File = File.new()
	for f in files:
		if file.open(f, File.READ) != OK:
			continue
		f = file.get_path_absolute()
		match f.get_extension():
			"ptex":
				do_load_material(f)
			"obj":
				var result = new_paint_project(f)
				while result is GDScriptFunctionState:
					result = yield(result, "completed")
			"bmp", "exr", "hdr", "jpg", "jpeg", "png", "svg", "tga", "webp":
				var controls : Array = get_controls_at_position(get_global_mouse_position(), self)
				while ! controls.empty():
					var next_controls = []
					for control in controls:
						if control == null:
							continue
						if control.has_method("on_drop_image_file"):
							control.on_drop_image_file(f)
							return
						if control.get_parent() != self:
							next_controls.append(control.get_parent())
					controls = next_controls

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
