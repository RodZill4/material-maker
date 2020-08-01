tool
extends MMGenTexture
class_name MMGenText

"""
Texture generator from text
"""

var updating : bool = false
var update_again : bool = false

func get_type() -> String:
	return "text"

func get_type_name() -> String:
	return "Text"

func get_parameter_defs() -> Array:
	return [ { name="text", type="string", default="Hello World" },
			 { name="font", type="file", filters= [ "*.otf,*.ttf,*.fnt;Font file" ], default="" },
			 { name="font_size", type="float", min=0, max=128, step=1, default=32 },
			 { name="x", type="float", min=-0.5, max=0.5, step=0.001, default=0.1, control="P1.x" },
			 { name="y", type="float", min=-0.5, max=0.5, step=0.001, default=0.1, control="P1.y" } ]

func set_parameter(n : String, v) -> void:
	.set_parameter(n, v)
	update_buffer()

func update_buffer() -> void:
	update_again = true
	if !updating:
		updating = true
		while update_again:
			update_again = false
			var result = mm_renderer.render_text(get_parameter("text"), get_parameter("font"), get_parameter("font_size"), get_parameter("x"), get_parameter("y"))
			while result is GDScriptFunctionState:
				result = yield(result, "completed")
			if !update_again:
				result.copy_to_texture(texture)
			result.release()
		updating = false
		get_tree().call_group("preview", "on_texture_changed", "o%s_tex" % str(get_instance_id()))
