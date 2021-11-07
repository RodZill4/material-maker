tool
extends Viewport


var render_owner : Object = null


signal done


func _ready() -> void:
	$ColorRect.material = $ColorRect.material.duplicate(true)

func setup_material(shader_material, textures, shader_code) -> void:
	for k in textures.keys():
		shader_material.set_shader_param(k+"_tex", textures[k])
	shader_material.shader.code = shader_code

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
	$Font.visible = false
	$ColorRect.visible = true
	return self

func render_material(object : Object, material : Material, render_size, with_hdr = true) -> Object:
	assert(render_owner == object, "Invalid renderer use")
	if mm_renderer.max_buffer_size != 0 and render_size > mm_renderer.max_buffer_size:
		render_size = mm_renderer.max_buffer_size
	var shader_material = $ColorRect.material
	size = Vector2(render_size, render_size)
	$ColorRect.rect_position = Vector2(0, 0)
	$ColorRect.rect_size = size
	$ColorRect.material = material
	hdr = with_hdr
	render_target_update_mode = Viewport.UPDATE_ONCE
	update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$ColorRect.material = shader_material
	return self

func render_shader(object : Object, shader, textures, render_size, with_hdr = true) -> Object:
	assert(render_owner == object, "Invalid renderer use")
	if mm_renderer.max_buffer_size != 0 and render_size > mm_renderer.max_buffer_size:
		render_size = mm_renderer.max_buffer_size
	size = Vector2(render_size, render_size)
	$ColorRect.rect_position = Vector2(0, 0)
	$ColorRect.rect_size = size
	var shader_material = $ColorRect.material
	shader_material.shader.code = shader
	if textures != null:
		for k in textures.keys():
			shader_material.set_shader_param(k, textures[k])
	shader_material.set_shader_param("preview_size", render_size)
	hdr = with_hdr
	render_target_update_mode = Viewport.UPDATE_ONCE
	update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	return self

func copy_to_texture(t : ImageTexture) -> void:
	var image : Image = get_texture().get_data()
	if image != null:
		t.create_from_image(image)

func get_image() -> Image:
	var image : Image = Image.new()
	image.copy_from(get_texture().get_data())
	return image

func save_to_file(fn : String, is_greyscale : bool = false) -> void:
	var image : Image = get_texture().get_data()
	if image != null:
		image.lock()
		print("Image format: "+str(image.get_format()))
		var export_image : Image = image
		match fn.get_extension():
			"png":
				export_image.save_png(fn)
			"exr":
				if is_greyscale:
					export_image = Image.new()
					export_image.copy_from(image)
					export_image.convert(Image.FORMAT_RH)
					print(export_image.get_format())
				export_image.save_exr(fn)
		image.unlock()

func release(object : Object) -> void:
	assert(render_owner == object, "Invalid renderer release")
	render_owner = null
	get_parent().release(self)
