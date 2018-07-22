tool
extends Container

var popup_position = Vector2(0, 0)

const MENU = [
	{ name="sine", description="Sine" },
	{ name="boolean", description="Boolean" },
	{ name="bricks", description="Bricks" },
	{ name="iqnoise", description="IQ Noise" },
	{ name="perlin", description="Perlin noise" },
	{ name="transform", description="Transform" }
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
	node_type = load("res://addons/procedural_material/"+MENU[id].name+".tscn")
	if node_type != null:
		var node = node_type.instance()
		$GraphEdit.add_child(node)
		node.set_begin(popup_position)

func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	var disconnect = $GraphEdit.get_source(to, to_slot)
	if disconnect != null:
		$GraphEdit.disconnect_node(disconnect.node, disconnect.slot, to, to_slot)
	$GraphEdit.connect_node(from, from_slot, to, to_slot)
	generate_shader();

func generate_shader():
	var code = ""
	var file = File.new()
	file.open("res://addons/procedural_material/shader_header.txt", File.READ)
	while !file.eof_reached():
		code += file.get_line()
		code += "\n"
	for c in $GraphEdit.get_children():
		if c is GraphNode:
			c.generated = false
	var shader_code = $GraphEdit/Material.get_shader_code("UV")
	code += shader_code.code
	#print(code)
	$Preview.material.shader.set_code(code)

