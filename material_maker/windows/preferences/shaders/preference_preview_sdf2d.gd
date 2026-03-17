class_name PreferencesSdf2dPreview
extends ColorRect

const SETTING_SDF2D_BG_COLOR := "ui_preview_sdf2d_background_color"
const SETTING_SDF2D_FG_COLOR_1 := "ui_preview_sdf2d_foreground_color1"
const SETTING_SDF2D_FG_COLOR_2 := "ui_preview_sdf2d_foreground_color2"
const SETTING_SDF2D_BORDER_THICKNESS := "ui_preview_sdf2d_border_thickness"
const SETTING_SDF2D_ISOLINE_DENSITY := "ui_preview_sdf2d_isoline_density"
const SETTING_SDF2D_ISOLINE_THICKNESS := "ui_preview_sdf2d_isoline_thickness"
const SETTING_SDF2D_ISOLINE_OPACITY := "ui_preview_sdf2d_isoline_opacity"
const SETTING_SDF2D_ISOLINE_SMOOTH := "ui_preview_sdf2d_isoline_smoothness"
const SETTING_SDF2D_SHADOW_OPACITY := "ui_preview_sdf2d_shadow_opacity"

func _on_ready() -> void:
	await get_tree().process_frame
	material.set_shader_parameter("bg", %BgColor.color)
	material.set_shader_parameter("fg1", %FgColor1.color)
	material.set_shader_parameter("fg2", %FgColor2.color)
	material.set_shader_parameter("_border", %BorderThickness.value)
	material.set_shader_parameter("_id", %IsolineDensity.value)
	material.set_shader_parameter("_it", %IsolineThickness.value)
	material.set_shader_parameter("io", %IsolineOpacity.value)
	material.set_shader_parameter("is", %IsolineSmoothness.value)
	material.set_shader_parameter("sha", %ShadowFac.value)

static func get_shader_code(preview_code : String) -> String:
	const vec3_str : String = "vec3(%s, %s, %s)"
	var bg : Color = mm_globals.get_config(SETTING_SDF2D_BG_COLOR)
	var fg1 : Color = mm_globals.get_config(SETTING_SDF2D_FG_COLOR_1)
	var fg2 : Color = mm_globals.get_config(SETTING_SDF2D_FG_COLOR_2)
	var border_thickness : float = mm_globals.get_config(SETTING_SDF2D_BORDER_THICKNESS)
	var isoline_density : float = mm_globals.get_config(SETTING_SDF2D_ISOLINE_DENSITY)
	var isoline_thickness : float = mm_globals.get_config(SETTING_SDF2D_ISOLINE_THICKNESS)
	var isoline_opacity : float = mm_globals.get_config(SETTING_SDF2D_ISOLINE_OPACITY)
	var isoline_smoothness : float = mm_globals.get_config(SETTING_SDF2D_ISOLINE_SMOOTH)
	var shadow_opacity : float = mm_globals.get_config(SETTING_SDF2D_SHADOW_OPACITY)
	preview_code = preview_code.replace("$(bg)",  vec3_str % [bg.r, bg.g, bg.b])
	preview_code = preview_code.replace("$(fg1)", vec3_str % [fg1.r, fg1.g, fg1.b])
	preview_code = preview_code.replace("$(fg2)", vec3_str % [fg2.r, fg2.g, fg2.b])
	preview_code = preview_code.replace("$(border_thickness)", str(border_thickness))
	preview_code = preview_code.replace("$(isolines_density)", str(isoline_density))
	preview_code = preview_code.replace("$(isolines_thickness)", str(isoline_thickness))
	preview_code = preview_code.replace("$(isolines_opacity)", str(isoline_opacity))
	preview_code = preview_code.replace("$(isolines_smoothness)", str(isoline_smoothness))
	preview_code = preview_code.replace("$(shadow_opacity)", str(shadow_opacity))
	return preview_code

func load_defaults() -> void:
	%BgColor.color = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_BG_COLOR]
	%FgColor1.color = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_FG_COLOR_1]
	%FgColor2.color = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_FG_COLOR_2]
	%BorderThickness.value = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_BORDER_THICKNESS]
	%IsolineDensity.value = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_ISOLINE_DENSITY]
	%IsolineThickness.value = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_ISOLINE_THICKNESS]
	%IsolineOpacity.value = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_ISOLINE_OPACITY]
	%IsolineSmoothness.value = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_ISOLINE_SMOOTH]
	%ShadowFac.value = mm_globals.DEFAULT_CONFIG[SETTING_SDF2D_SHADOW_OPACITY]
	_on_ready()

func _on_border_thickness_value_changed(value : Variant) -> void:
	material.set_shader_parameter("_border", value)

func _on_isoline_density_value_changed(value : Variant) -> void:
	material.set_shader_parameter("_id", value)

func _on_isoline_opacity_value_changed(value : Variant) -> void:
	material.set_shader_parameter("io", value)

func _on_isoline_thickness_value_changed(value : Variant) -> void:
	material.set_shader_parameter("_it", value)

func _on_isoline_smoothness_value_changed(value : Variant) -> void:
	material.set_shader_parameter("is", value)

func _on_shadow_fac_value_changed(value : Variant) -> void:
	material.set_shader_parameter("sha", value)

func _on_fg_color_1_color_changed(c : Color) -> void:
	material.set_shader_parameter("fg1", c)

func _on_fg_color_2_color_changed(c : Color) -> void:
	material.set_shader_parameter("fg2", c)

func _on_bg_color_color_changed(c : Color) -> void:
	material.set_shader_parameter("bg", c)

func _on_reset_button_pressed() -> void:
	load_defaults()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var f : float = lerpf(0.0, 0.3, event.position.x / size.x)
		material.set_shader_parameter("preview_sdf_radius", f)

func _on_mouse_exited() -> void:
	material.set_shader_parameter("preview_sdf_radius", 0.3)
