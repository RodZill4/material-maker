tool
extends MMGenTexture
class_name MMGenText

"""
Texture generator from text
"""

var updating : bool = false
var update_again : bool = false

func _ready() -> void:
	update_buffer()

func get_type() -> String:
	return "text"

func get_type_name() -> String:
	return "Text"

func get_parameter_defs() -> Array:
	return [ { name="text", type="string", default="Hello World" },
			 { name="font", type="file", filters=[ "*.otf,*.ttf,*.fnt;Font file" ], default="" },
			 { name="font_size", type="float", min=0, max=128, step=1, default=32 },
			 { name="center", type="boolean", default=false },
			 { name="x", type="float", min=-0.5, max=0.5, step=0.001, default=0.1, control="P1.x" },
			 { name="y", type="float", min=-0.5, max=0.5, step=0.001, default=0.1, control="P1.y" } ]

func set_parameter(n : String, v) -> void:
	.set_parameter(n, v)
	if is_inside_tree():
		update_buffer()

func update_buffer() -> void:
	update_again = true
	if !updating:
		updating = true
		while update_again:
			update_again = false
			var renderer = mm_renderer.request(self)
			while renderer is GDScriptFunctionState:
				renderer = yield(renderer, "completed")
			renderer = renderer.render_text(self, get_parameter("text"), get_parameter("font"), get_parameter("font_size"), get_parameter("x"), get_parameter("y"), get_parameter("center"))
			while renderer is GDScriptFunctionState:
				renderer = yield(renderer, "completed")
			if !update_again:
				renderer.copy_to_texture(texture)
			renderer.release(self)
		updating = false
		mm_deps.dependency_update("o%s_tex")

func _serialize(data: Dictionary) -> Dictionary:
	return data
