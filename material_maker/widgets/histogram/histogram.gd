extends Control

func update_histogram() -> void:
	pass

func get_image_texture() -> ImageTexture:
	return $ViewportImage/ColorRect.material.get_shader_param("tex")

func get_histogram_texture() -> ImageTexture:
	return $Control.material.get_shader_param("tex")
