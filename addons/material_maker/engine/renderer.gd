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
func render_text(object: Object, text: String, font_path: String, font_size: int,
		line_spacing: float, alignment: int, x: float, y: float,
		fg: Color, bg: Color, center: bool = false) -> Object:
	assert(render_owner == object)

	var font : Font = FontFile.new()
	if FileAccess.file_exists(font_path):
		if font.load_dynamic_font(font_path) == OK:
			pass
			#font.multichannel_signed_distance_field = true
			#font.msdf_size = 64
		elif font.load_bitmap_font(font_path) != OK:
			font = $Font/Label.get_theme_font("font")
	else:
		font = $Font/Label.get_theme_font("font")

	var label_settings : LabelSettings = LabelSettings.new()
	label_settings.font = font
	label_settings.font_size = font_size
	line_spacing = max(line_spacing,
			-font.get_string_size(text, 0, -1, font_size).y)
	label_settings.line_spacing = line_spacing

	$Font/Label.label_settings = label_settings
	$Font/Label.horizontal_alignment = alignment
	$Font/Label.text = text.replace("\\n","\n")
	$Font/Label.modulate = fg
	$Font.color = bg

	size = Vector2(2048, 2048)
	$Font.visible = true
	$Font.position = Vector2(0, 0)
	$Font.size = size
	$Font/Label.position = Vector2(2048*(0.5+x), 2048*(0.5+y))
	$Font/Label.add_theme_font_override("font", font)
	$Font/Label.add_theme_font_size_override("font_size", font_size)
	if center:
		$Font/Label.size = Vector2.ZERO
		$Font/Label.position -= $Font/Label.get_rect().size * 0.5
	$ColorRect.visible = false
	#hdr = true
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	texture = get_texture()
	$Font.visible = false
	$ColorRect.visible = true
	return self

func render_material(object : Object, material : Material, render_size : int, with_hdr : bool = true) -> Object:
	assert(render_owner == object)
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
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		texture = ImageTexture.create_from_image(get_texture().get_image())
	else:
		var image : Image = Image.create(render_size, render_size, false, get_texture().get_image().get_format())
		material.set_shader_parameter("mm_chunk_size", render_scale)
		for x in range(chunk_count):
			for y in range(chunk_count):
				material.set_shader_parameter("mm_chunk_offset", render_scale*Vector2(x, y))
				render_target_update_mode = SubViewport.UPDATE_ONCE
				await get_tree().process_frame
				await get_tree().process_frame
				image.blit_rect(get_texture().get_image(), Rect2(0, 0, size.x, size.y), Vector2(x*size.x, y*size.y))
		texture = ImageTexture.new()
		texture.set_image(image)
	$ColorRect.material = null
	return self

func render_shader(object : Object, shader_code : String, render_size : int, with_hdr : bool = true) -> Object:
	var shader_material = ShaderMaterial.new()
	var shader : Shader = Shader.new() 
	shader.code = shader_code
	shader_material.shader = shader
	mm_deps.material_update_params(MMShaderMaterial.new(shader_material))
	var status = await render_material(object, shader_material, render_size, with_hdr)
	return self

func copy_to_texture(t : ImageTexture) -> void:
	var image : Image = texture.get_image()
	if image != null:
		t.set_image(image)

func get_image() -> Image:
	var image : Image = Image.new()
	image.copy_from(texture.get_image())
	return image

func save_to_file(fn : String, is_greyscale : bool = false) -> void:
	var image : Image = texture.get_image()
	if image != null:
		var export_image : Image = image
		match fn.get_extension():
			"png":
				export_image.save_png(fn)
			"jpg":
				export_image.save_jpg(fn, 1.0)
			"webp":
				export_image.save_webp(fn)
			"exr":
				if is_greyscale:
					export_image = Image.new()
					export_image.copy_from(image)
					export_image.convert(Image.FORMAT_RH)
				else:
					pass
				export_image.save_exr(fn, is_greyscale)

func release(object : Object) -> void:
	assert(render_owner == object)
	render_owner = null
	texture = null
	get_parent().release(self)
