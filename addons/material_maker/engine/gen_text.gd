@tool
extends MMGenTexture
class_name MMGenText


# Texture generator from text


var updating : bool = false
var update_again : bool = false

func _ready() -> void:
	update_buffer()

func get_type() -> String:
	return "text"

func get_type_name() -> String:
	return "Text"

func get_parameter_defs() -> Array:
	return [
		{ name="text", type="string", default="Text" },
		{ name="font", type="file", filters=[ "*.otf,*.ttf,*.fnt;Font file" ], default="" },
		{ name="font_size", type="float", min=0, max=128, step=1, default=32 },
		{ name="center", type="boolean", default=false },
		{ name="x", type="float", min=-0.5, max=0.5, step=0.001, default=0.1, control="P1.x" },
		{ name="y", type="float", min=-0.5, max=0.5, step=0.001, default=0.1, control="P1.y" }
	]

func set_parameter(n : String, v) -> void:
	super.set_parameter(n, v)
	if is_inside_tree():
		update_buffer()

func calculate_float_param(n : String, default_value : float = 0.0) -> float:
	var param_value = get_parameter(n)
	if param_value is int:
		return float(param_value)
	elif param_value is float:
		return param_value
	elif param_value is String:
		var expression = Expression.new()
		var error = expression.parse(param_value, [])
		if error == OK:
			var result = expression.execute([], null, true)
			if not expression.has_execute_failed():
				if result is int:
					return float(result)
				elif result is float:
					return result
	return default_value

func update_buffer() -> void:
	update_again = true
	if !updating:
		updating = true
		var renderer = await mm_renderer.request(self)
		while update_again:
			update_again = false
			renderer = await renderer.render_text(self, get_parameter("text"), get_parameter("font"), int(calculate_float_param("font_size", 64)), calculate_float_param("x"), calculate_float_param("y"), get_parameter("center"))
		renderer.copy_to_texture(texture)
		renderer.release(self)
		mm_deps.dependency_update("o%d_tex" % get_instance_id(), texture)
		updating = false

func _serialize(data: Dictionary) -> Dictionary:
	return data
