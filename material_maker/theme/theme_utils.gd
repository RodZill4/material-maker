class_name ThemeUtils
extends RefCounted

static var base_color : Color
static var accent : Color
static var contrast : float

static var theme_name : String

const LIGHT_THEME : EnhancedTheme = preload("res://material_maker/theme/default light.tres")
const DARK_THEME : EnhancedTheme = preload("res://material_maker/theme/default dark.tres")

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

static func get_base_color(base : Color, target : Color) -> Color:
	return Color.from_hsv(base.h, lerpf(base.s, target.s, 0.25),
			lerpf(base.v, target.v, 0.45), target.a)

static func apply_color_contrast(is_dark : bool, base : Color,
		weight_dark : float, weight_light : float = weight_dark) -> Color:
	if is_dark:
		return base.lerp(Color.BLACK, contrast * weight_dark)
	else:
		return base.lerp(Color.WHITE, contrast * weight_light)

static func process_swap_rules(i : ColorSwap, base : Color, theme_type : String) -> void:
	var rule : Dictionary = CUSTOM_RULES[i.name]

	if rule.has("light") and rule.has("dark"):
		var swap : float = rule[theme_type]
		i.target = apply_color_contrast(swap < 0.0, base, abs(swap))

	if rule.has("alpha"):
		i.target.a = rule["alpha"]
	elif rule.has("sat"):
		if base.s > 0.0:
			i.target.s *= rule["sat"]
	i.target = i.target.clamp()

static func get_editor_background() -> Color:
	match theme_name:
		"default light":
			return Color("eaeaea")
		"default dark":
			return Color("0c0b0cff")
		"classic":
			return Color("1e2330")
		_:
			var is_dark : bool = base_color.get_luminance() < 0.5
			return apply_color_contrast(is_dark, base_color, -0.2, 0.9)

static func generate_custom_theme(_base : Color, _accent : Color, _contrast : float) -> Theme:
	base_color = _base
	accent = _accent
	contrast = _contrast

	var is_dark : bool = true
	var theme : EnhancedTheme = DARK_THEME
	if base_color.get_luminance() > 0.5:
		is_dark = false
		theme = LIGHT_THEME

	var custom_theme : EnhancedTheme = theme.duplicate(true)

	for i : ColorSwap in custom_theme.icon_color_swaps:
		if i.name in ["Hover", "Secondary"]:
			i.target = apply_color_contrast(is_dark, accent, 0.2, -0.2)

	for i : ColorSwap in custom_theme.theme_color_swaps:
		var base_col : Color = get_base_color(base_color, i.target)
		var theme_type : String = "dark" if is_dark else "light"

		if CUSTOM_RULES.has(i.name):
			process_swap_rules(i, base_col, theme_type)
		else:
			if i.name == "NodeTitleBarBG":
				if base_color.s > 0.0:
					i.target = Color.from_hsv(base_col.h, 0.15, base_col.v, base_col.a)
			elif i.name == "TextSelection":
				i.target = apply_color_contrast(is_dark, accent, 0.5)
				i.target.a = 0.6
			elif "CodeEdit" in i.name:
				pass
			elif i.name in ["RichTextLabel", "RichTextLabelDefaultColor", "PortGroup",
					"Port Preview Color", "Node Title Color"]:
				pass
			else:
				i.target = base_col

	var clear_color : Color = apply_color_contrast(is_dark, base_color, 0.25, 0.5)
	RenderingServer.set_default_clear_color(clear_color)

	custom_theme.update()
	return custom_theme
