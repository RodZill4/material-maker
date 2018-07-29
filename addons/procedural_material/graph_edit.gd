tool
extends GraphEdit

signal graph_changed

func _ready():
	pass

func get_source(node, port):
	for c in get_connection_list():
		if c.to == node && c.to_port == port:
			return { node=c.from, slot=c.from_port }

func remove_node(node):
	for c in get_connection_list():
		if c.from == node or c.to == node:
			disconnect_node(c.from, c.from_port, c.to, c.to_port)

func send_changed_signal():
	$Timer.start()

func do_send_changed_signal():
	emit_signal("graph_changed")

func generate_shader(node, shader_type = 0):
	var code
	if shader_type == 1:
		code = "shader_type spatial;\n\n"
	else:
		code = "shader_type canvas_item;\n\n"
	var file = File.new()
	file.open("res://addons/procedural_material/shader_header.txt", File.READ)
	code += file.get_as_text()
	code += "\n"
	for c in get_children():
		if c is GraphNode:
			c.generated = false
			c.generated_variants = []
	var src_code = node.get_shader_code("UV")
	var shader_code = src_code.defs
	shader_code += "void fragment() {\n"
	shader_code += src_code.code
	if shader_type == 1:
		if src_code.has("albedo"):
			shader_code += "ALBEDO = "+src_code.albedo+";\n"
		if src_code.has("normal_map"):
			shader_code += "NORMALMAP = "+src_code.normal_map+";\n"
	else:
		if src_code.has("rgb"):
			shader_code += "COLOR = vec4("+src_code.rgb+", 1.0);\n"
		elif src_code.has("f"):
			shader_code += "COLOR = vec4(vec3("+src_code.f+"), 1.0);\n"
		else:
			shader_code += "COLOR = vec4(1.0);\n"
	shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

func setup_material(shader_material, textures, shader_code):
	for k in textures.keys():
		shader_material.set_shader_param(k+"_tex", textures[k])
	shader_material.shader.code = shader_code


func export_texture(node, filename, size = 256):
	if node != null:
		$SaveViewport.size = Vector2(size, size)
		$SaveViewport/ColorRect.rect_position = Vector2(0, 0)
		$SaveViewport/ColorRect.rect_size = Vector2(size, size)
		setup_material($SaveViewport/ColorRect.material, node.get_textures(), generate_shader(node))
		$SaveViewport.render_target_update_mode = Viewport.UPDATE_ONCE
		$SaveViewport.update_worlds()
		$SaveViewport/Timer.start()
		yield($SaveViewport/Timer, "timeout")
		var viewport_texture = $SaveViewport.get_texture()
		var viewport_image = viewport_texture.get_data()
		viewport_image.save_png("res://generated_image.png")

func precalculate_texture(node, size, object, method, args):
	if node == null:
		return null
	$SaveViewport.size = Vector2(size, size)
	$SaveViewport/ColorRect.rect_position = Vector2(0, 0)
	$SaveViewport/ColorRect.rect_size = Vector2(size, size)
	setup_material($SaveViewport/ColorRect.material, node.get_textures(), generate_shader(node))
	$SaveViewport.render_target_update_mode = Viewport.UPDATE_ONCE
	$SaveViewport.update_worlds()
	$SaveViewport/Timer.start()
	yield($SaveViewport/Timer, "timeout")
	var viewport_texture = $SaveViewport.get_texture()
	var texture = ImageTexture.new()
	texture.create_from_image(viewport_texture.get_data())
	args.append(texture)
	object.callv(method, args)

