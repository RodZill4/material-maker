tool
extends Viewport

var render_queue = []

func _ready():
	$ColorRect.material = $ColorRect.material.duplicate(true)

# Save shader to image, create image texture

static func generate_shader(src_code):
	var code
	code = "shader_type canvas_item;\n"
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	code += file.get_as_text()
	code += "\n"
	var shader_code = src_code.defs
	shader_code += "void fragment() {\n"
	shader_code += src_code.code
	shader_code += "COLOR = vec4("+src_code.rgb+", 1.0);\n"
	shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

static func generate_combined_shader(red_code, green_code, blue_code):
	var code
	code = "shader_type canvas_item;\n"
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	code += file.get_as_text()
	code += "\n"
	var shader_code = ""
	shader_code += red_code.defs
	shader_code += green_code.defs
	shader_code += blue_code.defs
	shader_code += "void fragment() {\n"
	shader_code += red_code.code
	shader_code += green_code.code
	shader_code += blue_code.code
	shader_code += "COLOR = vec4("+red_code.f+", "+green_code.f+", "+blue_code.f+", 1.0);\n"
	shader_code += "}\n"
	#print("GENERATED COMBINED SHADER:\n"+shader_code)
	code += shader_code
	return code

func setup_material(shader_material, textures, shader_code):
	for k in textures.keys():
		shader_material.set_shader_param(k+"_tex", textures[k])
	shader_material.shader.code = shader_code

func render_shader_to_viewport(shader, textures, render_size, method, args):
	render_queue.append( { shader=shader, textures=textures, size=render_size, method=method, args=args } )
	if render_queue.size() == 1:
		while !render_queue.empty():
			var job = render_queue.front()
			size = Vector2(job.size, job.size)
			$ColorRect.rect_position = Vector2(0, 0)
			$ColorRect.rect_size = Vector2(job.size, job.size)
			var shader_material = $ColorRect.material
			shader_material.shader.code = job.shader
			if job.textures != null:
				for k in job.textures.keys():
					shader_material.set_shader_param(k+"_tex", job.textures[k])
			render_target_update_mode = Viewport.UPDATE_ALWAYS
			update_worlds()
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			render_target_update_mode = Viewport.UPDATE_DISABLED
			callv(job.method, job.args)
			render_queue.pop_front()

func render_to_viewport(node, render_size, method, args):
	render_shader_to_viewport(node.generate_shader(), node.get_textures(), render_size, method, args)

func export_texture(node, filename, render_size = 256):
	if node == null:
		return null
	render_to_viewport(node, render_size, "do_export_texture", [ filename ])

func do_export_texture(filename):
	var viewport_texture = get_texture()
	var viewport_image = viewport_texture.get_data()
	viewport_image.save_png(filename)

func precalculate_node(node, render_size, target_texture, object, method, args):
	if node == null:
		return null
	render_to_viewport(node, render_size, "do_precalculate_texture", [ object, method, args ])

func precalculate_shader(shader, textures, render_size, target_texture, object, method, args):
	render_shader_to_viewport(shader, textures, render_size, "do_precalculate_texture", [ target_texture, object, method, args ])

func do_precalculate_texture(target_texture, object, method, args):
	var viewport_texture = get_texture()
	target_texture.create_from_image(viewport_texture.get_data())
	object.callv(method, args)
