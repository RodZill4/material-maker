extends Control

var quitting : bool = false

var recent_files = []

var current_tab = null

var updating : bool = false
var need_update : bool = false

# The resolution scale to use for 3D previews.
# Values above 1.0 enable supersampling. This has a significant performance cost
# but greatly improves texture rendering quality, especially when using
# specular/parallax mapping and when viewed at oblique angles.
var preview_rendering_scale_factor : float = 2.0

# The number of subdivisions to use for tesselated 3D previews. Higher values
# result in more detailed bumps but are more demanding to render.
# This doesn't apply to non-tesselated 3D previews which use parallax occlusion mapping.
var preview_tesselation_detail : int = 256

@onready var node_library_manager = $NodeLibraryManager
@onready var brush_library_manager = $BrushLibraryManager


@onready var projects_panel = $VBoxContainer/Layout/FlexibleLayout/Main

@onready var layout = $VBoxContainer/Layout
var library
var preview_2d : Array
var histogram
var preview_3d
var hierarchy
var brushes


var current_mesh : Mesh = null


const FPS_LIMIT_MIN = 20
const FPS_LIMIT_MAX = 500
const IDLE_FPS_LIMIT_MIN = 1
const IDLE_FPS_LIMIT_MAX = 100

const RECENT_FILES_COUNT = 15

const THEMES = ["Default Dark", "Default Light", "Classic"]

const MENU : Array[Dictionary] = [
	{ menu="File/New material", command="new_material", shortcut="Control+N" },
	{ menu="File/New paint project", command="new_paint_project", shortcut="Control+Shift+N", not_in_ports=["HTML5"] },
	{ menu="File/Load", command="load_project", shortcut="Control+O" },
	{ menu="File/Load material from website", command="load_material_from_website" },
	{ menu="File/Load recent", submenu="load_recent", standalone_only=true, not_in_ports=["HTML5"] },
	{ menu="File/-" },
	{ menu="File/Save", command="save_project", shortcut="Control+S" },
	{ menu="File/Save as...", command="save_project_as", shortcut="Control+Shift+S" },
	{ menu="File/Save all...", command="save_all_projects", not_in_ports=["HTML5"] },
	{ menu="File/-" },
	{ menu="File/Export again", command="export_again", shortcut="Control+E", not_in_ports=["HTML5"] },
	{ menu="File/Export material", submenu="export_material", not_in_ports=["HTML5"] },
	{ menu="File/-" },
	{ menu="File/Close", command="close_project", shortcut="Control+Shift+Q" },
	{ menu="File/Quit", command="quit", shortcut="Control+Q", not_in_ports=["HTML5"] },

	{ menu="Edit/Undo", command="edit_undo", shortcut="Control+Z" },
	{ menu="Edit/Redo", command="edit_redo", shortcut="Control+Shift+Z" },
	{ menu="Edit/-" },
	{ menu="Edit/Cut", command="edit_cut", shortcut="Control+X" },
	{ menu="Edit/Copy", command="edit_copy", shortcut="Control+C" },
	{ menu="Edit/Paste", command="edit_paste", shortcut="Control+V" },
	{ menu="Edit/Duplicate", command="edit_duplicate", shortcut="Control+D" },
	{ menu="Edit/Duplicate with inputs", command="edit_duplicate_with_inputs", shortcut="Control+Shift+D" },
	{ menu="Edit/-" },
	{ menu="Edit/Select All", command="edit_select_all", shortcut="Control+A" },
	{ menu="Edit/Select None", command="edit_select_none", shortcut="Control+Shift+A" },
	{ menu="Edit/Invert Selection", command="edit_select_invert", shortcut="Control+I" },
	{ menu="Edit/Select Sources", command="edit_select_sources", shortcut="Control+L" },
	{ menu="Edit/Select Targets", command="edit_select_targets", shortcut="Control+Shift+L" },
	{ menu="Edit/-" },
	{ menu="Edit/Load Selection", command="edit_load_selection", not_in_ports=["HTML5"] },
	{ menu="Edit/Save Selection", command="edit_save_selection", not_in_ports=["HTML5"] },
	{ menu="Edit/-" },
	{ menu="Edit/Set theme", submenu="set_theme" },
	{ menu="Edit/Preferences", command="edit_preferences", shortcut="Control+Comma" },

	{ menu="View/Center view", command="view_center", shortcut="C" },
	{ menu="View/Reset zoom", command="view_reset_zoom", shortcut="Control+0" },
	{ menu="View/-" },
	# { menu="View/Show or Hide side panels", command="toggle_side_panels", shortcut="Control+Space" },
	{ menu="View/Panels", submenu="show_panels" },

	{ menu="Tools/Create", submenu="create" },
	{ menu="Tools/Create group", command="create_subgraph", shortcut="Control+G" },
	{ menu="Tools/Make selected nodes editable", command="make_selected_nodes_editable", shortcut="Control+W" },
	{ menu="Tools/-" },
	{ menu="Tools/Add selected node to library", submenu="add_selection_to_library", mode="material" },
	{ menu="Tools/Add current brush to library", submenu="add_brush_to_library", mode="paint", not_in_ports=["HTML5"] },
	{ menu="Tools/Create a screenshot of the current graph", command="generate_graph_screenshot", mode="material" },
	{ menu="Tools/Paint project settings", command="paint_project_settings", mode="paint", not_in_ports=["HTML5"] },
	{ menu="Tools/Set painting environment", submenu="paint_environment", mode="paint", not_in_ports=["HTML5"] },
	{ menu="Tools/-" },
	{ menu="Tools/Environment editor", command="environment_editor", not_in_ports=["HTML5"] },
	#{ menu="Tools/Generate screenshots for the library nodes", command="generate_screenshots", mode="material" },

	{ menu="Help/User manual", command="show_doc", shortcut="F1" },
	{ menu="Help/Show selected library item documentation", command="show_library_item_doc", shortcut="Control+F1" },
	{ menu="Help/Report a bug", command="bug_report" },
	{ menu="Help/" },
	{ menu="Help/About", command="about" }
]


func _enter_tree() -> void:
	mm_globals.main_window = self

func _ready() -> void:
	get_window().borderless = false
	get_window().transparent = false
	get_window().grab_focus()
	get_window().gui_embed_subwindows = false

	get_window().close_requested.connect(self.on_close_requested)

	get_tree().set_auto_accept_quit(false)

	if mm_globals.get_config("locale") == "":
		mm_globals.set_config("locale", TranslationServer.get_locale())

	on_config_changed()

	# Set a minimum window size to prevent UI elements from collapsing on each other.
	get_window().min_size = Vector2(1024, 600)

	# Restore the window position/size if values are present in the configuration cache
	if mm_globals.config.has_section_key("window", "screen"):
		get_window().current_screen = mm_globals.config.get_value("window", "screen")

	if mm_globals.config.has_section_key("window", "maximized"):
		get_window().mode = Window.MODE_MAXIMIZED if (mm_globals.config.get_value("window", "maximized")) else Window.MODE_WINDOWED

	if get_window().mode != Window.MODE_MAXIMIZED:
		if mm_globals.config.has_section_key("window", "position"):
			get_window().position = mm_globals.config.get_value("window", "position")
		else:
			get_window().min_size *= get_window().content_scale_factor
			get_window().move_to_center()
		if mm_globals.config.has_section_key("window", "size"):
			get_window().size = mm_globals.config.get_value("window", "size")

	# Restore the theme
	var theme_name: String = "default dark"
	if mm_globals.config.has_section_key("window", "theme"):
		theme_name = mm_globals.config.get_value("window", "theme")
	change_theme(theme_name)

	# In HTML5 export, copy all examples to the filesystem
	if OS.get_name() == "HTML5":
		print("Copying samples")
		DirAccess.open("res://").make_dir("/examples")
		var dir : DirAccess = DirAccess.open("res://material_maker/examples/")
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		while true:
			var f = dir.get_next()
			if f == "":
				break
			if f.ends_with(".ptex"):
				print(f)
				dir.copy("res://material_maker/examples/"+f, "/examples/"+f)

	# Set window title
	get_window().set_title(ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/actual_release"))

	layout.load_panels()
	library = get_panel("Library")
	preview_2d = [ get_panel("Preview2D"), get_panel("Preview2D (2)") ]
	histogram = get_panel("Histogram")
	preview_3d = get_panel("Preview3D")
	preview_3d.connect("need_update", self.update_preview_3d)
	hierarchy = get_panel("Hierarchy")
	hierarchy.connect("group_selected", self.on_group_selected)
	brushes = get_panel("Brushes")

	# Load recent projects
	load_recents()

	get_window().connect("files_dropped", self.on_files_dropped)

	var args : PackedStringArray = OS.get_cmdline_args()
	for a in args:
		if a.get_extension().to_lower() in [ "ptex", "mmpp" ]:
			do_load_project(get_file_absolute_path(a))
		elif a.get_extension().to_lower() in [ "obj", "glb", "gltf" ]:
			var mesh_filename : String = get_file_absolute_path(a)
			if mesh_filename == "":
				push_error("Cannot load mesh from '%s' (no such file or directory)" % a)
				continue
			var mesh : Mesh = MMMeshLoader.load_mesh(mesh_filename)
			if mesh == null:
				push_error("Cannot load mesh from '%s'" % mesh_filename)
				continue
			var project_filename : String = mesh_filename.get_basename()+".mmpp"
			create_paint_project(mesh, mesh_filename, 1024, project_filename)

	# Rescue unsaved projects
	if true:
		var dir : DirAccess = DirAccess.open("user://unsaved_projects")
		if dir != null:
			var files : Array = []
			dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			var file_name = dir.get_next()
			while file_name != "":
				if !dir.current_is_dir() and file_name.get_extension() == "mmcr":
					files.append("user://unsaved_projects".path_join(file_name))
				file_name = dir.get_next()
			if ! files.is_empty():
				var dialog_text : String = "Oops, it seems Material Maker crashed and rescued unsaved work\nLoad %d unsaved projects?" % files.size()
				var result = await accept_dialog(dialog_text, true, false, [ { label="Delete them!", action="delete" } ])
				match result:
					"ok":
						for f in files:
							var graph_edit = new_graph_panel()
							graph_edit.load_from_recovery(f)
							graph_edit.update_tab_title()
						hierarchy.update_from_graph_edit(get_current_graph_edit())
					"delete":
						for f in files:
							DirAccess.remove_absolute(f)

	if get_current_graph_edit() == null:
		await get_tree().process_frame
		new_material()

	size = get_window().size
	position = Vector2.ZERO
	set_anchors_preset(Control.PRESET_FULL_RECT)
	update_menus()

	mm_logger.message("Material Maker "+ProjectSettings.get_setting("application/config/actual_release"))

	size = get_viewport().size/get_viewport().content_scale_factor
	position = Vector2i(0, 0)


var menu_update_requested : bool = false

func update_menus() -> void:
	if ! menu_update_requested:
		menu_update_requested = true
		do_update_menus.call_deferred()

func do_update_menus() -> void:
	# Create menus
	var menu_bar_class
	if OS.get_name() == "macOS" and mm_globals.get_config("prefer_global_menu"):
		menu_bar_class = mm_globals.menu_manager.MenuBarDisplayServer
	else:
		menu_bar_class = mm_globals.menu_manager.MenuBarGodot
	var menu_bar = menu_bar_class.new($VBoxContainer/TopBar/Menu)
	mm_globals.menu_manager.create_menus(MENU, self, menu_bar)
	menu_update_requested = false

func _exit_tree() -> void:
	# Save the window position and size to remember it when restarting the application
	mm_globals.config.set_value("window", "screen", get_window().current_screen)
	mm_globals.config.set_value("window", "maximized", (get_window().mode == Window.MODE_MAXIMIZED) || ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)))
	mm_globals.config.set_value("window", "position", get_window().position)
	mm_globals.config.set_value("window", "size", get_window().size)
	layout.save_config()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		match get_window().mode:
			Window.MODE_EXCLUSIVE_FULLSCREEN, Window.MODE_FULLSCREEN, Window.MODE_MAXIMIZED:
				get_window().mode = Window.MODE_WINDOWED
			_:
				get_window().mode = Window.MODE_MAXIMIZED

func on_config_changed() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (mm_globals.get_config("vsync")) else DisplayServer.VSYNC_DISABLED)
	# Convert FPS to microseconds per frame.
	# Clamp the FPS to reasonable values to avoid locking up the UI.
	@warning_ignore("narrowing_conversion")
	OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(mm_globals.get_config("fps_limit"), FPS_LIMIT_MIN, FPS_LIMIT_MAX)) * 1_000_000
	# locale
	var locale = mm_globals.get_config("locale")
	if locale != "" and locale != TranslationServer.get_locale():
		TranslationServer.set_locale(locale)
		get_tree().call_group("updated_from_locale", "update_from_locale")
		if OS.get_name() == "macOS":
			mm_globals.main_window.update_menus()

	var ui_scale = mm_globals.get_config("ui_scale")
	if ui_scale <= 0:
		# If scale is set to 0 (auto), scale everything if the display requires it (crude hiDPI support).
		# This prevents UI elements from being too small on hiDPI displays.
		ui_scale = 2 if DisplayServer.screen_get_dpi() >= 192 and DisplayServer.screen_get_size().x >= 2048 else 1
	get_viewport().content_scale_factor = ui_scale
	size = get_viewport().size/get_viewport().content_scale_factor
	position = Vector2i(0, 0)
	#ProjectSettings.set_setting("display/window/stretch/scale", scale)

	# Clamp to reasonable values to avoid crashes on startup.
	preview_rendering_scale_factor = clamp(mm_globals.get_config("ui_3d_preview_resolution"), 1.0, 2.0)
	update_preview_3d([ preview_3d, projects_panel.preview_3d_background ])

	@warning_ignore("narrowing_conversion")
	preview_tesselation_detail = clamp(mm_globals.get_config("ui_3d_preview_tesselation_detail"), 16, 1024)

func get_panel(panel_name : String) -> Control:
	return layout.get_panel(panel_name)

func get_current_project() -> Control:
	return projects_panel.get_projects().get_current_tab_control()

func get_current_graph_edit() -> MMGraphEdit:
	if projects_panel == null:
		return null
	var graph_edit = projects_panel.get_projects().get_current_tab_control()
	if graph_edit != null and graph_edit.has_method("get_graph_edit"):
		return graph_edit.get_graph_edit()
	return null

func get_share_button():
	return %Share

# Modes

var current_mode : String = ""

func get_current_mode() -> String:
	return current_mode

func set_current_mode(mode : String) -> void:
	current_mode = mode
	layout.change_mode(current_mode)

# Menus

func create_menu_load_recent(menu) -> void:
	menu.clear()
	if recent_files.is_empty():
		menu.add_item("No items found", 0)
		menu.set_item_disabled(0, true)
	else:
		for i in recent_files.size():
			menu.add_item(recent_files[i], i)
		menu.connect_id_pressed(self._on_LoadRecent_id_pressed)

func _on_LoadRecent_id_pressed(id) -> void:
	do_load_project(recent_files[id])

func load_recents() -> void:
	var f : FileAccess = FileAccess.open("user://recent_files.bin", FileAccess.READ)
	if f != null:
		var test_json_conv = JSON.new()
		test_json_conv.parse(f.get_as_text())
		recent_files = test_json_conv.get_data()

func save_recents() -> void:
	var f : FileAccess = FileAccess.open("user://recent_files.bin", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(recent_files))
	update_menus()

func add_recent(path, save = true) -> void:
	remove_recent(path, false)
	recent_files.push_front(path)
	while recent_files.size() > RECENT_FILES_COUNT:
		recent_files.pop_back()
	if save:
		save_recents()

func remove_recent(path, save = true) -> void:
	while true:
		var index = recent_files.find(path)
		if index >= 0:
			recent_files.remove_at(index)
		else:
			break
	if save:
		save_recents()

func export_profile_config_key(profile : String) -> String:
	var key = "export_"+profile.to_lower().replace(" ", "_")
	return key

func export_material(file_path : String, profile : String) -> void:
	var project = get_current_project()
	if project == null:
		return
	mm_globals.config.set_value("path", export_profile_config_key(profile), file_path.get_base_dir())
	var export_prefix = file_path.trim_suffix("."+file_path.get_extension())
	project.export_material(export_prefix, profile)

func export_again_is_disabled() -> bool:
	var project = get_current_project()
	if project == null:
		return true
	var material_node = project.get_material_node()
	if material_node == null or material_node.get_last_export_target() == "":
		return true
	return false

func export_again() -> void:
	var project = get_current_project()
	if project == null:
		return
	var material_node = project.get_material_node()
	if material_node == null:
		return
	var export_target : String = material_node.get_last_export_target()
	if export_target == "":
		return
	var export_path : String = material_node.get_export_path(export_target)
	export_material(export_path, export_target)

func create_menu_export_material(menu : MMMenuManager.MenuBase, prefix : String = "", export_profiles = null) -> void:
	if prefix == "":
		menu.clear()
	var project = get_current_project()
	if project == null:
		return
	var material_node = project.get_material_node()
	if material_node == null:
		return
	var prefix_len = prefix.length()
	var submenus : Array[String] = []
	if export_profiles == null:
		export_profiles = material_node.get_export_profiles()
	for id in range(export_profiles.size()):
		var p : String = export_profiles[id]
		if prefix_len > 0:
			if p.left(prefix_len) != prefix:
				continue
			p = p.right(-prefix_len)
		var slash_position = p.find("/")
		if slash_position == -1:
			menu.add_item(p, id)
		else:
			var submenu_name : String = p.left(slash_position)
			if submenus.find(submenu_name) == -1:
				var submenu : MMMenuManager.MenuBase = menu.add_submenu(submenu_name)
				create_menu_export_material(submenu, p.left(slash_position+1), export_profiles)
				submenus.append(submenu_name)
	menu.connect_id_pressed(self._on_ExportMaterial_id_pressed)

func _on_ExportMaterial_id_pressed(id) -> void:
	var project = get_current_project()
	if project == null:
		return
	var material_node = project.get_material_node()
	if material_node == null:
		return
	var profile = material_node.get_export_profiles()[id]
	var export_extension : String = material_node.get_export_extension(profile)
	if export_extension == "":
		export_material("", profile)
	else:
		var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
		dialog.min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		var profile_name : String = profile
		var last_profile_name_slash : int = profile_name.rfind("/")
		if last_profile_name_slash != -1:
			profile_name = profile_name.right(-(last_profile_name_slash+1))
		dialog.add_filter("*."+export_extension+";"+profile_name+" Material")
		var last_export_path = material_node.get_export_path(profile)
		if last_export_path != "":
			dialog.current_path = last_export_path
		else:
			var config_key = export_profile_config_key(profile)
			if mm_globals.config.has_section_key("path", config_key):
				dialog.current_dir = mm_globals.config.get_value("path", config_key)
		add_child(dialog)
		var files = await dialog.select_files()
		if files.size() > 0:
			export_material(files[0], profile)


func create_menu_set_theme(menu : MMMenuManager.MenuBase) -> void:
	menu.clear()
	for t in THEMES:
		menu.add_item(t)
	menu.connect_id_pressed(self._on_SetTheme_id_pressed)

func change_theme(theme_name) -> void:
	if not ResourceLoader.exists("res://material_maker/theme/"+theme_name+".tres"):
		theme_name = "default dark"
	var _theme = load("res://material_maker/theme/"+theme_name+".tres")
	if _theme == theme:
		return
	if _theme is EnhancedTheme:
		_theme.update()
	await get_tree().process_frame
	theme = _theme
	if "classic" in theme_name:
		RenderingServer.set_default_clear_color(Color(0.14, 0.17,0.23))
	else:
		RenderingServer.set_default_clear_color(
				Color(0.48, 0.48, 0.48) if "light" in theme_name else Color(0.12, 0.12, 0.12))
	$NodeFactory.on_theme_changed()

func _on_SetTheme_id_pressed(id) -> void:
	var theme_name : String = THEMES[id].to_lower()
	change_theme(theme_name)
	mm_globals.config.set_value("window", "theme", theme_name)


func create_menu_show_panels(menu : MMMenuManager.MenuBase) -> void:
	menu.clear()
	var panels = layout.get_panel_list()
	for i in range(panels.size()):
		menu.add_check_item(panels[i], i)
		menu.set_item_checked(i, layout.is_panel_visible(panels[i]))
	menu.connect_id_pressed(self._on_ShowPanels_id_pressed)

func _on_ShowPanels_id_pressed(id) -> void:
	var panel : String = layout.get_panel_list()[id]
	layout.set_panel_visible(panel, not layout.is_panel_visible(panel))
	update_menus()

func create_menu_create(menu : MMMenuManager.MenuBase) -> void:
	var gens = mm_loader.get_generator_list()
	menu.clear()
	for i in gens.size():
		menu.add_item(gens[i], i)
	menu.connect_id_pressed(self._on_Create_id_pressed)

func _on_Create_id_pressed(id) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		var gens = mm_loader.get_generator_list()
		await graph_edit.create_gen_from_type(gens[id])


func new_graph_panel() -> GraphEdit:
	var graph_edit = preload("res://material_maker/panels/graph_edit/graph_edit.tscn").instantiate()
	graph_edit.node_factory = $NodeFactory
	projects_panel.get_projects().add_tab(graph_edit)
	projects_panel.get_projects().current_tab = graph_edit.get_index()
	return graph_edit

func new_material() -> void:
	var graph_edit = new_graph_panel()
	graph_edit.new_material()
	graph_edit.top_generator.set_current_mesh(current_mesh)
	graph_edit.update_tab_title()
	hierarchy.update_from_graph_edit(get_current_graph_edit())

func new_paint_project(obj_file_name = null) -> void:
	# Prevent opening the New Paint Project dialog several times by pressing the keyboard shortcut.
	if get_node_or_null("NewPainterWindow") != null:
		return

	var new_painter_dialog = preload("res://material_maker/windows/new_painter/new_painter.tscn").instantiate()
	var result = await new_painter_dialog.ask(obj_file_name)
	if ! result.has("mesh"):
		return
	create_paint_project(result.mesh, result.mesh_filename, result.size, result.project_filename)

func create_paint_project(mesh, mesh_filename, texture_size, project_filename):
	var paint_panel = load("res://material_maker/panels/paint/paint.tscn").instantiate()
	projects_panel.get_projects().add_tab(paint_panel)
	paint_panel.init_project(mesh, mesh_filename, texture_size, project_filename)
	projects_panel.get_projects().current_tab = paint_panel.get_index()

func load_project() -> void:
	if OS.get_name() == "HTML5":
		if ! Html5.is_connected("file_loaded", Callable(self, "on_html5_load_file")):
			Html5.connect("file_loaded", Callable(self, "on_html5_load_file"))
		Html5.load_file(".ptex")
	else:
		var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
		dialog.min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
		dialog.add_filter("*.ptex;Procedural Textures File")
		dialog.add_filter("*.mmpp;Model Painting File")
		if mm_globals.config.has_section_key("path", "project"):
			dialog.current_dir = mm_globals.config.get_value("path", "project")
		var files = await dialog.select_files()
		if files.size() > 0:
			do_load_projects(files)

func on_html5_load_file(file_name, _file_type, file_data):
	match file_name.get_extension():
		"ptex":
			if do_load_material_from_data(file_name, file_data, false):
				hierarchy.update_from_graph_edit(get_current_graph_edit())

func get_file_absolute_path(filename : String) -> String:
	var file : FileAccess = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		return ""
	return file.get_path_absolute()

func do_load_projects(filenames) -> void:
	var file_name : String = ""
	for f in filenames:
		f = get_file_absolute_path(f)
		if f != "":
			file_name = f
			do_load_project(file_name)
	if file_name != "":
		mm_globals.config.set_value("path", "project", file_name.get_base_dir())

func do_load_project(file_name : String) -> bool:
	var status : bool = false
	match file_name.get_extension():
		"ptex":
			status = await do_load_material(file_name, false)
			hierarchy.update_from_graph_edit(get_current_graph_edit())
		"mmpp":
			status = do_load_painting(file_name)
	if ! FileAccess.file_exists(file_name):
		status = false
	if status:
		add_recent(file_name)
	else:
		remove_recent(file_name)
	return status

func create_new_graph_edit_if_needed() -> MMGraphEdit:
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
	return graph_edit

func do_load_material(filename : String, update_hierarchy : bool = true) -> bool:
	var graph_edit : MMGraphEdit = create_new_graph_edit_if_needed()
	await graph_edit.load_file(filename)
	if update_hierarchy:
		hierarchy.update_from_graph_edit(get_current_graph_edit())
	print("Current mesh: ", current_mesh)
	print("Top generator: ", graph_edit.top_generator)
	if current_mesh and graph_edit.top_generator:
		graph_edit.top_generator.set_current_mesh(current_mesh)
	return true

func do_load_material_from_data(filename : String, data : String, update_hierarchy : bool = true) -> bool:
	var graph_edit : MMGraphEdit = create_new_graph_edit_if_needed()
	graph_edit.load_from_data(filename, data)
	if update_hierarchy:
		hierarchy.update_from_graph_edit(get_current_graph_edit())
	return true

func do_load_painting(filename : String) -> bool:
	var paint_panel = load("res://material_maker/panels/paint/paint.tscn").instantiate()
	projects_panel.get_projects().add_tab(paint_panel)
	var status : bool = paint_panel.load_project(filename)
	projects_panel.get_projects().current_tab = paint_panel.get_index()
	return status

func load_material_from_website() -> void:
	var dialog = load("res://material_maker/windows/load_from_website/load_from_website.tscn").instantiate()
	var result = await dialog.select_asset()
	if result == {}:
		return
	new_material()
	var graph_edit = get_current_graph_edit()
	var new_generator = await mm_loader.create_gen(result)
	graph_edit.set_new_generator(new_generator)
	hierarchy.update_from_graph_edit(graph_edit)

func save_project(project : Control = null) -> bool:
	if project == null:
		project = get_current_project()
	if project != null:
		return await project.save()
	return false

func save_project_as(project : Control = null) -> bool:
	if project == null:
		project = get_current_project()
	if project != null:
		return await project.save_as()
	return false

func save_all_projects() -> void:
	for i in range(projects_panel.get_projects().get_tab_count()):
		await projects_panel.get_projects().get_tab(i).save()

func close_project() -> void:
	projects_panel.get_projects().close_tab()

func quit() -> void:
	if quitting:
		return
	quitting = true
	if mm_globals.get_config("confirm_quit"):
		var result = await accept_dialog("Quit Material Maker?", true)
		if result == "cancel":
			quitting = false
			return
	if mm_globals.get_config("confirm_close_project"):
		var result = await $VBoxContainer/Layout/FlexibleLayout/Main/Projects.check_save_tabs()
		if !result:
			quitting = false
			return
	await mm_renderer.stop_rendering_thread()
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
	return false # todo validate_json(DisplayServer.clipboard_get()) != ""

func edit_duplicate() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.duplicate_selected()

func edit_duplicate_with_inputs() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.duplicate_selected_with_inputs()

func edit_duplicate_with_inputs_is_disabled() -> bool:
	return edit_cut_is_disabled()

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

func edit_select_connected(end1 : String, end2 : String) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	var node_list : Array = []
	for n in graph_edit.get_selected_nodes():
		node_list.push_back(n.name)
	while !node_list.is_empty():
		var new_node_list = []
		for c in graph_edit.get_connection_list():
			if c[end1] in node_list:
				var source = graph_edit.get_node(NodePath(c[end2]))
				if !source.selected:
					new_node_list.push_back(c[end2])
					source.selected = true
		node_list = new_node_list

func edit_select_sources_is_disabled() -> bool:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	return graph_edit == null or graph_edit.get_selected_nodes().is_empty()

func edit_select_sources() -> void:
	edit_select_connected("to_node", "from_node")

func edit_select_targets_is_disabled() -> bool:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	return graph_edit.get_selected_nodes().is_empty() if graph_edit else true

func edit_select_targets() -> void:
	edit_select_connected("from_node", "to_node")

func edit_duplicate_is_disabled() -> bool:
	return edit_cut_is_disabled()

func edit_load_selection() -> void:
	var graph_edit = get_current_graph_edit()
	if graph_edit == null:
		return
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.mms;Material Maker Selection")
	if mm_globals.config.has_section_key("path", "selection"):
		dialog.current_dir = mm_globals.config.get_value("path", "selection")
	var files = await dialog.select_files()
	if files.size() == 1:
		mm_globals.config.set_value("path", "selection", files[0].get_base_dir())
		var file : FileAccess = FileAccess.open(files[0], FileAccess.READ)
		if file != null:
			var test_json_conv = JSON.new()
			test_json_conv.parse(file.get_as_text())
			graph_edit.do_paste(test_json_conv.get_data())
			file.close()

func edit_save_selection() -> void:
	var graph_edit = get_current_graph_edit()
	if graph_edit == null:
		return
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mms;Material Maker Selection")
	if mm_globals.config.has_section_key("path", "selection"):
		dialog.current_dir = mm_globals.config.get_value("path", "selection")
	var files = await dialog.select_files()
	if files.size() == 1:
		mm_globals.config.set_value("path", "selection", files[0].get_base_dir())
		var file : FileAccess = FileAccess.open(files[0], FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(graph_edit.serialize_selection()))
			file.close()

func edit_preferences() -> void:
	var dialog = load("res://material_maker/windows/preferences/preferences.tscn").instantiate()
	dialog.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	dialog.edit_preferences(mm_globals.config)

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
	if !selected_nodes.is_empty():
		for n in selected_nodes:
			if n.generator.toggle_editable() and n.has_method("update_node"):
				n.update_node()

func create_menu_add_to_library(menu : MMMenuManager.MenuBase, manager, function) -> void:
	menu.clear()
	for i in manager.get_child_count():
		var lib = manager.get_child(i)
		if ! lib.read_only:
			menu.add_item(lib.library_name, i)
	menu.connect_id_pressed(Callable(self, function))

func create_menu_add_selection_to_library(menu : MMMenuManager.MenuBase) -> void:
	create_menu_add_to_library(menu, node_library_manager, "add_selection_to_library")

func add_selection_to_library(index) -> void:
	var selected_nodes = get_selected_nodes()
	if selected_nodes.is_empty():
		return
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instantiate()
	dialog.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	dialog.min_size = Vector2(250, 90) * dialog.content_scale_factor
	add_child(dialog)
	var current_item_name = ""
	if library.is_inside_tree():
		current_item_name = library.get_selected_item_name()
	var status = await dialog.enter_text("New library element", "Select a name for the new library element", current_item_name)
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
	var result = await selected_nodes[0].generator.render(self, 0, 64, true)
	var image : Image = result.get_image()
	result.release(self)
	node_library_manager.add_item_to_library(index, status.text, image, data)

func create_menu_add_brush_to_library(menu : MMMenuManager.MenuBase) -> void:
	create_menu_add_to_library(menu, brush_library_manager, "add_brush_to_library")

func add_brush_to_library(index) -> void:
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instantiate()
	dialog.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	dialog.min_size = Vector2(250, 90) * dialog.content_scale_factor
	add_child(dialog)
	var status = await dialog.enter_text("New library element", "Select a name for the new library element", brushes.get_selected_item_name())
	if ! status.ok:
		return
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	var data = graph_edit.top_generator.serialize()
	# Create thumbnail
	var result = await get_current_project().get_brush_preview()
	var image : Image = Image.new()
	image.copy_from(result.get_image())
	image.resize(32, 32)
	brush_library_manager.add_item_to_library(index, status.text, image, data)

func paint_project_settings():
	var dialog = load("res://material_maker/panels/paint/paint_project_settings.tscn").instantiate()
	add_child(dialog)
	dialog.edit_settings(get_current_project())

func create_menu_paint_environment(menu : MMMenuManager.MenuBase) -> void:
	get_node("/root/MainWindow/EnvironmentManager").create_environment_menu(menu)
	menu.connect_id_pressed(self._on_PaintEnvironment_id_pressed)

func _on_PaintEnvironment_id_pressed(id) -> void:
	var paint = get_current_project()
	if paint != null:
		paint.set_environment(id)


func environment_editor() -> Node:
	var env_editor : Node = load("res://material_maker/windows/environment_editor/environment_editor.tscn").instantiate()
	add_child(env_editor)
	return env_editor

# -----------------------------------------------------------------------
#                             Help menu
# -----------------------------------------------------------------------

func get_doc_dir() -> String:
	var base_dir = MMPaths.get_resource_dir().replace("\\", "/")
	# In release builds, documentation is expected to be located in
	# a subdirectory of the program directory
	var release_doc_path = base_dir.path_join("doc")
	# In development, documentation is part of the project files.
	# We can use a globalized `res://` path here as the project isn't exported.
	var devel_doc_path = ProjectSettings.globalize_path("res://material_maker/doc/_build/html")
	for p in [ release_doc_path, devel_doc_path ]:
		if FileAccess.file_exists(p+"/index.html"):
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
		while doc_name != "":
			var doc_path : String = doc_dir+"/node_"+doc_name+".html"
			if FileAccess.file_exists(doc_path):
				OS.shell_open(doc_path)
				break
			doc_name = doc_name.left(doc_name.rfind("_"))

func show_library_item_doc_is_disabled() -> bool:
	return get_doc_dir() == "" or !library.is_inside_tree() or library.get_selected_item_doc_name() == ""

func bug_report() -> void:
	OS.shell_open("https://github.com/RodZill4/godot-procedural-textures/issues")

func about() -> void:
	var about_box = preload("res://material_maker/windows/about/about.tscn").instantiate()
	add_child(about_box)
	about_box.hide()
	about_box.popup_centered()

# Preview

func update_preview() -> void:
	update_preview_2d()
	update_preview_3d([ preview_3d, projects_panel.preview_3d_background ])

func get_current_node(graph_edit : MMGraphEdit) -> Node:
	for n in graph_edit.get_children():
		if n is GraphNode and n.selected:
			return n
	return null

func update_preview_2d() -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if not graph_edit:
		return
	var previews : Array = [ get_panel("Preview2D"), get_panel("Preview2D (2)") ]
	for i in range(2):
		var preview = graph_edit.get_current_preview(i)
		var generator : MMGenBase = null
		var output_index : int = -1
		if preview == null or not is_instance_valid(preview.generator):
			previews[i].clear()
			continue
		generator = preview.generator
		output_index = preview.output_index
		if previews[i] != null:
			previews[i].set_generator(generator, output_index)
		if i == 0:
			histogram.set_generator(generator, output_index)
			projects_panel.preview_2d_background.set_generator(generator, output_index)

var current_gen_material = null
func update_preview_3d(previews : Array) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	var gen_material = null
	if graph_edit != null and graph_edit.top_generator != null and graph_edit.top_generator.has_node("Material"):
		gen_material = graph_edit.top_generator.get_node("Material")
	if gen_material != current_gen_material:
		current_gen_material = gen_material
	if current_gen_material != null:
		var materials : Dictionary[Node, Array] = {}
		for p in previews:
			materials[p] = p.get_materials()
		await current_gen_material.set_3d_previews(materials)

func on_preview_changed(graph) -> void:
	if graph == get_current_graph_edit():
		update_preview_2d()

func _on_Projects_tab_changed(_tab) -> void:
	var project = get_current_project()
	if project.has_method("project_selected"):
		project.call("project_selected")
	var new_tab = projects_panel.get_projects().get_current_tab_control()
	if new_tab != current_tab:
		var new_graph_edit = null
		if new_tab is GraphEdit:
			new_graph_edit = new_tab
			set_current_mode("material")
			if current_mesh and new_graph_edit.top_generator:
				new_graph_edit.top_generator.set_current_mesh(current_mesh)
		else:
			if new_tab.has_method("get_graph_edit"):
				new_graph_edit = new_tab.get_graph_edit()
			set_current_mode("paint")
		current_tab = new_tab
		if new_graph_edit != null:
			if ! new_graph_edit.is_connected("graph_changed", self.update_preview):
				new_graph_edit.connect("graph_changed", self.update_preview)
			if ! new_graph_edit.is_connected("preview_changed", self.on_preview_changed):
				new_graph_edit.connect("preview_changed", self.on_preview_changed)
			update_preview()
		if new_tab is GraphEdit:
			hierarchy.update_from_graph_edit(get_current_graph_edit())

func on_group_selected(generator) -> void:
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.edit_subgraph(generator)

func _notification(what : int) -> void:
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Limit FPS to decrease CPU/GPU usage while the window is unfocused.
			@warning_ignore("narrowing_conversion")
			OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(mm_globals.get_config("idle_fps_limit"), IDLE_FPS_LIMIT_MIN, IDLE_FPS_LIMIT_MAX)) * 1_000_000
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			# Return to the normal FPS limit when the window is focused.
			@warning_ignore("narrowing_conversion")
			OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(mm_globals.get_config("fps_limit"), FPS_LIMIT_MIN, FPS_LIMIT_MAX)) * 1_000_000

func on_close_requested():
	await get_tree().process_frame
	quit()

func dim_window() -> void:
	# Darken the UI to denote that the application is currently exiting
	# (it won't respond to user input in this state).
	modulate = Color(0.5, 0.5, 0.5)

func generate_screenshots():
	var result = await library.generate_screenshots(get_current_graph_edit())
	print(result)

func generate_graph_screenshot():
	# Prompt for a target PNG file
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image file")
	var files = await dialog.select_files()
	if files.size() != 1:
		return
	# Generate the image
	var graph_edit : GraphEdit = get_current_graph_edit()
	var minimap_save : bool = graph_edit.minimap_enabled
	graph_edit.minimap_enabled = false
	var save_scroll_offset : Vector2 = graph_edit.scroll_offset
	var save_zoom : float = graph_edit.zoom
	graph_edit.zoom = 1
	await get_tree().process_frame
	var graph_edit_rect = graph_edit.get_global_rect()
	var scale_factor : float = get_window().content_scale_factor
	graph_edit_rect = Rect2(graph_edit_rect.position+Vector2(15, 80), graph_edit_rect.size-Vector2(25, 90))
	graph_edit_rect = Rect2(scale_factor*graph_edit_rect.position, scale_factor*graph_edit_rect.size)
	var graph_rect = null
	for c in graph_edit.get_children():
		if c is GraphElement:
			var node_rect = Rect2(c.position_offset, c.size)
			if graph_rect == null:
				graph_rect = node_rect
			else:
				graph_rect = graph_rect.expand(node_rect.position)
				graph_rect = graph_rect.expand(node_rect.end)
	graph_rect = graph_rect.grow_individual(50, 20, 50, 80)
	graph_rect = Rect2(scale_factor*graph_rect.position, scale_factor*graph_rect.size)
	var image : Image = Image.create(graph_rect.size.x, graph_rect.size.y, false, get_viewport().get_texture().get_image().get_format())
	var origin = graph_rect.position
	var small_image : Image = Image.create(graph_edit_rect.size.x, graph_edit_rect.size.y, false, get_viewport().get_texture().get_image().get_format())
	for x in range(0, graph_rect.size.x, graph_edit_rect.size.x):
		for y in range(0, graph_rect.size.y, graph_edit_rect.size.y):
			graph_edit.scroll_offset = (origin+Vector2(x, y))/scale_factor-Vector2(15, 80)
			await get_tree().process_frame
			small_image.blit_rect(get_viewport().get_texture().get_image(), graph_edit_rect, Vector2(0, 0))
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
	if return_value.is_empty():
		return_value.append(parent)
	return return_value

func run_method_at_position(pos : Vector2i, method : String, parameters : Array) -> bool:
	var controls : Array = get_controls_at_position(pos, self)
	while ! controls.is_empty():
		var next_controls = []
		for control in controls:
			if control == null:
				continue
			if control.has_method(method):
				control.callv(method, parameters)
				return true
			if control.get_parent() != self:
				next_controls.append(control.get_parent())
		controls = next_controls
	return false

func on_files_dropped(files : PackedStringArray) -> void:
	await get_tree().process_frame
	for f in files:
		var file : FileAccess = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		f = file.get_path_absolute()
		match f.get_extension():
			"ptex":
				var status : bool = await do_load_material(f)
				if status:
					add_recent(f)
				else:
					remove_recent(f)
			"obj", "glb", "gltf":
				if ! run_method_at_position(get_global_mouse_position(), "on_drop_model_file", [ f ]):
					await new_paint_project(f)
			"bmp", "exr", "hdr", "jpg", "jpeg", "png", "svg", "tga", "webp":
				run_method_at_position(get_global_mouse_position(), "on_drop_image_file", [ f ])
			"mme":
				var test_json_conv : JSON = JSON.new()
				if test_json_conv.parse(file.get_as_text()) == OK:
					var data = test_json_conv.get_data()
					if data.has("material") and data.has("name"):
						mm_loader.save_export_target(data.material, data.name, data)
						mm_loader.load_external_export_targets()

var tip_priority: int = 0

func set_tip_text(tip : String, timeout : float = 0.0, priority: int = 0):
	tip = tip.replace("#LMB", "[img]res://material_maker/icons/lmb.tres[/img]")
	tip = tip.replace("#RMB", "[img]res://material_maker/icons/rmb.tres[/img]")
	tip = tip.replace("#MMB", "[img]res://material_maker/icons/mmb.tres[/img]")
	if priority >= tip_priority:
		tip_priority = priority
		$VBoxContainer/StatusBar/HBox/Tip.text = tip
		var tip_timer : Timer = $VBoxContainer/StatusBar/HBox/Tip/Timer
		tip_timer.stop()
		if timeout > 0.0:
			tip_timer.one_shot = true
			tip_timer.wait_time = timeout
			tip_timer.start()

func _on_Tip_Timer_timeout():
	tip_priority = 0
	$VBoxContainer/StatusBar/HBox/Tip.text = ""

# Add dialog

func add_dialog(dialog : Window):
	var background : ColorRect = load("res://material_maker/darken.tscn").instantiate()
	add_child(background)
	add_child(dialog)
	dialog.connect("tree_exited", background.queue_free)

# Accept dialog

func accept_dialog(dialog_text : String, cancel_button : bool = false, autowrap : bool = false, extra_buttons : Array[Dictionary] = []):
	var dialog = preload("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instantiate()
	dialog.dialog_text = dialog_text
	if autowrap:
		dialog.dialog_autowrap = autowrap
		dialog.min_size.x = 500
	if cancel_button:
		dialog.add_cancel_button("Cancel")
	for b in extra_buttons:
		dialog.add_button(b.label, b.right if b.has("right") else false, b.action)
	add_dialog(dialog)
	return await dialog.ask()

# Current mesh

func set_current_mesh(m : Mesh):
	current_mesh = m
	var current_graph_edit = get_current_graph_edit()
	if current_graph_edit:
		current_graph_edit.top_generator.set_current_mesh(m)

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


func _on_console_resizer_container_mouse_entered() -> void:
	pass # Replace with function body.
