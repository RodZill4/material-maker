tool
extends Container

var popup_position = Vector2(0, 0)
var selected_node = null

const MENU = [
	{ command="load_texture", description="Load texture" },
	{ command="save_texture", description="Save texture" },
	{ name="sine", description="Sine" },
	{ name="bricks", description="Bricks" },
	{ name="iqnoise", description="IQ Noise" },
	{ name="perlin", description="Perlin noise" },
	{ name="transform", description="Transform" },
	{ name="warp", description="Warp" },
	{ name="colorize", description="Colorize" },
	{ name="normal_map", description="Normal Map" },
	{ name="blend", description="Blend" }
]

func _ready():
	$GraphEdit.add_valid_connection_type(0, 0)
	$GraphEdit/PopupMenu.clear()
	for i in MENU.size():
		$GraphEdit/PopupMenu.add_item(MENU[i].description, i)

func _on_GraphEdit_popup_request(position):
	popup_position = position
	$GraphEdit/PopupMenu.popup(Rect2(position, $GraphEdit/PopupMenu.rect_size))

func _on_PopupMenu_id_pressed(id):
	var node_type = null
	if MENU[id].has("command"):
		call(MENU[id].command)
	elif MENU[id].has("name"):
		node_type = load("res://addons/procedural_material/nodes/"+MENU[id].name+".tscn")
		if node_type != null:
			var node = node_type.instance()
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

func generate_shader():
	$TexturePreview.material.shader.set_code($GraphEdit.generate_shader($GraphEdit/Material))
	if selected_node != null:
		$TexturePreview/SelectedPreview.material.shader.set_code($GraphEdit.generate_shader(selected_node))

func _on_GraphEdit_node_selected(node):
	print("selected "+str(node))
	selected_node = node
	$TexturePreview/SelectedPreview.material.shader.set_code($GraphEdit.generate_shader(selected_node))
