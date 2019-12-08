extends ColorRect

func _ready() -> void:
	material = material.duplicate(true)

func set_preview_texture(tex: Texture) -> void:
	material.set_shader_param("tex", tex)
