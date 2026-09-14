extends PanelContainer

@onready var preview3D : SubViewportContainer = owner

@onready var TonemapSection : GridContainer = %TonemapSection
@onready var GlowSection : GridContainer = %GlowSection
@onready var AdjustmentSection : GridContainer = %AdjustmentSection
@onready var DepthOfFieldSection : VBoxContainer = %DepthOfFieldSection

@onready var Tonemap : CheckBox = %Tonemap
@onready var TonemapMode : MM_OptionEdit = %TonemapMode
@onready var TonemapExposure : FloatEdit = %TonemapExposure
@onready var TonemapWhite : FloatEdit = %TonemapWhite
@onready var TonemapWhiteLabel : Label = %TonemapWhiteLabel
@onready var TonemapAgXContrast : FloatEdit = %TonemapAgXContrast
@onready var TonemapAgXContrastLabel : Label = %TonemapAgXContrastLabel
@onready var TonemapAgXWhite := %TonemapAgXWhite
@onready var TonemapAgXWhiteLabel : Label = %TonemapAgXWhiteLabel

@onready var Glow : CheckBox = %Glow
@onready var GlowBleed : FloatEdit = %GlowBleed
@onready var GlowBloom : FloatEdit = %GlowBloom
@onready var GlowIntensity : FloatEdit = %GlowIntensity
@onready var GlowStrength : FloatEdit = %GlowStrength
@onready var GlowIntensityLabel : Label = %GlowIntensityLabel
@onready var GlowBlendMode : MM_OptionEdit = %GlowBlendMode
@onready var GlowBlendMix : FloatEdit = %GlowBlendMix
@onready var GlowBlendMixLabel : Label = %GlowBlendMixLabel
@onready var GlowThreshold : FloatEdit = %GlowThreshold
@onready var GlowClamp : FloatEdit = %GlowClamp

@onready var Adjustment : CheckBox = %Adjustment
@onready var AdjustmentBrightness : FloatEdit = %AdjustmentBrightness
@onready var AdjustmentContrast : FloatEdit = %AdjustmentContrast
@onready var AdjustmentSaturation : FloatEdit = %AdjustmentSaturation

@onready var DepthOfField : CheckBox = %DepthOfField
@onready var FarEnabled : CheckBox = %FarEnabled
@onready var NearEnabled : CheckBox = %NearEnabled
@onready var FarDistance : FloatEdit = %FarDistance
@onready var FarTransition : FloatEdit = %FarTransition
@onready var NearDistance : FloatEdit = %NearDistance
@onready var NearTransition : FloatEdit = %NearTransition
@onready var BlurAmount : FloatEdit = %BlurAmount
@onready var FarNearSettings : GridContainer = %FarNearSettings

@onready var ResetDofSection : Button = %ResetDofSection
@onready var ResetAdjustmentSection : Button = %ResetAdjustmentSection
@onready var ResetGlowSection : Button = %ResetGlowSection
@onready var ResetTonemapSection : Button = %ResetTonemapSection

#region configuration keys
const SETTING_PREVIEW_TONEMAP_ENABLED : String = "ui_3d_preview_tonemap_enabled"
const SETTING_PREVIEW_TONEMAP : String = "ui_3d_preview_tonemap"
const SETTING_PREVIEW_TONEMAP_WHITE : String = "ui_3d_preview_tonemap_white"
const SETTING_PREVIEW_TONEMAP_AGX_WHITE : String = "ui_3d_preview_tonemap_agx_white"
const SETTING_PREVIEW_TONEMAP_AGX_CONTRAST : String = "ui_3d_preview_tonemap_agx_contrast"
const SETTING_PREVIEW_TONEMAP_EXPOSURE : String = "ui_3d_preview_tonemap_exposure"

const SETTING_PREVIEW_GLOW_ENABLED : String = "ui_3d_preview_glow_enabled"
const SETTING_PREVIEW_GLOW_SIZE : String = "ui_3d_preview_glow_size"
const SETTING_PREVIEW_GLOW_BLOOM : String = "ui_3d_preview_glow_bloom"
const SETTING_PREVIEW_GLOW_INTENSITY : String = "ui_3d_preview_glow_intensity"
const SETTING_PREVIEW_GLOW_STRENGTH : String = "ui_3d_preview_glow_strength"
const SETTING_PREVIEW_GLOW_BLEND_MODE : String = "ui_3d_preview_glow_blend_mode"
const SETTING_PREVIEW_GLOW_BLEND_MIX_FAC : String = "ui_3d_preview_glow_blend_mix_factor"
const SETTING_PREVIEW_GLOW_LOWER_THRESHOLD : String = "ui_3d_preview_glow_lower_threshold"
const SETTING_PREVIEW_GLOW_UPPER_THRESHOLD : String = "ui_3d_preview_glow_upper_threshold"

const SETTING_PREVIEW_ADJUSTMENT_ENABLED : String = "ui_3d_preview_adjustment_enabled"
const SETTING_PREVIEW_ADJUSTMENT_BRIGHTNESS : String = "ui_3d_preview_adjustment_brightness"
const SETTING_PREVIEW_ADJUSTMENT_CONTRAST : String = "ui_3d_preview_adjustment_contrast"
const SETTING_PREVIEW_ADJUSTMENT_SATURATION : String = "ui_3d_preview_adjustment_saturation"

const SETTINGS_PREVIEW_DOF_ENABLED : String = "ui_3d_preview_dof_enabled"
const SETTINGS_PREVIEW_DOF_FAR : String = "ui_3d_preview_dof_far"
const SETTINGS_PREVIEW_DOF_NEAR : String = "ui_3d_preview_dof_near"
const SETTINGS_PREVIEW_DOF_BLUR_AMOUNT : String = "ui_3d_preview_dof_blur_amount"
const SETTINGS_PREVIEW_DOF_FAR_DIST : String = "ui_3d_preview_dof_far_distance"
const SETTINGS_PREVIEW_DOF_NEAR_DIST : String = "ui_3d_preview_dof_near_distance"
const SETTINGS_PREVIEW_DOF_FAR_TRANSITION : String = "ui_3d_preview_dof_far_transition"
const SETTINGS_PREVIEW_DOF_NEAR_TRANSITION : String = "ui_3d_preview_dof_near_transition"
#endregion

enum Section {
	TONEMAP,
	GLOW,
	ADJUSTMENT,
	DOF
}


var environment : Environment
var camera_attributes : CameraAttributesPractical

var custom_min_width : float

signal setting_changed(section : Section)

func _open() -> void:
	_on_v_box_container_minimum_size_changed()

func expand_panel_width() -> void:
	# minimize visual jumps (i.e. float field widths)
	# when scrollbar is added to the ScrollContainer
	var v_scroll : VScrollBar = $ScrollContainer.get_v_scroll_bar()
	custom_minimum_size.x = (custom_min_width + v_scroll.size.x
			if v_scroll.visible else custom_min_width)

func is_section_not_default(section_key : String) -> bool:
	var not_default : bool = true
	for config in mm_globals.DEFAULT_CONFIG.keys():
		var key : String = "ui_3d_preview_" + section_key
		if key in config and "enable" not in config:
			not_default = not_default and (mm_globals.get_config(config) == mm_globals.DEFAULT_CONFIG[config])
	return not_default

func check_setting_changed(section : Section) -> void:
	match section:
		Section.TONEMAP:
			ResetTonemapSection.disabled = is_section_not_default("tonemap")
		Section.GLOW:
			ResetGlowSection.disabled = is_section_not_default("glow")
		Section.ADJUSTMENT:
			ResetAdjustmentSection.disabled = is_section_not_default("adjustment")
		Section.DOF:
			ResetDofSection.disabled = is_section_not_default("dof")

func _ready() -> void:
	custom_min_width = custom_minimum_size.x
	$ScrollContainer.get_v_scroll_bar().visibility_changed.connect(
			expand_panel_width)
	setting_changed.connect(check_setting_changed)

	await preview3D.ready
	preview3D.resized.connect(_on_v_box_container_minimum_size_changed)

	environment = preview3D.environment
	camera_attributes = preview3D.camera_attributes

	if mm_globals.has_config(SETTING_PREVIEW_TONEMAP_ENABLED):
		Tonemap.button_pressed = mm_globals.get_config(SETTING_PREVIEW_TONEMAP_ENABLED)
	restore_tonemap_settings()

	if mm_globals.has_config(SETTING_PREVIEW_GLOW_ENABLED):
		Glow.button_pressed = mm_globals.get_config(SETTING_PREVIEW_GLOW_ENABLED)
		environment.glow_enabled = Glow.button_pressed
		GlowSection.visible = Glow.button_pressed
	restore_glow_settings()

	if mm_globals.has_config(SETTING_PREVIEW_ADJUSTMENT_ENABLED):
		Adjustment.button_pressed = mm_globals.get_config(SETTING_PREVIEW_ADJUSTMENT_ENABLED)
		AdjustmentSection.visible = Adjustment.button_pressed
		environment.adjustment_enabled = Adjustment.button_pressed
	restore_adjustment_settings()

	if mm_globals.has_config(SETTINGS_PREVIEW_DOF_ENABLED):
		DepthOfField.button_pressed = mm_globals.get_config(SETTINGS_PREVIEW_DOF_ENABLED)
		DepthOfFieldSection.visible = DepthOfField.button_pressed
	restore_dof_settings()

func _on_glow_blending_item_selected(index : Environment.GlowBlendMode) -> void:
	environment.glow_blend_mode = index
	mm_globals.set_config(SETTING_PREVIEW_GLOW_BLEND_MODE, index)
	GlowBlendMix.visible = index == Environment.GLOW_BLEND_MODE_MIX
	GlowBlendMixLabel.visible = index == Environment.GLOW_BLEND_MODE_MIX
	GlowIntensity.visible = GlowBlendMode.selected != Environment.GLOW_BLEND_MODE_MIX
	GlowIntensityLabel.visible = GlowBlendMode.selected != Environment.GLOW_BLEND_MODE_MIX
	setting_changed.emit(Section.GLOW)

func _on_glow_blend_mix_value_changed(value : Variant) -> void:
	environment.glow_mix = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_BLEND_MIX_FAC, value)
	setting_changed.emit(Section.GLOW)

func _on_glow_size_value_changed(value : Variant) -> void:
	environment.glow_hdr_scale = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_SIZE, value)
	setting_changed.emit(Section.GLOW)

func _on_glow_toggled(toggled_on : bool) -> void:
	environment.glow_enabled = toggled_on
	GlowSection.visible = Glow.button_pressed
	mm_globals.set_config(SETTING_PREVIEW_GLOW_ENABLED, toggled_on)
	setting_changed.emit(Section.GLOW)

func _on_glow_bloom_value_changed(value : Variant) -> void:
	environment.glow_bloom = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_BLOOM, value)
	setting_changed.emit(Section.GLOW)

func _on_glow_intensity_value_changed(value : Variant) -> void:
	environment.glow_intensity = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_INTENSITY, value)
	setting_changed.emit(Section.GLOW)

func _on_glow_threshold_value_changed(value : Variant) -> void:
	environment.glow_hdr_threshold = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_LOWER_THRESHOLD, value)
	setting_changed.emit(Section.GLOW)

func _on_glow_clamp_value_changed(value : Variant) -> void:
	environment.glow_hdr_luminance_cap = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_UPPER_THRESHOLD, value)
	setting_changed.emit(Section.GLOW)

func _on_glow_strength_value_changed(value : Variant) -> void:
	environment.glow_strength = value
	mm_globals.set_config(SETTING_PREVIEW_GLOW_STRENGTH, value)
	setting_changed.emit(Section.GLOW)

func _on_adjustment_toggled(toggled_on : bool) -> void:
	environment.adjustment_enabled = toggled_on
	AdjustmentSection.visible = toggled_on
	mm_globals.set_config(SETTING_PREVIEW_ADJUSTMENT_ENABLED, toggled_on)

func _on_adjustment_brightness_value_changed(value : Variant) -> void:
	environment.adjustment_brightness = value
	mm_globals.set_config(SETTING_PREVIEW_ADJUSTMENT_BRIGHTNESS, value)
	setting_changed.emit(Section.ADJUSTMENT)

func _on_adjustment_contrast_value_changed(value : Variant) -> void:
	environment.adjustment_contrast = value
	mm_globals.set_config(SETTING_PREVIEW_ADJUSTMENT_CONTRAST, value)
	setting_changed.emit(Section.ADJUSTMENT)

func _on_adjustment_saturation_value_changed(value : Variant) -> void:
	environment.adjustment_saturation = value
	mm_globals.set_config(SETTING_PREVIEW_ADJUSTMENT_SATURATION, value)
	setting_changed.emit(Section.ADJUSTMENT)

func restore_tonemap_settings(force_update : bool = false) -> void:
	if Tonemap.button_pressed or force_update:
		if mm_globals.has_config(SETTING_PREVIEW_TONEMAP):
			TonemapMode.selected = mm_globals.get_config(SETTING_PREVIEW_TONEMAP)
			environment.tonemap_mode = TonemapMode.selected as Environment.ToneMapper
			show_hide_tonemap_options(TonemapMode.selected)

		if mm_globals.has_config(SETTING_PREVIEW_TONEMAP_EXPOSURE):
			TonemapExposure.value = mm_globals.get_config(SETTING_PREVIEW_TONEMAP_EXPOSURE)
			environment.tonemap_exposure = TonemapExposure.value

		if mm_globals.has_config(SETTING_PREVIEW_TONEMAP_WHITE):
			TonemapWhite.value = mm_globals.get_config(SETTING_PREVIEW_TONEMAP_WHITE)
			environment.tonemap_white = TonemapWhite.value
		
		if mm_globals.has_config(SETTING_PREVIEW_TONEMAP_AGX_WHITE):
			TonemapAgXWhite.value = mm_globals.get_config(SETTING_PREVIEW_TONEMAP_AGX_WHITE)
			environment.tonemap_agx_white = TonemapAgXWhite.value
		
		if mm_globals.has_config(SETTING_PREVIEW_TONEMAP_AGX_CONTRAST):
			TonemapAgXContrast.value = mm_globals.get_config(SETTING_PREVIEW_TONEMAP_AGX_CONTRAST)
			environment.tonemap_agx_contrast = TonemapAgXContrast.value

	setting_changed.emit(Section.TONEMAP)

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
		environment.glow_blend_mode = GlowBlendMode.selected as Environment.GlowBlendMode
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
	
	setting_changed.emit(Section.GLOW)

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

	setting_changed.emit(Section.ADJUSTMENT)

func restore_dof_settings() -> void:
	if mm_globals.has_config(SETTINGS_PREVIEW_DOF_FAR):
		FarEnabled.button_pressed = mm_globals.get_config(SETTINGS_PREVIEW_DOF_FAR)
		camera_attributes.dof_blur_far_enabled = FarEnabled.button_pressed
		far_near_toggled("far", FarEnabled.button_pressed)

	if mm_globals.has_config(SETTINGS_PREVIEW_DOF_NEAR):
		NearEnabled.button_pressed = mm_globals.get_config(SETTINGS_PREVIEW_DOF_NEAR)
		camera_attributes.dof_blur_near_enabled = NearEnabled.button_pressed
		far_near_toggled("near", NearEnabled.button_pressed)

	if mm_globals.has_config(SETTINGS_PREVIEW_DOF_BLUR_AMOUNT):
		BlurAmount.value = mm_globals.get_config(SETTINGS_PREVIEW_DOF_BLUR_AMOUNT)
		camera_attributes.dof_blur_amount = BlurAmount.value

	if mm_globals.has_config(SETTINGS_PREVIEW_DOF_FAR_DIST):
		FarDistance.value = mm_globals.get_config(SETTINGS_PREVIEW_DOF_FAR_DIST)
		camera_attributes.dof_blur_far_distance = FarDistance.value

	if mm_globals.has_config(SETTINGS_PREVIEW_DOF_NEAR_DIST):
		NearDistance.value = mm_globals.get_config(SETTINGS_PREVIEW_DOF_NEAR_DIST)
		camera_attributes.dof_blur_near_distance = NearDistance.value

	if mm_globals.has_config(SETTINGS_PREVIEW_DOF_FAR_TRANSITION):
		FarTransition.value = mm_globals.get_config(SETTINGS_PREVIEW_DOF_FAR_TRANSITION)
		camera_attributes.dof_blur_far_transition = FarTransition.value

	if mm_globals.has_config(SETTINGS_PREVIEW_DOF_NEAR_TRANSITION):
		NearTransition.value = mm_globals.get_config(SETTINGS_PREVIEW_DOF_NEAR_TRANSITION)
		camera_attributes.dof_blur_near_transition = NearTransition.value

	setting_changed.emit(Section.DOF)

func _on_tonemap_toggled(toggled_on : bool) -> void:
	TonemapSection.visible = toggled_on
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP_ENABLED, toggled_on)
	if not toggled_on:
		environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		environment.tonemap_exposure = 1.0
		environment.tonemap_white = 1.0
	else:
		restore_tonemap_settings()

func agx_white_contrast(should_show : bool) -> void:
	for c : Control in TonemapSection.get_children():
		if "agx" in c.name.to_lower():
			c.visible = should_show

func show_hide_tonemap_options(tonemapper : Environment.ToneMapper) -> void:
	match tonemapper:
		Environment.ToneMapper.TONE_MAPPER_LINEAR:
			agx_white_contrast(false)
			TonemapWhiteLabel.hide()
			TonemapWhite.hide()
		Environment.ToneMapper.TONE_MAPPER_AGX:
			agx_white_contrast(true)
			TonemapWhiteLabel.hide()
			TonemapWhite.hide()
		_:
			agx_white_contrast(false)
			TonemapWhiteLabel.show()
			TonemapWhite.show()

func _on_tone_map_item_selected(tonemapper : Environment.ToneMapper) -> void:
	environment.tonemap_mode = tonemapper
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP, tonemapper)
	show_hide_tonemap_options(tonemapper)
	setting_changed.emit(Section.TONEMAP)

func _on_tonemap_white_value_changed(value : Variant) -> void:
	environment.tonemap_white = max(0.001, value)
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP_WHITE, value)
	setting_changed.emit(Section.TONEMAP)

func _on_tonemap_agx_white_value_changed(value : Variant) -> void:
	environment.tonemap_agx_white = max(0.001, value)
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP_AGX_WHITE, value)
	setting_changed.emit(Section.TONEMAP)

func _on_tonemap_agx_contrast_value_changed(value : Variant) -> void:
	environment.tonemap_agx_contrast = value
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP_AGX_CONTRAST, value)
	setting_changed.emit(Section.TONEMAP)

func _on_tonemap_exposure_value_changed(value : Variant) -> void:
	environment.tonemap_exposure = value
	mm_globals.set_config(SETTING_PREVIEW_TONEMAP_EXPOSURE, value)
	setting_changed.emit(Section.TONEMAP)

func reset_post_process_section(section : String) -> void:
	for setting in mm_globals.DEFAULT_CONFIG:
		if section in setting and "enable" not in setting:
			mm_globals.set_config(setting, mm_globals.DEFAULT_CONFIG[setting])

func _on_reset_tonemap_section_pressed() -> void:
	reset_post_process_section("preview_tonemap")
	restore_tonemap_settings(true)
	ResetTonemapSection.disabled = true

func _on_reset_glow_section_pressed() -> void:
	reset_post_process_section("preview_glow")
	restore_glow_settings()
	ResetGlowSection.disabled = true

func _on_reset_adjustment_section_pressed() -> void:
	reset_post_process_section("preview_adjustment")
	restore_adjustment_settings()
	ResetAdjustmentSection.disabled = true

func _on_reset_dof_section_pressed() -> void:
	reset_post_process_section("preview_dof")
	restore_dof_settings()
	ResetDofSection.disabled = true

func _on_minimum_size_changed() -> void:
	size = get_combined_minimum_size()

func _on_v_box_container_minimum_size_changed() -> void:
	$ScrollContainer.custom_minimum_size.y = min(
			$ScrollContainer/VBoxContainer.get_minimum_size().y,
			preview3D.get_rect().size.y - 64)

func _on_depth_of_field_toggled(toggled_on : bool) -> void:
	DepthOfFieldSection.visible = toggled_on
	mm_globals.set_config(SETTINGS_PREVIEW_DOF_ENABLED, toggled_on)
	if not toggled_on:
		camera_attributes.dof_blur_far_enabled = false
		camera_attributes.dof_blur_near_enabled = false
	else:
		restore_dof_settings()

func far_near_toggled(dof_type : String, toggled_on : bool) -> void:
	for control in FarNearSettings.get_children():
		if dof_type in control.name.to_lower() and control is FloatEdit:
			control.editable = toggled_on
			control.modulate = Color.WHITE if toggled_on else Color.WEB_GRAY

func _on_far_enabled_toggled(toggled_on : bool) -> void:
	camera_attributes.dof_blur_far_enabled = toggled_on
	far_near_toggled("far", toggled_on)
	mm_globals.set_config(SETTINGS_PREVIEW_DOF_FAR, toggled_on)
	setting_changed.emit(Section.DOF)

func _on_near_enabled_toggled(toggled_on : bool) -> void:
	camera_attributes.dof_blur_near_enabled = toggled_on
	far_near_toggled("near", toggled_on)
	mm_globals.set_config(SETTINGS_PREVIEW_DOF_NEAR, toggled_on)
	setting_changed.emit(Section.DOF)

func _on_blur_amount_value_changed(value : Variant) -> void:
	camera_attributes.dof_blur_amount = value
	mm_globals.set_config(SETTINGS_PREVIEW_DOF_BLUR_AMOUNT, value)
	setting_changed.emit(Section.DOF)

func _on_far_distance_value_changed(value : Variant) -> void:
	camera_attributes.dof_blur_far_distance = value
	mm_globals.set_config(SETTINGS_PREVIEW_DOF_FAR_DIST, value)
	setting_changed.emit(Section.DOF)

func _on_near_distance_value_changed(value : Variant) -> void:
	camera_attributes.dof_blur_near_distance = value
	mm_globals.set_config(SETTINGS_PREVIEW_DOF_NEAR_DIST, value)
	setting_changed.emit(Section.DOF)

func _on_far_transition_value_changed(value : Variant) -> void:
	camera_attributes.dof_blur_far_transition = value
	mm_globals.set_config(SETTINGS_PREVIEW_DOF_FAR_TRANSITION, value)
	setting_changed.emit(Section.DOF)

func _on_near_transition_value_changed(value : Variant) -> void:
	camera_attributes.dof_blur_near_transition = value
	mm_globals.set_config(SETTINGS_PREVIEW_DOF_NEAR_TRANSITION, value)
	setting_changed.emit(Section.DOF)
