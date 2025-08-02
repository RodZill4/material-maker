extends PanelContainer

@onready var preview3D := owner

@onready var Tonemap := %Tonemap
@onready var TonemapMode := %TonemapMode
@onready var TonemapExposure := %TonemapExposure
@onready var TonemapWhite := %TonemapWhite

@onready var Glow := %Glow
@onready var GlowBleed := %GlowBleed
@onready var GlowBloom := %GlowBloom
@onready var GlowIntensity := %GlowIntensity
@onready var GlowStrength := %GlowStrength
@onready var GlowIntensityLabel := %GlowIntensityLabel
@onready var GlowBlendMode := %GlowBlendMode
@onready var GlowBlendMix := %GlowBlendMix
@onready var GlowBlendMixLabel := %GlowBlendMixLabel
@onready var GlowThreshold := %GlowThreshold
@onready var GlowClamp := %GlowClamp

@onready var Adjustment := %Adjustment
@onready var AdjustmentBrightness := %AdjustmentBrightness
@onready var AdjustmentContrast := %AdjustmentContrast
@onready var AdjustmentSaturation := %AdjustmentSaturation

const SETTING_PREVIEW_TONEMAP_ENABLED := "ui_3d_preview_tonemap_enabled"
const SETTING_PREVIEW_TONEMAP := "ui_3d_preview_tonemap"
const SETTING_PREVIEW_TONEMAP_WHITE := "ui_3d_preview_tonemap_white"
const SETTING_PREVIEW_TONEMAP_EXPOSURE := "ui_3d_preview_tonemap_exposure"

const SETTING_PREVIEW_GLOW_ENABLED := "ui_3d_preview_glow_enabled"
const SETTING_PREVIEW_GLOW_SIZE := "ui_3d_preview_glow_size"
const SETTING_PREVIEW_GLOW_BLOOM := "ui_3d_preview_glow_bloom"
const SETTING_PREVIEW_GLOW_INTENSITY := "ui_3d_preview_glow_intensity"
const SETTING_PREVIEW_GLOW_STRENGTH := "ui_3d_preview_glow_strength"
const SETTING_PREVIEW_GLOW_BLEND_MODE := "ui_3d_preview_glow_blend_mode"
const SETTING_PREVIEW_GLOW_BLEND_MIX_FAC := "ui_3d_preview_glow_blend_mix_factor"
const SETTING_PREVIEW_GLOW_LOWER_THRESHOLD := "ui_3d_preview_glow_lower_threshold"
const SETTING_PREVIEW_GLOW_UPPER_THRESHOLD := "ui_3d_preview_glow_upper_threshold"

const SETTING_PREVIEW_ADJUSTMENT_ENABLED := "ui_3d_preview_adjustment_enabled"
const SETTING_PREVIEW_ADJUSTMENT_BRIGHTNESS := "ui_3d_preview_adjustment_brightness"
const SETTING_PREVIEW_ADJUSTMENT_CONTRAST := "ui_3d_preview_adjustment_contrast"
const SETTING_PREVIEW_ADJUSTMENT_SATURATION := "ui_3d_preview_adjustment_saturation"

var environment : Environment


func _open() -> void:
	pass


func _ready() -> void:
	await preview3D.ready
	environment = preview3D.environment

	if mm_globals.has_config(SETTING_PREVIEW_TONEMAP_ENABLED):
		Tonemap.button_pressed = mm_globals.get_config(SETTING_PREVIEW_TONEMAP_ENABLED)
		restore_tonemap_settings()

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_ENABLED):
		Glow.button_pressed = mm_globals.get_config(SETTING_PREVIEW_GLOW_ENABLED)
		environment.glow_enabled = Glow.button_pressed
		$VBoxContainer/GlowSection.visible = Glow.button_pressed

	restore_glow_settings()

	if mm_globals.has_config(SETTING_PREVIEW_ADJUSTMENT_ENABLED):
		Adjustment.button_pressed = mm_globals.get_config(SETTING_PREVIEW_ADJUSTMENT_ENABLED)
		environment.adjustment_enabled = Adjustment.button_pressed
		$VBoxContainer/AdjustmentSection.visible = Adjustment.button_pressed

	restore_adjustment_settings()


func _on_minimum_size_changed() -> void:
	size = get_combined_minimum_size()


func _on_glow_blending_item_selected(index: int) -> void:
	environment.glow_blend_mode = index
	mm_globals.set_config(SETTING_PREVIEW_GLOW_BLEND_MODE, index)
	GlowBlendMix.visible = index == Environment.GLOW_BLEND_MODE_MIX
	GlowBlendMixLabel.visible = index == Environment.GLOW_BLEND_MODE_MIX
	GlowIntensity.visible = GlowBlendMode.selected != Environment.GLOW_BLEND_MODE_MIX
	GlowIntensityLabel.visible = GlowBlendMode.selected != Environment.GLOW_BLEND_MODE_MIX


func _on_glow_blend_mix_value_changed(value: Variant) -> void:
	environment.glow_mix = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_BLEND_MIX_FAC, value)


func _on_glow_size_value_changed(value: Variant) -> void:
	environment.glow_hdr_scale = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_SIZE, value)


func _on_glow_toggled(toggled_on: bool) -> void:
	environment.glow_enabled = toggled_on
	$VBoxContainer/GlowSection.visible = Glow.button_pressed
	mm_globals.set_config(SETTING_PREVIEW_GLOW_ENABLED, toggled_on)


func _on_glow_bloom_value_changed(value: Variant) -> void:
	environment.glow_bloom = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_BLOOM, value)


func _on_glow_intensity_value_changed(value: Variant) -> void:
	environment.glow_intensity = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_INTENSITY, value)


func _on_glow_threshold_value_changed(value: Variant) -> void:
	environment.glow_hdr_threshold = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_LOWER_THRESHOLD, value)


func _on_glow_clamp_value_changed(value: Variant) -> void:
	environment.glow_hdr_luminance_cap = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_UPPER_THRESHOLD, value)


func _on_glow_strength_value_changed(value: Variant) -> void:
	environment.glow_strength = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_STRENGTH, value)


func _on_adjustment_toggled(toggled_on: bool) -> void:
	environment.adjustment_enabled = toggled_on
	$VBoxContainer/AdjustmentSection.visible = toggled_on
	mm_globals.set_config(SETTING_PREVIEW_ADJUSTMENT_ENABLED, toggled_on)


func _on_adjustment_brightness_value_changed(value: Variant) -> void:
	environment.adjustment_brightness = value
	mm_globals.set_config(SETTING_PREVIEW_ADJUSTMENT_BRIGHTNESS, value)


func _on_adjustment_contrast_value_changed(value: Variant) -> void:
	environment.adjustment_contrast = value
	mm_globals.set_config(SETTING_PREVIEW_ADJUSTMENT_CONTRAST, value)


func _on_adjustment_saturation_value_changed(value: Variant) -> void:
	environment.adjustment_saturation = value
	mm_globals.set_config(SETTING_PREVIEW_ADJUSTMENT_SATURATION, value)


func restore_tonemap_settings(force_update : bool = false) -> void:
	if Tonemap.button_pressed or force_update:
		if mm_globals.has_config(SETTING_PREVIEW_TONEMAP):
			TonemapMode.selected = mm_globals.get_config(SETTING_PREVIEW_TONEMAP)
			environment.tonemap_mode = TonemapMode.selected

		if mm_globals.has_config(SETTING_PREVIEW_TONEMAP_EXPOSURE):
			TonemapExposure.value = mm_globals.get_config(SETTING_PREVIEW_TONEMAP_EXPOSURE)
			environment.tonemap_exposure = TonemapExposure.value

		if mm_globals.has_config(SETTING_PREVIEW_TONEMAP_WHITE):
			TonemapWhite.value = mm_globals.get_config(SETTING_PREVIEW_TONEMAP_WHITE)
			environment.tonemap_white = TonemapWhite.value


func restore_glow_settings() -> void:
	if mm_globals.has_config(SETTING_PREVIEW_GLOW_SIZE):
		GlowBleed.value = mm_globals.get_config(SETTING_PREVIEW_GLOW_SIZE)
		environment.glow_hdr_scale = GlowBleed.value

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_BLOOM):
		GlowBloom.value = mm_globals.get_config(SETTING_PREVIEW_GLOW_BLOOM)
		environment.glow_bloom = GlowBloom.value

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_INTENSITY):
		GlowIntensity.value = mm_globals.get_config(SETTING_PREVIEW_GLOW_INTENSITY)
		environment.glow_intensity = GlowIntensity.value

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_STRENGTH):
		GlowStrength.value = mm_globals.get_config(SETTING_PREVIEW_GLOW_STRENGTH)
		environment.glow_strength = GlowStrength.value

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_BLEND_MODE):
		GlowBlendMode.selected = mm_globals.get_config(SETTING_PREVIEW_GLOW_BLEND_MODE)
		environment.glow_blend_mode = GlowBlendMode.selected
		GlowBlendMix.visible = GlowBlendMode.selected == Environment.GLOW_BLEND_MODE_MIX
		GlowBlendMixLabel.visible = GlowBlendMode.selected == Environment.GLOW_BLEND_MODE_MIX
		GlowIntensity.visible = GlowBlendMode.selected != Environment.GLOW_BLEND_MODE_MIX
		GlowIntensityLabel.visible = GlowBlendMode.selected != Environment.GLOW_BLEND_MODE_MIX

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_BLEND_MIX_FAC):
		GlowBlendMix.value = mm_globals.get_config(SETTING_PREVIEW_GLOW_BLEND_MIX_FAC)
		environment.glow_mix = GlowBlendMix.value

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_LOWER_THRESHOLD):
		GlowThreshold.value = mm_globals.get_config(SETTING_PREVIEW_GLOW_LOWER_THRESHOLD)
		environment.glow_hdr_threshold = GlowThreshold.value

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_UPPER_THRESHOLD):
		GlowClamp.value = mm_globals.get_config(SETTING_PREVIEW_GLOW_UPPER_THRESHOLD)
		environment.glow_hdr_luminance_cap = GlowClamp.value


func restore_adjustment_settings() -> void:
	if mm_globals.has_config(SETTING_PREVIEW_ADJUSTMENT_BRIGHTNESS):
		AdjustmentBrightness.value = mm_globals.get_config(SETTING_PREVIEW_ADJUSTMENT_BRIGHTNESS)
		environment.adjustment_brightness = AdjustmentBrightness.value

	if mm_globals.has_config(SETTING_PREVIEW_ADJUSTMENT_CONTRAST):
		AdjustmentContrast.value = mm_globals.get_config(SETTING_PREVIEW_ADJUSTMENT_CONTRAST)
		environment.adjustment_contrast = AdjustmentContrast.value

	if mm_globals.has_config(SETTING_PREVIEW_ADJUSTMENT_SATURATION):
		AdjustmentSaturation.value = mm_globals.get_config(SETTING_PREVIEW_ADJUSTMENT_SATURATION)
		environment.adjustment_saturation = AdjustmentSaturation.value


func _on_tonemap_toggled(toggled_on: bool) -> void:
	$VBoxContainer/TonemapSection.visible = toggled_on
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP_ENABLED, toggled_on)
	if not toggled_on:
		environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		environment.tonemap_exposure = 1.0
		environment.tonemap_white = 1.0
	else:
		restore_tonemap_settings()


func _on_tone_map_item_selected(index: int) -> void:
	environment.tonemap_mode = index
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP, index)


func _on_tonemap_white_value_changed(value: Variant) -> void:
	environment.tonemap_white = value
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP_WHITE, value)


func _on_tonemap_exposure_value_changed(value: Variant) -> void:
	environment.tonemap_exposure = value
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP_EXPOSURE, value)

func reset_post_process_section(section : String) -> void:
	for setting in mm_globals.DEFAULT_CONFIG:
		if section in setting and "enable" not in setting:
			mm_globals.set_config(setting, mm_globals.DEFAULT_CONFIG[setting])


func _on_reset_tonemap_section_pressed() -> void:
	reset_post_process_section("preview_tonemap")
	restore_tonemap_settings(true)


func _on_reset_glow_section_pressed() -> void:
	reset_post_process_section("preview_glow")
	restore_glow_settings()


func _on_reset_adjustment_section_pressed() -> void:
	reset_post_process_section("preview_adjustment")
	restore_adjustment_settings()
