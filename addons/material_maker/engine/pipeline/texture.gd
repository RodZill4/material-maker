extends RefCounted
class_name MMTexture


var rid : RID
var texture_size : Vector2i
var texture_format : RenderingDevice.DataFormat
var texture : ImageTexture
var texture_needs_update : bool = false


func _init() -> void:
	rid = RID()
	texture = ImageTexture.new()

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			#print("Deleting texture rid")
			if rid.is_valid():
				var rd = await mm_renderer.request_rendering_device(self)
				rd.free_rid(rid)
				mm_renderer.release_rendering_device(self)
				#print("Texture rid deleted")

func get_texture_rid(rd : RenderingDevice = null) -> RID:
	if ! rid.is_valid():
		var image : Image = texture.get_image()
		if image == null:
			print("No image for texture %s" % str(texture))
			image = Image.create(1, 1, false, Image.FORMAT_RH)
			texture_format = RenderingDevice.DATA_FORMAT_R16_SFLOAT
		var fmt : RDTextureFormat = RDTextureFormat.new()
		fmt.width = image.get_width()
		fmt.height = image.get_height()
		fmt.format = texture_format
		fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		var view : RDTextureView = RDTextureView.new()
		rid = rd.texture_create(fmt, view, [ image.get_data() ])
	return rid

func set_texture_rid(new_rid : RID, size : Vector2i, format : RenderingDevice.DataFormat, rd : RenderingDevice = null) -> void:
	if rid.is_valid():
		if rd != null:
			rd.free_rid(rid)
		else:
			rd = await mm_renderer.request_rendering_device(self)
			rd.free_rid(rid)
			mm_renderer.release_rendering_device(self)
	rid = new_rid
	texture_size = size
	texture_format = format
	texture_needs_update = true

func get_texture() -> ImageTexture:
	if texture_needs_update:
		var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
		var byte_data : PackedByteArray = rd.texture_get_data(rid, 0)
		mm_renderer.release_rendering_device(self)
		var image_format : Image.Format
		match texture_format:
			RenderingDevice.DATA_FORMAT_R32_SFLOAT:
				image_format = Image.FORMAT_RF
			RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT:
				image_format = Image.FORMAT_RGBAF
			RenderingDevice.DATA_FORMAT_R16_SFLOAT:
				image_format = Image.FORMAT_RH
			RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT:
				image_format = Image.FORMAT_RGBAH
			RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM:
				image_format = Image.FORMAT_RGBA8
		var image : Image = Image.create_from_data(texture_size.x, texture_size.y, false, image_format, byte_data)
		texture.set_image(image)
		texture_needs_update = false
	return texture

func set_texture(new_texture : ImageTexture) -> void:
	texture = new_texture
	texture_size = texture.get_size()
	var image : Image = texture.get_image()
	match image.get_format():
		Image.FORMAT_RF:
			texture_format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
		Image.FORMAT_RGBAF:
			texture_format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
		Image.FORMAT_RH:
			texture_format = RenderingDevice.DATA_FORMAT_R16_SFLOAT
		Image.FORMAT_RGBAH:
			texture_format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
		Image.FORMAT_RGBA8:
			texture_format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
		_:
			print("Unsupported texture format "+str(image.get_format()))
			image.convert(Image.FORMAT_RGBAH)
			texture.set_image(image)
			texture_format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	if rid.is_valid():
		var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
		rd.free_rid(rid)
		mm_renderer.release_rendering_device(self)
	rid = RID()

func get_width() -> int:
	return texture_size.x

func get_height() -> int:
	return texture_size.y

func save_to_file(file_name : String):
	var texture = await get_texture()
	var image : Image = texture.get_image()
	if image != null:
		var export_image : Image = image
		match file_name.get_extension():
			"png":
				export_image.save_png(file_name)
			"jpg":
				export_image.save_jpg(file_name, 1.0)
			"webp":
				export_image.save_webp(file_name)
			"exr":
				match image.get_format():
					Image.FORMAT_RF,Image.FORMAT_RH:
						export_image.save_exr(file_name, true)
					_:
						export_image.save_exr(file_name, false)
