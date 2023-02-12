extends MenuButton

var MP = MMCurve.Point

var presets = [
	[MP.new(0.0, 0.0, 0.0, 1.0), MP.new(1.0, 1.0, 1.0, 0.0)],
	[MP.new(0.0, 0.0, 0.0, 4.0), MP.new(0.292893, 0.707107, 1.0, 1.0), MP.new(1.0, 1.0, 0.0, 0.0)],
	[MP.new(0.0, 0.0, 0.0, 0.0), MP.new(0.5, 0.5, 3.0, 3.0), MP.new(1.0, 1.0, 0.0, 0.0)],
	[MP.new(0.0, 0.0, 0.0, 0.0), MP.new(0.707107, 0.292893, 1.0, 1.0), MP.new(1.0, 1.0, 4.0, 0.0)],
	[MP.new(0.0, 0.0, 0.0, 2.0), MP.new(0.5, 1.0, 2.0, -2.0), MP.new(1.0, 0.0, -2.0, 0.0)],
	[MP.new(0.0, 0.0, 0.0, 5.0), MP.new(0.15, 0.65, 2.45201, 2.45201), MP.new(0.5, 1.0, 0.0, 0.0), MP.new(0.85, 0.65, -2.45201, -2.45201), MP.new(1.0, 0.0, -5.0, 0.0)],
	[MP.new(0.0, 0.0, 0.0, 2.38507), MP.new(0.292893, 0.707107, 2.34362, 0.428147), MP.new(1.0, 1.0, 0.410866, 0.0)]
] 

func _enter_tree() -> void:
	get_popup().connect("id_pressed",Callable(self,"_menu_item_selected"))
	var current_theme : Theme = mm_globals.main_window.theme
	var path = "res://material_maker/theme/"
	if "light" in current_theme.resource_path:
		path += "light/"
	else:
		path += "dark/"
	
	get_popup().set_item_icon(0, load(path + "curve_preset_linear.tres"))
	get_popup().set_item_icon(1, load(path + "curve_preset_easeout.tres"))
	get_popup().set_item_icon(2, load(path + "curve_preset_easeinout.tres"))
	get_popup().set_item_icon(3, load(path + "curve_preset_easein.tres"))
	get_popup().set_item_icon(4, load(path + "curve_preset_sawtooth.tres"))
	get_popup().set_item_icon(5, load(path + "curve_preset_bounce.tres"))
	get_popup().set_item_icon(6, load(path + "curve_preset_bevel.tres"))

func _exit_tree() -> void:
	get_popup().disconnect("id_pressed",Callable(self,"_menu_item_selected"))

func _menu_item_selected(index : int) -> void:
	var curve = MMCurve.new()
	curve.points = presets[index]
	get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(curve)
