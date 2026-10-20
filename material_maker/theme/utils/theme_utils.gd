class_name ThemeUtils
extends RefCounted

static var base_color : Color = Color(-1.0, -1.0, -1.0, 0.0)
static var accent : Color = Color(-1.0, -1.0, -1.0, 0.0)
static var contrast : float = -3.0

static var current_theme : int

const DEFAULT_LIGHT_THEME : EnhancedTheme = preload("res://material_maker/theme/default light.tres")
const DEFAULT_DARK_THEME : EnhancedTheme = preload("res://material_maker/theme/default dark.tres")

const SETTING_CUSTOM_BASE_COLOR : String = "custom_theme_base_color"
const SETTING_CUSTOM_ACCENT : String = "custom_theme_accent_color"
const SETTING_CUSTOM_CONTRAST : String = "custom_theme_contrast"

const INVALID_THEME : int = -1
const DARK_THEME : int = 0
const LIGHT_THEME : int = 1
const CUSTOM_THEME : int = 2
const CLASSIC_THEME : int = 3

const THEMES : PackedStringArray = ["Default Dark", "Default Light", "Custom", "Classic"]

const CUSTOM_RULES : Dictionary[String, Dictionary] = {
	"Main Background": { "light": -0.1, "dark": -0.5 },
	"Background": { "light": 0.3, "dark": -0.3 },
	"Grid": { "light": -0.1, "dark": 0.1 },
	"Nodes": { "light": 0.75, "dark": -0.8, "sat": 0.85 },
	"Elements": { "light": -0.15, "dark": -0.2 },
	"Hover": { "light": -0.15, "dark": 0.15 },
	"Tab Selected": { "light": 0.1, "dark": -0.2 },
	"Tab Unselected": { "light": -0.1, "dark": 0.2 },
	"TreeHover": { "light": -0.5, "dark": 0.3 },
	"TreeHoverSelected": { "light": 0.1, "dark": 0.1 },
	"FloatFillHover": { "light": -0.2, "dark": 0.3, "sat": 1.7 },
	"FloatFillNormal": { "light": 0.1, "dark": 0.1 },
	"AddNodePopup": { "light": 0.3, "dark": -0.6, "sat": 1.2 },
	"AddNodePopupList": { "light": 0.2, "dark": -0.5 },
	"PanelMenuBackgrounds": { "light": 0.25, "dark": -0.25 },
	"PopupMenuHover": { "light": -0.2, "dark": 0.1 },
	"ItemListHover": { "light": -0.1, "dark": 0.1 },
	"RerouteNormal": { "light": -0.25, "dark": 0.1 },
	"RerouteSelected": { "light": -0.35, "dark": -0.2 },
	"PortalLink": { "light": -0.1, "dark": -0.1 },
	"ScrollBarGrabberHighlight": { "light": 0.4, "dark": 0.3 },
	"ScrollBarBG": { "alpha": 0.2 },
	"OptionEditButtonPopup": { "light": -0.35, "dark": 0.28, "sat": 1.25 },
	"EmbedBorder": { "light": 0.15, "dark": -0.25 , "sat": 1.5 },
	"EmbedBorderUnfocus": { "light": -0.25, "dark": 0.15, "sat": 1.5 },
	"FileDialogPanel": { "light": 0.25, "dark": -0.25, "sat": 1.25 },
	"GraphEditConnectionKnife": { "light": -0.75, "dark": 0.75 },
	"GraphEditLassoStroke": { "light": -0.75, "dark": 0.75 }
}

static func set_theme(name : String) -> void:
	current_theme = THEMES.find(name.capitalize())

static func is_base_color_dark() -> bool:
	return base_color.get_luminance() < 0.5

static func is_dark_theme() -> bool:
	return current_theme == DARK_THEME or (is_custom_theme() and is_base_color_dark())

static func is_light_theme() -> bool:
	return current_theme == LIGHT_THEME or (is_custom_theme() and not is_base_color_dark())

static func is_classic_theme() -> bool:
	return current_theme == CLASSIC_THEME

static func is_custom_theme() -> bool:
	return current_theme == CUSTOM_THEME

static func get_editor_background() -> Color:
	match current_theme:
		LIGHT_THEME:
			return Color("eaeaea")
		DARK_THEME:
			return Color("0c0b0cff")
		CLASSIC_THEME:
			return Color("1e2330")
		CUSTOM_THEME:
			return _apply_color_contrast(
					is_base_color_dark(), base_color, -0.2, 0.9)
		_:
			return Color("0c0b0cff")

static func clear_custom_params() -> void:
	base_color = Color(-1.0, -1.0, -1.0, 0.0)
	accent = Color(-1.0, -1.0, -1.0, 0.0)
	contrast = -3.0

static func setup_clear_color() -> void:
	var color : Color = Color("1f1f1f")
	match current_theme:
		LIGHT_THEME:
			color = Color.WHITE
		DARK_THEME:
			color = Color("1f1f1f")
		CLASSIC_THEME:
			color = Color(0.14, 0.17,0.23)
		CUSTOM_THEME:
			color = _apply_color_contrast(
					base_color.get_luminance() < 0.5, base_color, 0.25, 0.5)
	RenderingServer.set_default_clear_color(color)

static func _get_base_color(base : Color, target : Color) -> Color:
	return Color.from_hsv(base.h, lerpf(base.s, target.s, 0.25),
			lerpf(base.v, target.v, 0.45), target.a)

static func _apply_color_contrast(is_dark : bool, base : Color,
		weight_dark : float, weight_light : float = weight_dark) -> Color:
	if is_dark:
		return base.lerp(Color.BLACK, contrast * weight_dark)
	else:
		return base.lerp(Color.WHITE, contrast * weight_light)

static func _process_swap_rules(i : ColorSwap, base : Color, theme_type : String) -> void:
	var rule : Dictionary = CUSTOM_RULES[i.name]

	if rule.has("light") and rule.has("dark"):
		var swap : float = rule[theme_type]
		i.target = _apply_color_contrast(swap < 0.0, base, abs(swap))

	if rule.has("alpha"):
		i.target.a = rule.alpha
	elif rule.has("sat"):
		if base.s > 0.0:
			i.target.s *= rule.sat
	i.target = i.target.clamp()

static func did_custom_params_change() -> bool:
	var _base : Color = mm_globals.get_config(SETTING_CUSTOM_BASE_COLOR)
	var _accent : Color = mm_globals.get_config(SETTING_CUSTOM_ACCENT)
	var _contrast : float = clampf(mm_globals.get_config(SETTING_CUSTOM_CONTRAST), -2.0, 2.0)
	return base_color != _base or accent != _accent or contrast != _contrast

static func generate_custom_theme() -> Theme:
	base_color = mm_globals.get_config(SETTING_CUSTOM_BASE_COLOR)
	accent = mm_globals.get_config(SETTING_CUSTOM_ACCENT)
	contrast = clampf(mm_globals.get_config(SETTING_CUSTOM_CONTRAST), -2.0, 2.0)

	var is_dark : bool = is_base_color_dark()
	var theme : EnhancedTheme = DEFAULT_DARK_THEME
	if not is_dark:
		theme = DEFAULT_LIGHT_THEME

	var custom_theme : EnhancedTheme = theme.duplicate(true)

	for i : ColorSwap in custom_theme.icon_color_swaps:
		if i.name in ["Hover", "Secondary"]:
			i.target = _apply_color_contrast(is_dark, accent, -0.2, 0.2)

	for i : ColorSwap in custom_theme.theme_color_swaps:
		var base_col : Color = _get_base_color(base_color, i.target)
		var theme_type : String = "dark" if is_dark else "light"

		if CUSTOM_RULES.has(i.name):
			_process_swap_rules(i, base_col, theme_type)
		else:
			if i.name == "NodeTitleBarBG":
				if base_color.s > 0.0:
					i.target = Color.from_hsv(base_col.h, 0.15, base_col.v, base_col.a)
			elif i.name == "TextSelection":
				i.target = _apply_color_contrast(is_dark, accent, -0.3, 0.3)
				i.target.a = 0.5
			elif "CodeEdit" in i.name:
				pass
			elif i.name in ["RichTextLabel", "RichTextLabelDefaultColor", "PortGroup",
					"Port Preview Color", "Node Title Color"]:
				pass
			else:
				i.target = base_col
	return custom_theme
