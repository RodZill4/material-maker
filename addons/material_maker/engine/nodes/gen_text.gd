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

func get_description() -> String:
	var desc_list : PackedStringArray = PackedStringArray()
	desc_list.push_back(TranslationServer.translate("Text"))
	desc_list.push_back(TranslationServer.translate("Text as a grayscale image"))
	return "\n".join(desc_list)

func get_parameter_defs() -> Array:
	return [
		{ name="text", label="Text", type="string", default="Text" },
		{ name="font", label="Font", type="file", filters=[ "*.otf,*.ttf,*.fnt;Font file" ], default="" },
		{ name="fg", label="Foreground", type="color", default={ r=1.0, g=0.0, b=1.0, a=1.0} },
		{ name="bg", label="Background", type="color", default={ r=0.0, g=0.0, b=0.0, a=1.0} },
		{ name="font_size", label="Font size", type="float", min=0, max=128, step=1, default=32 },
		{ name="line_spacing", label="Line Spacing", type="float", min=-512, max=512, step=1, default=0.0 },
		{ name="alignment", label="Align", default=0, type="enum", values=[
				{ "name": "Left", "value": "0" },
				{ "name": "Center", "value": "1" },
				{ "name": "Right", "value": "2" }
				]},
		{ name="center", label="Center", type="boolean", default=false },
		{ name="x", label="X", type="float", min=-0.5, max=0.5, step=0.001, default=0.1, control="P1.x" },
		{ name="y", label="Y", type="float", min=-0.5, max=0.5, step=0.001, default=0.1, control="P1.y" }
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
			renderer = await renderer.render_text(self,
					get_parameter("text"),
					get_parameter("font"),
					int(calculate_float_param("font_size", 64)),
					calculate_float_param("line_spacing"),
					int(get_parameter("alignment")),
					calculate_float_param("x"),
					calculate_float_param("y"),
					get_parameter("fg"),
					get_parameter("bg"),
					get_parameter("center"))
		var image_texture : ImageTexture = ImageTexture.new()
		renderer.copy_to_texture(image_texture)
		renderer.release(self)
		texture.set_texture(image_texture)
		mm_deps.dependency_update("o%d_tex" % get_instance_id(), texture)
		mm_deps.update()
		updating = false

func _serialize(data: Dictionary) -> Dictionary:
	return data
