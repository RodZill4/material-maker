@tool
extends SubViewport


var render_owner : Object = null

var texture : Texture2D


signal done


func request(object : Object) -> Object:
	assert(render_owner == null)
	render_owner = object
	return self

var current_font : String = ""
func render_text(object : Object, text : String, font_path : String, font_size : int, x : float, y : float, center : bool = false) -> Object:
	assert(render_owner == object) #,"Invalid renderer use")
	size = Vector2(2048, 2048)
	$Font.visible = true
	$Font.position = Vector2(0, 0)
	$Font.size = size
	$Font/Label.text = text
	$Font/Label.position = Vector2(2048*(0.5+x), 2048*(0.5+y))
	var font : Font = $Font/Label.get_font("font")
	if font_path != "" and font_path != current_font:
		var font_data = load(font_path)
		if font_data != null:
			font.font_data = font_data
			current_font = font_path
	font.size = font_size
	if center:
		$Font/Label.position -= 0.5*font.get_string_size(text)
	$ColorRect.visible = false
	#hdr = true
	render_target_update_mode = SubViewport.UPDATE_ONCE
	#update_worlds()
	await get_tree().process_frame
	await get_tree().process_frame
	texture = get_texture()
	$Font.visible = false
	$ColorRect.visible = true
	return self

func render_material(object : Object, material : Material, render_size : int, with_hdr : bool = true) -> Object:
	assert(render_owner == object) #,"Invalid renderer use")
	if mm_renderer.max_buffer_size != 0 and render_size > mm_renderer.max_buffer_size:
		render_size = mm_renderer.max_buffer_size
	var chunk_count : int = 1
	var render_scale : float = 1.0
	var max_viewport_size : int = mm_renderer.max_viewport_size
	if render_size <= max_viewport_size:
		size = Vector2(render_size, render_size)
	else:
		chunk_count = render_size/max_viewport_size
		render_scale = float(max_viewport_size)/float(render_size)
		size = Vector2(max_viewport_size, max_viewport_size)
	$ColorRect.position = Vector2(0, 0)
	$ColorRect.size = size
	$ColorRect.material = material
	if OS.get_name() == "HTML5":
		pass
		#hdr = false
	else:
		pass
		#hdr = with_hdr
	if chunk_count == 1:
		material.set_shader_parameter("mm_chunk_size", 1.0)
		material.set_shader_parameter("mm_chunk_offset", Vector2(0.0, 0.0))
		render_target_update_mode = SubViewport.UPDATE_ONCE
		#update_worlds()
		await get_tree().process_frame
		await get_tree().process_frame
		texture = get_texture()
	else:
		var image : Image = Image.new()
		image.create(render_size, render_size, false, get_texture().get_data().get_format())
		material.set_shader_parameter("mm_chunk_size", render_scale)
		for x in range(chunk_count):
			for y in range(chunk_count):
				material.set_shader_parameter("mm_chunk_offset", render_scale*Vector2(x, y))
				render_target_update_mode = SubViewport.UPDATE_ONCE
				#update_worlds()
				await get_tree().process_frame
				await get_tree().process_frame
				image.blit_rect(get_texture().get_data(), Rect2(0, 0, size.x, size.y), Vector2(x*size.x, y*size.y))
		texture = ImageTexture.new()
		texture.create_from_image(image)
	$ColorRect.material = null
	return self

func render_shader(object : Object, shader : String, render_size : int, with_hdr : bool = true) -> Object:
	var shader_material = ShaderMaterial.new()
	shader_material.gdshader = Shader.new() 
	shader_material.gdshader.code = shader
	mm_deps.material_update_params(shader_material)
	var status = await render_material(object, shader_material, render_size, with_hdr)
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
		false # image.lock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
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
		false # image.unlock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed

func release(object : Object) -> void:
	assert(render_owner == object) #,"Invalid renderer release")
	render_owner = null
	texture = null
	get_parent().release(self)
