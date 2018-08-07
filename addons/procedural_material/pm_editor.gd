tool
extends Container

var popup_menu = null
var popup_position = Vector2(0, 0)

var texture_preview_material = null

var preview_maximized = false

const MENU = [
	{ command="new_texture", description="New material" },
	{ command="load_texture", description="Load material" },
	{ command="save_texture", description="Save material" },
	{ command="save_texture_as", description="Save material as..." },
	{ command="export_texture", description="Export material" },
	{ },
	{ submenu="generator", description="Generator" },
	{ name="image", description="Image", in_submenu="generator" },
	{ name="pattern", description="Pattern", in_submenu="generator" },
	{ name="bricks", description="Bricks", in_submenu="generator" },
	{ name="perlin", description="Perlin noise", in_submenu="generator" },
	{ name="voronoi", description="Voronoi Noise", in_submenu="generator" },
	{ submenu="filter", description="Filter" },
	{ name="colorize", description="Colorize", in_submenu="filter" },
	{ name="blend", description="Blend", in_submenu="filter" },
	{ name="transform", description="Transform", in_submenu="filter" },
	{ name="warp", description="Warp", in_submenu="filter" },
	{ name="normal_map", description="Normal Map", in_submenu="filter" }
]

func _ready():
	# Duplicate the material we'll modify and store the shaders
	$Preview/Preview/SelectedPreview.material = $Preview/Preview/SelectedPreview.material.duplicate(true)
	texture_preview_material = $Preview/Preview/SelectedPreview.material
	$GraphEdit.add_valid_connection_type(0, 0)
	# create or update popup menu
	if popup_menu != null:
		popup_menu.queue_free()
	popup_menu = create_menu()
	$GraphEdit.add_child(popup_menu)

func create_menu(in_submenu = null):
	var menu = PopupMenu.new()
	menu.connect("id_pressed", self, "_on_PopupMenu_id_pressed")
	for i in MENU.size():
		if MENU[i].has("in_submenu"):
			if in_submenu != MENU[i].in_submenu:
				continue
		elif in_submenu != null:
			continue
		if MENU[i].has("submenu"):
			var submenu = create_menu(MENU[i].submenu)
			menu.add_child(submenu)
			menu.add_submenu_item(MENU[i].description, submenu.get_name())
		elif MENU[i].has("description"):
			menu.add_item(MENU[i].description, i)
		else:
			menu.add_separator()
	return menu

func _on_GraphEdit_popup_request(position):
	popup_position = position
	popup_menu.popup(Rect2(position, popup_menu.rect_size))

func _on_PopupMenu_id_pressed(id):
	var node_type = null
	if MENU[id].has("command"):
		call(MENU[id].command)
	elif MENU[id].has("name"):
		$GraphEdit.create_node({type=MENU[id].name}, popup_position)

func set_save_path(graph_edit, path):
	if !Engine.editor_hint:
		if path != null:
			OS.set_window_title("Procedural textures (%s)" % path)
		else:
			OS.set_window_title("Procedural textures")

func new_texture():
	$GraphEdit.new_material()

func load_texture():
	$GraphEdit.load_file()

func save_texture():
	$GraphEdit.save_file()
	
func save_texture_as():
	$GraphEdit.save_file_as()

func export_texture():
	$GraphEdit.export_textures()

func get_selected_node():
	var rv = null
	for c in $GraphEdit.get_children():
		if c is GraphNode && c.selected:
			if rv != null:
				return null
			else:
				rv = c
	return rv

func generate_shader():
	var selected_node = get_selected_node()
	if $GraphEdit/Material != null:
		$GraphEdit/Material.update_materials($Preview/Preview.get_materials())
	if selected_node != null:
		$GraphEdit.setup_material($Preview/Preview.get_2d_material(), selected_node.get_textures(), selected_node.generate_shader())

func _on_GraphEdit_node_selected(node):
	var selected_node = get_selected_node()
	if selected_node != null:
		$GraphEdit.setup_material($Preview/Preview.get_2d_material(), selected_node.get_textures(), selected_node.generate_shader())

func _on_SelectedPreview_gui_input(ev):
	if ev is InputEventMouseButton && ev.button_index == 1 && ev.doubleclick:
		if preview_maximized:
			$Preview/Preview/SelectedPreview/SelectedPreviewAnimation.play("minimize")
		else:
			$Preview/Preview/SelectedPreview/SelectedPreviewAnimation.play("maximize")
		preview_maximized = !preview_maximized

