tool
extends ColorRect

func set_preview_texture(tex: Texture) -> void:
	material.set_shader_param("tex", tex)

func on_resized() -> void:
	material.set_shader_param("size", rect_size)
