class_name ThemeUtils

const LIGHT_THEME = preload("res://material_maker/theme/default light.tres")
const DARK_THEME = preload("res://material_maker/theme/default dark.tres")

const CUSTOM_RULES : Dictionary[String, Dictionary] = {
	"Main Background": { "light": -0.1, "dark": -0.5 },
	"Background": { "light": 0.3, "dark": -0.3 },
	"FloatFillHover": { "light": -0.2, "dark": 0.25, "sat": 0.5},
	"FloatFillNormal": { "light": 0.1, "dark": 0.1 },
	"AddNodePopup": { "light": -0.1, "dark": -0.3 },
	"AddNodePopupList": { "light": 0.25, "dark": -0.4 },
	"PanelMenuBackgrounds": { "light": 0.25, "dark": -0.25 },
	"Grid": { "light": -0.2, "dark": 0.25 },
	"Nodes": { "light": 0.1, "dark": -0.5 },
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
	"ScrollBarGrabberHighlight": { "light": 0.4, "dark": 0.3 },
	"ScrollBarBG": { "alpha": 0.4 },
	"Hover": { "light": -0.15, "dark": 0.1 },
	"OptionEditButtonPopup": { "light": 0.1, "dark": -0.2 },
}

static func get_base_color(base : Color, target : Color) -> Color:
	return Color.from_hsv(base.h,
			lerpf(base.s, target.s, 0.2), lerpf(base.v, target.v, 0.6), target.a)

static func process_swap_rule(i : ColorSwap, base : Color, theme_type : String) -> void:
	var rule : Dictionary = CUSTOM_RULES[i.name]

	if rule.has("light") and rule.has("dark"):
		var swap : float = rule[theme_type]
		if swap > 0.0:
			i.target = base.lightened(abs(swap))
		else:
			i.target = base.darkened(abs(swap))

	if rule.has("alpha"):
		i.target.a = rule["alpha"]
	elif rule.has("sat"):
		if base.s > 0.0:
			i.target.s *= 1.0 + rule["sat"]
	i.target = i.target.clamp()

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
		if custom_base.get_luminance() > 0.5:
			custom_base.darkened(0.2)
		return custom_base.darkened(0.1)

static func generate_custom_theme(base : Color) -> Theme:
	var is_dark : bool = true
	var theme : EnhancedTheme = DARK_THEME
	if base.get_luminance() > 0.5:
		is_dark = false
		theme = LIGHT_THEME
	var custom_theme : EnhancedTheme = theme.duplicate(true)

	for i : ColorSwap in custom_theme.theme_color_swaps:
		var base_col : Color = get_base_color(base, i.target)
		var theme_type : String = "dark" if is_dark else "light"

		if CUSTOM_RULES.has(i.name):
			process_swap_rule(i, base_col, theme_type)
		else:
			if i.name == "NodeTitleBarBG":
				if base.s > 0.0:
					i.target = Color.from_hsv(base_col.h, 0.1, base_col.v, base_col.a)
			elif i.name in ["RichTextLabel" ,"RichTextLabelDefaultColor", "PortGroup",
					"Port Preview Color", "Node Title Color"]:
				pass
			elif "CodeEdit" in i.name or "Comment" in i.name:
				pass
			else:
				i.target = base_col

	for i : ColorSwap in custom_theme.icon_color_swaps:
		var base_col : Color = get_base_color(base, i.target)
		match i.name:
			"Secondary":
				if base.s > 0.0:
					if is_dark:
						i.target = Color.from_hsv(base.h, 0.4, 0.9)
					else:
						i.target = Color.from_hsv(base.h, 0.6, 0.5)
			"Hover":
				i.target = base_col.darkened(0.2 if is_dark else 0.4)

	if is_dark:
		RenderingServer.set_default_clear_color(base.darkened(0.3))
	else:
		RenderingServer.set_default_clear_color(base.lightened(0.5))

	custom_theme.update()
	return custom_theme
	
