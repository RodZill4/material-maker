tool
extends GraphEdit

var save_path = null
var need_save = false

signal save_path_changed
signal graph_changed

func _ready():
	pass

func get_source(node, port):
	for c in get_connection_list():
		if c.to == node && c.to_port == port:
			return { node=c.from, slot=c.from_port }

func add_node(node, global_position = null):
	add_child(node)
	if global_position != null:
		node.offset = (scroll_offset + global_position - rect_global_position) / zoom
	node.connect("close_request", self, "remove_node", [ node ])

func remove_node(node):
	var node_name = node.name
	for c in get_connection_list():
		if c.from == node_name or c.to == node_name:
			disconnect_node(c.from, c.from_port, c.to, c.to_port)
	node.queue_free()
	send_changed_signal()

func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	var disconnect = get_source(to, to_slot)
	if disconnect != null:
		disconnect_node(disconnect.node, disconnect.slot, to, to_slot)
	connect_node(from, from_slot, to, to_slot)
	send_changed_signal();

func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)
	send_changed_signal();

# Global operations on graph

func update_tab_title():
	var title = "[unnamed]"
	if save_path != null:
		title = save_path.right(save_path.rfind("/")+1)
	if need_save:
		title += " *"
	get_parent().set_tab_title(get_index(), title)
	get_parent().update()

func set_need_save(ns):
	if ns != need_save:
		need_save = ns
		if get_parent() is TabContainer:
			update_tab_title()

func set_save_path(path):
	if path != save_path:
		save_path = path
		if get_parent() is TabContainer:
			update_tab_title()
		else:
			emit_signal("save_path_changed", self, path)

func clear_material():
	clear_connections()
	for c in get_children():
		if c is GraphNode:
			remove_child(c)
			c.free()
	send_changed_signal()

func new_material():
	clear_material()
	create_node({name="Material", type="material"})
	set_save_path(null)

func create_node(data, global_position = null):
	if !data.has("type"):
		return null
	var node_type = load("res://addons/procedural_material/nodes/"+data.type+".tscn")
	if node_type != null:
		var node = node_type.instance()
		if data.has("name") && !has_node(data.name):
			node.name = data.name
		else:
			var i = 0
			while true:
				var node_name = data.type+"_"+str(i)
				if !has_node(node_name):
					node.name = node_name
					break
				i += 1
		add_node(node, global_position)
		node.deserialize(data)
	send_changed_signal()

func load_file():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.ptex;Procedural textures file")
	dialog.connect("file_selected", self, "do_load_file")
	dialog.popup_centered()

func do_load_file(filename):
	var file = File.new()
	if file.open(filename, File.READ) != OK:
		return
	var data = parse_json(file.get_as_text())
	file.close()
	clear_material()
	for n in data.nodes:
		var node = create_node(n)
	for c in data.connections:
		connect_node(c.from, c.from_port, c.to, c.to_port)
	set_save_path(filename)
	send_changed_signal()
	set_need_save(false)

func save_file():
	if save_path != null:
		do_save_file(save_path)
	else:
		save_file_as()
	
func save_file_as():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.ptex;Procedural textures file")
	dialog.connect("file_selected", self, "do_save_file")
	dialog.popup_centered()

func do_save_file(filename):
	var data = { nodes = [] }
	for c in get_children():
		if c is GraphNode:
			data.nodes.append(c.serialize())
	data.connections = get_connection_list()
	var file = File.new()
	if file.open(filename, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()
	set_save_path(filename)
	set_need_save(false)

func export_textures(size = 512):
	if save_path != null:
		var prefix = save_path.left(save_path.rfind("."))
		$GraphEdit/Material.export_textures(prefix)

func send_changed_signal():
	set_need_save(true)
	$Timer.start()

func do_send_changed_signal():
	emit_signal("graph_changed")

func can_drop_data(position, data):
	return typeof(data) == TYPE_DICTIONARY and data.has('type')

func drop_data(position, data):
	var node = create_node(data, get_global_transform().xform(position))
	return true

# Save shader to image, create image texture

func setup_material(shader_material, textures, shader_code):
	for k in textures.keys():
		shader_material.set_shader_param(k+"_tex", textures[k])
	shader_material.shader.code = shader_code

var render_queue = []

func render_to_viewport(node, size, method, args):
	render_queue.append( { shader=node.generate_shader(), textures=node.get_textures(), size=size, method=method, args=args } )
	if render_queue.size() == 1:
		while !render_queue.empty():
			var job = render_queue.front()
			$SaveViewport.size = Vector2(job.size, job.size)
			$SaveViewport/ColorRect.rect_position = Vector2(0, 0)
			$SaveViewport/ColorRect.rect_size = Vector2(job.size, job.size)
			var shader_material = $SaveViewport/ColorRect.material
			shader_material.shader.code = job.shader
			for k in job.textures.keys():
				shader_material.set_shader_param(k+"_tex", job.textures[k])
			$SaveViewport.render_target_update_mode = Viewport.UPDATE_ONCE
			$SaveViewport.update_worlds()
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			callv(job.method, job.args)
			render_queue.pop_front()

func export_texture(node, filename, size = 256):
	if node == null:
		return null
	render_to_viewport(node, size, "do_export_texture", [ filename ])

func do_export_texture(filename):
	var viewport_texture = $SaveViewport.get_texture()
	var viewport_image = viewport_texture.get_data()
	viewport_image.save_png(filename)

func precalculate_texture(node, size, object, method, args):
	if node == null:
		return null
	render_to_viewport(node, size, "do_precalculate_texture", [ object, method, args ])

func do_precalculate_texture(object, method, args):
	var viewport_texture = $SaveViewport.get_texture()
	var texture = ImageTexture.new()
	texture.create_from_image(viewport_texture.get_data())
	args.append(texture)
	object.callv(method, args)

