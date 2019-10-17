tool
extends Panel

var recent_files = []

var editor_interface = null
var current_tab = null

onready var renderer = $Renderer
onready var projects = $VBoxContainer/HBoxContainer/ProjectsPane/Projects
onready var library = $VBoxContainer/HBoxContainer/VBoxContainer/Library

const MENU = [
	{ menu="File", command="new_material", description="New material" },
	{ menu="File", command="load_material", shortcut="Control+O", description="Load material" },
	{ menu="File", submenu="load_recent", description="Load recent", standalone_only=true },
	{ menu="File" },
	{ menu="File", command="save_material", shortcut="Control+S", description="Save material" },
	{ menu="File", command="save_material_as", shortcut="Control+Shift+S", description="Save material as..." },
	{ menu="File", command="save_all_materials", description="Save all materials..." },
	{ menu="File" },
	{ menu="File", command="export_material", shortcut="Control+E", description="Export material" },
	{ menu="File" },
	{ menu="File", command="close_material", description="Close material" },
	{ menu="File", command="quit", shortcut="Control+Q", description="Quit" },
	{ menu="Edit", command="edit_cut", shortcut="Control+X", description="Cut" },
	{ menu="Edit", command="edit_copy", shortcut="Control+C", description="Copy" },
	{ menu="Edit", command="edit_paste", shortcut="Control+V", description="Paste" },
	{ menu="Tools", submenu="create", description="Create" },
	{ menu="Tools", command="create_subgraph", shortcut="Control+G", description="Create group" },
	{ menu="Tools", command="make_selected_nodes_editable", shortcut="Control+F", description="Make selected nodes editable" },
	{ menu="Tools" },
	{ menu="Tools", command="add_to_user_library", description="Add selected node to user library" },
	{ menu="Tools", command="save_user_library", description="Save user library" },
	{ menu="Help", command="show_doc", description="User manual" },
	{ menu="Help", command="bug_report", description="Report a bug" },
	{ menu="Help" },
	{ menu="Help", command="about", description="About" }
]

signal quit

func _ready():
	# Upscale everything if the display requires it (crude hiDPI support).
	# This prevents UI elements from being too small on hiDPI displays.
	if OS.get_screen_dpi() >= 192 and OS.get_screen_size().x >= 2048:
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(), 2)

	if !Engine.editor_hint:
		OS.set_window_title(ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/release"))
	load_recents()
	for m in $VBoxContainer/Menu.get_children():
		var menu = m.get_popup()
		create_menu(menu, m.name)
		m.connect("about_to_show", self, "menu_about_to_show", [ m.name, menu ])
	new_material()

func get_current_graph_edit() -> MMGraphEdit:
	var graph_edit = projects.get_current_tab_control()
	if graph_edit != null and graph_edit is GraphEdit:
		return graph_edit
	return null

func create_menu(menu, menu_name):
	menu.clear()
	menu.connect("id_pressed", self, "_on_PopupMenu_id_pressed")
	for i in MENU.size():
		if MENU[i].has("standalone_only") and MENU[i].standalone_only and Engine.editor_hint:
			continue
		if MENU[i].menu != menu_name:
			continue
		if MENU[i].has("submenu"):
			var submenu = PopupMenu.new()
			var submenu_function = "create_menu_"+MENU[i].submenu
			if has_method(submenu_function):
				submenu.connect("about_to_show", self, submenu_function, [ submenu ]);
			else:
				create_menu(submenu, MENU[i].submenu)
			menu.add_child(submenu)
			menu.add_submenu_item(MENU[i].description, submenu.get_name())
		elif MENU[i].has("description"):
			var shortcut = 0
			if MENU[i].has("shortcut"):
				for s in MENU[i].shortcut.split("+"):
					if s == "Alt":
						shortcut |= KEY_MASK_ALT
					elif s == "Control":
						shortcut |= KEY_MASK_CTRL
					elif s == "Shift":
						shortcut |= KEY_MASK_SHIFT
					else:
						shortcut |= OS.find_scancode_from_string(s)
			menu.add_item(MENU[i].description, i, shortcut)
		else:
			menu.add_separator()
	return menu

func create_menu_load_recent(menu):
	menu.clear()
	for i in recent_files.size():
		menu.add_item(recent_files[i], i)
	if !menu.is_connected("id_pressed", self, "_on_LoadRecent_id_pressed"):
		menu.connect("id_pressed", self, "_on_LoadRecent_id_pressed")

func _on_LoadRecent_id_pressed(id):
	do_load_material(recent_files[id])

func load_recents():
	var f = File.new()
	if f.open("user://recent_files.bin", File.READ) == OK:
		recent_files = parse_json(f.get_as_text())
		f.close()

func add_recent(path):
	while true:
		var index = recent_files.find(path)
		if index >= 0:
			recent_files.remove(index)
		else:
			break
	recent_files.push_front(path)
	var f = File.new()
	f.open("user://recent_files.bin", File.WRITE)
	f.store_string(to_json(recent_files))
	f.close()

func create_menu_create(menu):
	var gens = MMGenLoader.get_generator_list()
	menu.clear()
	for i in gens.size():
		menu.add_item(gens[i], i)
	if !menu.is_connected("id_pressed", self, "_on_Create_id_pressed"):
		menu.connect("id_pressed", self, "_on_Create_id_pressed")

func _on_Create_id_pressed(id):
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		var gens = MMGenLoader.get_generator_list()
		graph_edit.create_gen_from_type(gens[id])

func menu_about_to_show(name, menu):
	for i in MENU.size():
		if MENU[i].menu != name:
			continue
		if MENU[i].has("submenu"):
			pass
		elif MENU[i].has("command"):
			var command_name = MENU[i].command+"_is_disabled"
			if has_method(command_name):
				var is_disabled = call(command_name)
				menu.set_item_disabled(menu.get_item_index(i), is_disabled)

func new_pane():
	var graph_edit = preload("res://addons/material_maker/graph_edit.tscn").instance()
	graph_edit.node_factory = $NodeFactory
	graph_edit.renderer = $Renderer
	graph_edit.editor_interface = editor_interface
	projects.add_child(graph_edit)
	projects.current_tab = graph_edit.get_index()
	return graph_edit 

func new_material():
	var graph_edit = new_pane()
	graph_edit.new_material()
	graph_edit.update_tab_title()

func load_material():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILES
	dialog.add_filter("*.ptex;Procedural textures file")
	dialog.connect("files_selected", self, "do_load_materials")
	dialog.popup_centered()

func do_load_materials(filenames):
	for f in filenames:
		do_load_material(f)

func do_load_material(filename):
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

func save_material():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		if graph_edit.save_path != null:
			graph_edit.save_file(graph_edit.save_path)
		else:
			save_material_as()

func save_material_as():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		var dialog = FileDialog.new()
		add_child(dialog)
		dialog.rect_min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.mode = FileDialog.MODE_SAVE_FILE
		dialog.add_filter("*.ptex;Procedural textures file")
		dialog.connect("file_selected", graph_edit, "save_file")
		dialog.popup_centered()

func close_material():
	projects.close_tab()

func export_material():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null :
		graph_edit.export_textures()

func export_material_is_disabled():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit == null or graph_edit.save_path == null:
		return true
	return false

func quit():
	if Engine.editor_hint:
		emit_signal("quit")
	else:
		get_tree().quit()


func edit_cut():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.cut()

func edit_cut_is_disabled():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	return graph_edit == null or !graph_edit.can_copy()

func edit_copy():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.copy()

func edit_copy_is_disabled():
	return edit_cut_is_disabled()

func edit_paste():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.paste()

func edit_paste_is_disabled():
	var data = parse_json(OS.clipboard)
	return data == null

func get_selected_nodes():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		return graph_edit.get_selected_nodes()
	else:
		return []

func create_subgraph():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		graph_edit.create_subgraph()

func make_selected_nodes_editable():
	var selected_nodes = get_selected_nodes()
	if !selected_nodes.empty():
		for n in selected_nodes:
			n.generator.model = null
			n.update_node()

func add_to_user_library():
	var selected_nodes = get_selected_nodes()
	if !selected_nodes.empty():
		var dialog = preload("res://addons/material_maker/widgets/line_dialog.tscn").instance()
		dialog.set_value(library.get_selected_item_name())
		dialog.set_texts("New library element", "Select a name for the new library element")
		add_child(dialog)
		dialog.connect("ok", self, "do_add_to_user_library", [ selected_nodes ])
		dialog.popup_centered()

func do_add_to_user_library(name, nodes):
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
	data.icon = name.right(name.rfind("/")+1).to_lower()
	var result = nodes[0].generator.render(0, renderer, 64)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	result.save_to_file("user://library/user/"+data.icon+".png")
	result.release()
	library.add_item(data, name, library.get_preview_texture(data))

func save_user_library():
	print("Saving user library")
	library.save_library("user://library/user.json")

func show_doc():
	var doc_path = OS.get_executable_path()
	doc_path = doc_path.replace("\\", "/")
	doc_path = doc_path.left(doc_path.rfind("/")+1)+"doc/index.html"
	var file = File.new()
	if file.exists(doc_path):
		OS.shell_open(doc_path)

func bug_report():
	OS.shell_open("https://github.com/RodZill4/godot-procedural-textures/issues")

func about():
	var about_box = preload("res://addons/material_maker/widgets/about.tscn").instance()
	add_child(about_box)
	about_box.popup_centered()
	
func _on_PopupMenu_id_pressed(id):
	var node_type = null
	if MENU[id].has("command"):
		var command = MENU[id].command
		if has_method(command):
			call(command)

# Preview

func update_preview():
	update_preview_2d()
	update_preview_3d()

func update_preview_2d(node = null):
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null:
		var preview = $VBoxContainer/HBoxContainer/VBoxContainer/Preview
		if node == null:
			for n in graph_edit.get_children():
				if n is GraphNode and n.selected:
					node = n
					break
		if node != null:
			var result = node.generator.render(0, renderer, 1024)
			while result is GDScriptFunctionState:
				result = yield(result, "completed")
			var tex = ImageTexture.new()
			result.copy_to_texture(tex)
			result.release()
			preview.set_2d(tex)

func update_preview_3d():
	var graph_edit : MMGraphEdit = get_current_graph_edit()
	if graph_edit != null and graph_edit.top_generator != null and graph_edit.top_generator.has_node("Material"):
		var gen_material = graph_edit.top_generator.get_node("Material")
		var status = gen_material.render_textures(renderer)
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
		gen_material.update_materials($VBoxContainer/HBoxContainer/VBoxContainer/Preview.get_materials())

func _on_Projects_tab_changed(tab):
	var new_tab = projects.get_current_tab_control()
	if new_tab != current_tab:
		if new_tab != null:
			for c in get_incoming_connections():
				if c.method_name == "update_preview" or c.method_name == "update_preview_2d":
					c.source.disconnect(c.signal_name, self, c.method_name)
			new_tab.connect("graph_changed", self, "update_preview")
			new_tab.connect("node_selected", self, "update_preview_2d")
		current_tab = new_tab
		update_preview()

func _on_Preview_show_background_preview(v):
	var pv = $VBoxContainer/HBoxContainer/VBoxContainer/Preview/MaterialPreview
	var bgpv = $VBoxContainer/HBoxContainer/ProjectsPane/BackgroundPreview/Viewport
	bgpv.world = pv.find_world()
	$VBoxContainer/HBoxContainer/ProjectsPane/BackgroundPreview.visible = v
