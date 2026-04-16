class_name ThemeUtils

const LIGHT_THEME = preload("res://material_maker/theme/default light.tres")
const DARK_THEME = preload("res://material_maker/theme/default dark.tres")

const LIGHT_DARK_CUTOFF = 0.55

const CUSTOM_RULES : Dictionary[String, Dictionary] = {
	"Main Background": { "light": -0.5, "dark": -0.5 },
	"Background": { "light": -0.3, "dark": -0.3 },
	"OptionEditButtonPopup": { "light": 0.1, "dark": -0.1 },
	"FloatFillHover": { "light": -0.4, "dark": 0.3 },
	"FloatFillNormal": { "light": -0.2, "dark": 0.1 },
	"AddNodePopup": { "light": -0.1, "dark": -0.3 },
	"AddNodePopupList": { "light": -0.25, "dark": -0.4 },
	"PanelMenuBackgrounds": { "light": 0.25, "dark": -0.25 },
	"Grid": { "light": -0.4, "dark": 0.25 },
	"ScrollBarGrabberHighlight": { "light": 0.2, "dark": 0.2 },
	"Nodes": { "light": 0.1, "dark": -0.5 },
	"ScrollBarBG": { "light": 0.0, "dark": 0.0, "alpha": 0.4 },
	"Elements": { "light": -0.1, "dark": -0.15 },
	"TreeHover": { "light": 0.2, "dark": 0.2 },
	"TreeHoverSelected": { "light": 0.1, "dark": 0.1 },
	"PopupMenuHover": { "light": -0.2, "dark": 0.1 },
	"ItemListHover": { "light": 0.0, "dark": 0.1 },
	"RerouteNormal": { "light": -0.25, "dark": 0.1 },
	"RerouteSelected": { "light": -0.35, "dark": -0.2 },
	"Tab Selected": { "light": 0.1, "dark": -0.2 },
	"Tab Unselected": { "light": -0.1, "dark": 0.2 },
	"PortalLink": { "light": -0.1, "dark": -0.1 },
}

static func get_base_color(base : Color, target : Color) -> Color:
	return Color.from_hsv(base.h,
		lerpf(base.s, target.s, 0.2), lerpf(base.v, target.v, 0.6), target.a)

static func process_swap_rule(i : ColorSwap, base : Color, theme_type : String) -> void:
	var swap : float = CUSTOM_RULES[i.name][theme_type]
	if swap > 0.0:
		i.target = base.lightened(abs(swap))
	else:
		i.target = base.darkened(abs(swap))

	if CUSTOM_RULES[i.name].has("alpha"):
		i.target.a = CUSTOM_RULES[i.name]["alpha"]

static func get_editor_background() -> Color:
	var theme_path : String = mm_globals.main_window.theme.resource_path
	if "dark" in theme_path:
		return Color("0b0b0c")
	elif "classic" in theme_path:
		return Color("1e2330")
	elif "light" in theme_path:
		return Color("eaeaea")
	else:
		var custom_base : Color = mm_globals.get_config("custom_theme_base_color")
		if custom_base.get_luminance() > LIGHT_DARK_CUTOFF:
			custom_base.darkened(0.2)
		return custom_base.darkened(0.1)

static func generate_custom_theme(base : Color) -> Theme:
	var is_dark : bool = true
	var theme : EnhancedTheme = DARK_THEME
	if base.get_luminance() > LIGHT_DARK_CUTOFF:
		is_dark = false
		theme = LIGHT_THEME
	var custom_theme : EnhancedTheme = theme.duplicate(true)

	for i : ColorSwap in custom_theme.theme_color_swaps:
		var base_col : Color = get_base_color(base, i.target)
		var theme_type : String = "dark" if is_dark else "light"

		if CUSTOM_RULES.has(i.name):
			process_swap_rule(i, base_col, theme_type)
		else:
			if "CodeEdit" not in i.name and "PortGroup" not in i.name:
				i.target = base_col

	for i : ColorSwap in custom_theme.icon_color_swaps:
		var base_col : Color = get_base_color(base, i.target)
		match i.name:
			"Secondary":
				if base.s > 0.0:
					if is_dark:
						i.target = Color.from_hsv(base.h, 0.4, 0.9)
					else:
						i.target = Color.from_hsv(base.h, 0.6, 0.3)
			"Hover":
				if is_dark:
					i.target = base_col.darkened(0.2)
				else:
					i.target = base_col.darkened(0.4)

	custom_theme.update()
	return custom_theme
	
