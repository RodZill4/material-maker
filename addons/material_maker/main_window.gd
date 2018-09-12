tool
extends Panel

var editor_interface = null
var current_tab = null

const MENU = [
	{ menu="File", command="new_material", description="New material" },
	{ menu="File", command="load_material", shortcut="Control+O", description="Load material" },
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
	{ menu="Tools", command="add_to_user_library", description="Add selected node to user library" },
	{ menu="Tools", command="save_user_library", description="Save user library" },
	{ menu="Help", command="show_doc", description="User manual" },
	{ menu="Help", command="bug_report", description="Report a bug" },
	{ menu="Help" },
	{ menu="Help", command="about", description="About" }
]

signal quit

func _ready():
	if !Engine.editor_hint:
		OS.set_window_title(ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/release"))
	for m in $VBoxContainer/Menu.get_children():
		var menu = m.get_popup()
		create_menu(menu, m.name)
		m.connect("about_to_show", self, "menu_about_to_show", [ m.name, menu ])
	new_material()

func create_menu(menu, menu_name):
	menu.clear()
	menu.connect("id_pressed", self, "_on_PopupMenu_id_pressed")
	for i in MENU.size():
		if MENU[i].menu != menu_name:
			continue
		if MENU[i].has("submenu"):
			var submenu = PopupMenu.new()
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
	graph_edit.renderer = $Renderer
	graph_edit.editor_interface = editor_interface
	$VBoxContainer/HBoxContainer/Projects.add_child(graph_edit)
	$VBoxContainer/HBoxContainer/Projects.current_tab = graph_edit.get_index()
	return graph_edit 

func new_material():
	var graph_edit = new_pane()
	graph_edit.update_tab_title()

func load_material():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILES
	dialog.add_filter("*.ptex;Procedural textures file")
	#dialog.connect("file_selected", self, "do_load_material")
	dialog.connect("files_selected", self, "do_load_materials")
	dialog.popup_centered()

func do_load_materials(filenames):
	for f in filenames:
		do_load_material(f)

func do_load_material(filename):
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	var node_count = 0
	if graph_edit == null:
		node_count = 123 # So test below succeeds...
	else:
		for c in graph_edit.get_children():
			if c is GraphNode:
				node_count += 1
				if node_count > 1:
					break
	if node_count > 1:
		graph_edit = new_pane()
	graph_edit.do_load_file(filename)

func save_material():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graph_edit != null:
		graph_edit.save_file()
	
func save_material_as():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graph_edit != null:
		graph_edit.save_file_as()

func close_material():
	$VBoxContainer/HBoxContainer/Projects.close_tab()

func export_material():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graph_edit != null :
		graph_edit.export_textures()

func export_material_is_disabled():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graph_edit == null or graph_edit.save_path == null:
		return true
	return false

func quit():
	if Engine.editor_hint:
		emit_signal("quit")
	else:
		get_tree().quit()

func edit_cut():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graph_edit != null:
		graph_edit.cut()

func edit_cut_is_disabled():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	return graph_edit == null or !graph_edit.can_copy()

func edit_copy():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graph_edit != null:
		graph_edit.copy()

func edit_copy_is_disabled():
	return edit_cut_is_disabled()

func edit_paste():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graph_edit != null:
		graph_edit.paste()

func edit_paste_is_disabled():
	var data = parse_json(OS.clipboard)
	return data == null

func add_to_user_library():
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graph_edit != null and graph_edit is GraphEdit:
		var selected_nodes = []
		for n in graph_edit.get_children():
			if n is GraphNode and n.selected:
				selected_nodes.append(n)
		if !selected_nodes.empty():
			var dialog = preload("res://addons/material_maker/widgets/line_dialog.tscn").instance()
			dialog.set_texts("New library element", "Select a name for the new library element")
			add_child(dialog)
			dialog.connect("ok", self, "do_add_to_user_library", [ selected_nodes ])
			dialog.popup_centered()

func do_add_to_user_library(name, nodes):
	var data
	if nodes.size() == 1:
		data = nodes[0].serialize()
		data.erase("node_position")
	else:
		var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
		data = graph_edit.serialize_selection()
	var dir = Directory.new()
	dir.make_dir("user://library")
	dir.make_dir("user://library/user")
	data.library = "user://library/user.json"
	data.icon = name.right(name.rfind("/")+1).to_lower()
	$VBoxContainer/HBoxContainer/VBoxContainer/Library.add_item(data, name)
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	graph_edit.export_texture(nodes[0], "user://library/user/"+data.icon+".png", 64)

func save_user_library():
	print("Saving user library")
	$VBoxContainer/HBoxContainer/VBoxContainer/Library.save_library("user://library/user.json")

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
	var material_node = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control().get_node("Material")
	if material_node != null:
		material_node.update_materials($VBoxContainer/HBoxContainer/VBoxContainer/Preview.get_materials())
	update_preview_2d()

func update_preview_2d(node = null):
	var graph_edit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	var preview = $VBoxContainer/HBoxContainer/VBoxContainer/Preview
	if node == null:
		for n in graph_edit.get_children():
			if n is GraphNode and n.selected:
				node = n
				break
	if node != null:
		graph_edit.renderer.setup_material(preview.get_2d_material(), node.get_textures(), node.generate_shader())

func _on_Projects_tab_changed(tab):
	var new_tab = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if new_tab != current_tab:
		if new_tab != null:
			for c in get_incoming_connections():
				if c.method_name == "update_preview" or c.method_name == "update_preview_2d":
					c.source.disconnect(c.signal_name, self, c.method_name)
			new_tab.connect("graph_changed", self, "update_preview")
			new_tab.connect("node_selected", self, "update_preview_2d")
		current_tab = new_tab
		update_preview()
