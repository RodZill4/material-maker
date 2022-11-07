tool
extends MMGenTexture
class_name MMGenImage

var timer : Timer
var filetime : int = 0

"""
Texture generator from image
"""

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2
	timer.start()
	timer.connect("timeout", self, "_on_timeout")

func get_type() -> String:
	return "image"

func get_type_name() -> String:
	return "Image"

func get_parameter_defs() -> Array:
	return [ { name="image", type="image_path", label="", default="" } ]

func get_filetime(file_path : String) -> int:
	var f : File = File.new()
	if f.file_exists(file_path):
		return f.get_modified_time(file_path)
	return 0

func set_parameter(n : String, v) -> void:
	.set_parameter(n, v)
	if n == "image":
		filetime = get_filetime(v)
		texture.load(v)

func _on_timeout() -> void:
	var file_path : String = get_parameter("image")
	var new_filetime : int = get_filetime(file_path)
	if filetime != new_filetime:
		filetime = new_filetime
		var image : Image = Image.new()
		image.load(file_path)
		texture.create_from_image(image)
		.set_parameter("image", file_path)
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
