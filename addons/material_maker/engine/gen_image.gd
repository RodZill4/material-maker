@tool
extends MMGenTexture
class_name MMGenImage


# Texture generator from image


var timer : Timer
var filetime : int = 0


func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2
	timer.start()
	timer.connect("timeout",Callable(self,"_on_timeout"))

func get_type() -> String:
	return "image"

func get_type_name() -> String:
	return "Image"

func get_parameter_defs() -> Array:
	return [
		{ name="image", type="image_path", label="", default="" },
		{ name="fix_ar", type="boolean", label="Fix Aspect Ratio", default=false },
		{ name="clamp", type="boolean", label="Clamp", default=false }
	]

func get_filetime(file_path : String) -> int:
	if FileAccess.file_exists(file_path):
		return FileAccess.get_modified_time(file_path)
	return 0

func get_adjusted_uv(uv : String) -> String:
	if get_parameter("fix_ar"):
		var ar : float = texture.get_height()
		ar /= texture.get_width()
		uv = "((%s) - vec2(0.0, %f)) * vec2(1.0, %f)" % [uv, (1-ar)/2, 1/ar]

	if get_parameter("clamp"):
		uv = "clamp(%s, 0.0, 1.0)" % uv

	return uv

func set_parameter(n : String, v) -> void:
	super.set_parameter(n, v)
	if n == "image":
		filetime = get_filetime(v)
		texture.load(v)
		mm_deps.dependency_update("o%d_tex" % get_instance_id(), texture)

func _on_timeout() -> void:
	var file_path : String = get_parameter("image")
	var new_filetime : int = get_filetime(file_path)
	if filetime != new_filetime:
		filetime = new_filetime
		var image : Image = Image.new()
		image.load(file_path)
		texture.create_from_image(image)
		super.set_parameter("image", file_path)
		mm_deps.dependency_update("o%d_tex" % get_instance_id(), texture)

func _serialize(data: Dictionary) -> Dictionary:
	return data

func _serialize_data(data: Dictionary) -> Dictionary:
	var image_path : String = data.parameters.image
	image_path = image_path.replace(mm_loader.current_project_path, "%PROJECT_PATH%")
	image_path = image_path.replace(OS.get_user_data_dir(), "%USER_DATA_PATH%")
	image_path = image_path.replace(MMPaths.get_resource_dir(), "%MATERIAL_MAKER_PATH%")
	data.parameters.image = image_path
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("parameters") and data.parameters.has("image"):
		data.parameters.image = data.parameters.image.replace("%PROJECT_PATH%", mm_loader.current_project_path)
		data.parameters.image = data.parameters.image.replace("%USER_DATA_PATH%", OS.get_user_data_dir())
		data.parameters.image = data.parameters.image.replace("%MATERIAL_MAKER_PATH%", MMPaths.get_resource_dir())
	elif data.has("image"):
		data.image = data.image.replace("%PROJECT_PATH%", mm_loader.current_project_path)
		data.image = data.image.replace("%USER_DATA_PATH%", OS.get_user_data_dir())
		data.image = data.image.replace("%MATERIAL_MAKER_PATH%", MMPaths.get_resource_dir())
