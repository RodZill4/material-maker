tool
extends Container

var save_path = null

var popup_menu = null
var popup_position = Vector2(0, 0)
var selected_node = null

var texture_preview_material = null

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
		node_type = load("res://addons/procedural_material/nodes/"+MENU[id].name+".tscn")
		if node_type != null:
			var node = node_type.instance()
			var i = 0
			while true:
				var name = MENU[id].name+"_"+str(i)
				if !$GraphEdit.has_node(name):
					node.set_name(name)
					break
				i += 1
			$GraphEdit.add_node(node, popup_position)
			node.offset = ($GraphEdit.scroll_offset + popup_position - $GraphEdit.rect_global_position) / $GraphEdit.zoom

func set_save_path(path):
	save_path = path
	if !Engine.editor_hint:
		if save_path != null:
			OS.set_window_title("Procedural textures (%s)" % save_path)
		else:
			OS.set_window_title("Procedural textures")

func new_texture():
	$GraphEdit.new_material()
	set_save_path(null)

func load_texture():
	selected_node = null
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.ptex;Procedural textures file")
	dialog.connect("file_selected", self, "do_load_texture")
	dialog.popup_centered()

func do_load_texture(path):
	set_save_path(path)
	$GraphEdit.load_file(save_path)

func save_texture():
	if save_path != null:
		$GraphEdit.save_file(save_path)
	else:
		save_texture_as()
	
func save_texture_as():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.ptex;Procedural textures file")
	dialog.connect("file_selected", self, "do_save_texture")
	dialog.popup_centered()

func do_save_texture(path):
	set_save_path(path)
	$GraphEdit.save_file(save_path)

func export_texture(size = 512):
	#$GraphEdit.export_texture(selected_node, "res://generated_image.png", size)
	var prefix = save_path.left(save_path.rfind("."))
	$GraphEdit/Material.export_textures(prefix)

func generate_shader():
	if $GraphEdit/Material != null:
		$GraphEdit/Material.update_materials($Preview/Preview.get_materials())
	if selected_node != null && selected_node is GraphNode:
		$GraphEdit.setup_material(texture_preview_material, selected_node.get_textures(), selected_node.generate_shader())

func _on_GraphEdit_node_selected(node):
	if selected_node != node && node is GraphNode:
		selected_node = node
		$GraphEdit.setup_material(texture_preview_material, selected_node.get_textures(), selected_node.generate_shader())

