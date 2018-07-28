tool
extends Container

var popup_menu = null
var popup_position = Vector2(0, 0)
var selected_node = null

var preview_material = null
var texture_preview_material = null

const MENU = [
	{ command="load_texture", description="Load texture" },
	{ command="save_texture", description="Save texture" },
	{ command="export_texture", description="Export texture" },
	{ submenu="generator", description="Generator" },
	{ name="image", description="Image", in_submenu="generator" },
	{ name="sine", description="Sine", in_submenu="generator" },
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
	preview_material = $Preview/Preview.preview_material
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
		else:
			menu.add_item(MENU[i].description, i)
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
			$GraphEdit.add_child(node)
			node.offset = ($GraphEdit.scroll_offset + popup_position - $GraphEdit.rect_global_position) / $GraphEdit.zoom

func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	var disconnect = $GraphEdit.get_source(to, to_slot)
	if disconnect != null:
		$GraphEdit.disconnect_node(disconnect.node, disconnect.slot, to, to_slot)
	$GraphEdit.connect_node(from, from_slot, to, to_slot)
	generate_shader();

func load_texture():
	var dialog = EditorFileDialog.new()
	add_child(dialog)
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.ptex;Procedural texture file")
	dialog.connect("file_selected", self, "load_file")
	dialog.popup_centered()

func load_file(filename):
	var file = File.new()
	if file.open(filename, File.READ) != OK:
		return
	var data = parse_json(file.get_as_text())
	file.close()
	$GraphEdit.clear_connections()
	for c in $GraphEdit.get_children():
		if c is GraphNode:
			$GraphEdit.remove_child(c)
			c.free()
	for n in data.nodes:
		if !n.has("type"):
			continue
		var node_type = load("res://addons/procedural_material/nodes/"+n.type+".tscn")
		if node_type != null:
			var node = node_type.instance()
			node.name = n.name
			$GraphEdit.add_child(node)
			node.deserialize(n)
	for c in data.connections:
		$GraphEdit.connect_node(c.from, c.from_port, c.to, c.to_port)
	generate_shader()

func save_texture():
	var dialog = EditorFileDialog.new()
	add_child(dialog)
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.mode = EditorFileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.ptex;Procedural texture file")
	dialog.connect("file_selected", self, "save_file")
	dialog.popup_centered()

func save_file(filename):
	var data = { nodes = [] }
	for c in $GraphEdit.get_children():
		if c is GraphNode:
			data.nodes.append(c.serialize())
	data.connections = $GraphEdit.get_connection_list()
	var file = File.new()
	if file.open(filename, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()

func export_texture():
	var size = 256
	$SaveViewport.size = Vector2(size, size)
	$SaveViewport/ColorRect.rect_position = Vector2(0, 0)
	$SaveViewport/ColorRect.rect_size = Vector2(size, size)
	setup_material($SaveViewport/ColorRect.material, selected_node.get_textures(), $GraphEdit.generate_shader(selected_node))
	$SaveViewport.render_target_update_mode = Viewport.UPDATE_ONCE
	#$SaveViewport/ColorRect.update()
	$SaveViewport.update_worlds()
	$SaveViewport/Timer.start()
	yield($SaveViewport/Timer, "timeout")
	var viewport_texture = $SaveViewport.get_texture()
	var viewport_image = viewport_texture.get_data()
	viewport_image.save_png("res://generated_image.png")

func setup_material(shader_material, textures, shader_code):
	for k in textures.keys():
		#print("Setting param "+k+" to "+str(textures[k]))
		shader_material.set_shader_param(k+"_tex", textures[k])
	shader_material.shader.code = shader_code

func generate_shader():
	setup_material(preview_material, $GraphEdit/Material.get_textures(), $GraphEdit.generate_shader($GraphEdit/Material, 1))
	if selected_node != null:
		setup_material(texture_preview_material, selected_node.get_textures(), $GraphEdit.generate_shader(selected_node))

func _on_GraphEdit_node_selected(node):
	if selected_node != node:
		selected_node = node
		setup_material(texture_preview_material, selected_node.get_textures(), $GraphEdit.generate_shader(selected_node))

