tool
extends Viewport


var render_owner : Object = null

var texture : Texture


signal done


func _ready() -> void:
	$ColorRect.material = $ColorRect.material.duplicate(true)

func setup_material(shader_material, textures, shader_code) -> void:
	shader_material.shader.code = shader_code
	for k in textures.keys():
		shader_material.set_shader_param(k+"_tex", textures[k])

func request(object : Object) -> Object:
	assert(render_owner == null)
	render_owner = object
	return self

var current_font : String = ""
func render_text(object : Object, text : String, font_path : String, font_size : int, x : float, y : float, center : bool = false) -> Object:
	assert(render_owner == object, "Invalid renderer use")
	size = Vector2(2048, 2048)
	$Font.visible = true
	$Font.rect_position = Vector2(0, 0)
	$Font.rect_size = size
	$Font/Label.text = text
	$Font/Label.rect_position = Vector2(2048*(0.5+x), 2048*(0.5+y))
	var font : Font = $Font/Label.get_font("font")
	if font_path != "" and font_path != current_font:
		var font_data = load(font_path)
		if font_data != null:
			font.font_data = font_data
			current_font = font_path
	font.size = font_size
	if center:
		$Font/Label.rect_position -= 0.5*font.get_string_size(text)
	$ColorRect.visible = false
	hdr = true
	render_target_update_mode = Viewport.UPDATE_ONCE
	update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	texture = get_texture()
	$Font.visible = false
	$ColorRect.visible = true
	return self

func render_material(object : Object, material : Material, render_size : int, with_hdr : bool = true) -> Object:
	assert(render_owner == object, "Invalid renderer use")
	if mm_renderer.max_buffer_size != 0 and render_size > mm_renderer.max_buffer_size:
		render_size = mm_renderer.max_buffer_size
	var shader_material = $ColorRect.material
	var chunk_count : int = 1
	var render_scale : float = 1.0
	var max_viewport_size : int = mm_renderer.max_viewport_size
	if render_size <= max_viewport_size:
		size = Vector2(render_size, render_size)
	else:
		chunk_count = render_size/max_viewport_size
		render_scale = float(max_viewport_size)/float(render_size)
		size = Vector2(max_viewport_size, max_viewport_size)
	$ColorRect.rect_position = Vector2(0, 0)
	$ColorRect.rect_size = size
	$ColorRect.material = material
	if OS.get_name() == "HTML5":
		hdr = false
	else:
		hdr = with_hdr
	if chunk_count == 1:
		material.set_shader_param("mm_chunk_size", 1.0)
		material.set_shader_param("mm_chunk_offset", Vector2(0.0, 0.0))
		render_target_update_mode = Viewport.UPDATE_ONCE
		update_worlds()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		texture = get_texture()
	else:
		var image : Image = Image.new()
		image.create(render_size, render_size, false, get_texture().get_data().get_format())
		material.set_shader_param("mm_chunk_size", render_scale)
		for x in range(chunk_count):
			for y in range(chunk_count):
				material.set_shader_param("mm_chunk_offset", render_scale*Vector2(x, y))
				render_target_update_mode = Viewport.UPDATE_ONCE
				update_worlds()
				yield(get_tree(), "idle_frame")
				yield(get_tree(), "idle_frame")
				image.blit_rect(get_texture().get_data(), Rect2(0, 0, size.x, size.y), Vector2(x*size.x, y*size.y))
		texture = ImageTexture.new()
		texture.create_from_image(image)
	$ColorRect.material = shader_material
	return self

func render_shader(object : Object, shader : String, textures : Dictionary, render_size : int, with_hdr : bool = true) -> Object:
	var shader_material = $ColorRect.material
	shader_material.shader.code = shader
	if textures != null:
		for k in textures.keys():
			shader_material.set_shader_param(k, textures[k])
	var status = render_material(object, shader_material, render_size, with_hdr)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	return self

func copy_to_texture(t : ImageTexture) -> void:
	var image : Image = texture.get_data()
	if image != null:
		t.create_from_image(image)

func get_image() -> Image:
	var image : Image = Image.new()
	image.copy_from(texture.get_data())
	return image

func save_to_file(fn : String, is_greyscale : bool = false) -> void:
	var image : Image = texture.get_data()
	if image != null:
		image.lock()
		var export_image : Image = image
		match fn.get_extension():
			"png":
				export_image.save_png(fn)
			"exr":
				if is_greyscale:
					export_image = Image.new()
					export_image.copy_from(image)
					export_image.convert(Image.FORMAT_RH)
				else:
					pass
				export_image.save_exr(fn, is_greyscale)
		image.unlock()

func release(object : Object) -> void:
	assert(render_owner == object, "Invalid renderer release")
	render_owner = null
	texture = null
	get_parent().release(self)
