tool
extends GraphEdit

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

func generate_shader(node):
	var code = ""
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
	if src_code.has("rgb"):
		shader_code += "COLOR = vec4("+src_code.rgb+", 1.0);\n"
	else:
		shader_code += "COLOR = vec4(vec3("+src_code.f+"), 1.0);\n"
	shader_code += "}\n"
	print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code
