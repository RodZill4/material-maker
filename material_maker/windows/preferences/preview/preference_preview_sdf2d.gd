extends ColorRect


func _on_ready() -> void:
	await get_tree().process_frame
	material.set_shader_parameter("bg", %BackgroundColor.color)
	material.set_shader_parameter("fg1", %ForegroundColor1.color)
	material.set_shader_parameter("fg2", %ForegroundColor2.color)
	material.set_shader_parameter("_border", %BorderThickness.value)
	material.set_shader_parameter("_id", %IsolineDensity.value)
	material.set_shader_parameter("_it", %IsolineThickness.value)
	material.set_shader_parameter("io", %IsolineOpacity.value)
	material.set_shader_parameter("is", %IsolineSmoothness.value)
	material.set_shader_parameter("sha", %ShadowOpacity.value)

func _on_background_color_color_changed(color: Color) -> void:
	material.set_shader_parameter("bg", color)


func _on_foreground_color_1_color_changed(color: Color) -> void:
	material.set_shader_parameter("fg1", color)


func _on_foreground_color_2_color_changed(color: Color) -> void:
	material.set_shader_parameter("fg2", color)


func _on_border_thickness_value_changed(value: Variant) -> void:
	material.set_shader_parameter("_border", value)


func _on_isoline_density_value_changed(value: Variant) -> void:
	material.set_shader_parameter("_id", value)


func _on_isoline_opacity_value_changed(value: Variant) -> void:
	material.set_shader_parameter("io", value)


func _on_isoline_thickness_value_changed(value: Variant) -> void:
	material.set_shader_parameter("_it", value)


func _on_isoline_smoothness_value_changed(value: Variant) -> void:
	material.set_shader_parameter("is", value)


func _on_shadow_opacity_value_changed(value: Variant) -> void:
	material.set_shader_parameter("sha", value)
