extends MenuButton

var MP = MMCurve.Point

var presets : Array[Dictionary] = [
	{ name="Linear", curve=[MP.new(0.0, 0.0, 0.0, 1.0), MP.new(1.0, 1.0, 1.0, 0.0)] },
	{ name="EaseOut", curve=[MP.new(0.0, 0.0, 0.0, 4.0), MP.new(0.292893, 0.707107, 1.0, 1.0), MP.new(1.0, 1.0, 0.0, 0.0)] },
	{ name="EaseInOut", curve=[MP.new(0.0, 0.0, 0.0, 0.0), MP.new(0.5, 0.5, 3.0, 3.0), MP.new(1.0, 1.0, 0.0, 0.0)] },
	{ name="EaseIn", curve=[MP.new(0.0, 0.0, 0.0, 0.0), MP.new(0.707107, 0.292893, 1.0, 1.0), MP.new(1.0, 1.0, 4.0, 0.0)] },
	{ name="SawTooth", curve=[MP.new(0.0, 0.0, 0.0, 2.0), MP.new(0.5, 1.0, 2.0, -2.0), MP.new(1.0, 0.0, -2.0, 0.0)] },
	{ name="Bounce", curve=[MP.new(0.0, 0.0, 0.0, 5.0), MP.new(0.15, 0.65, 2.45201, 2.45201), MP.new(0.5, 1.0, 0.0, 0.0), MP.new(0.85, 0.65, -2.45201, -2.45201), MP.new(1.0, 0.0, -5.0, 0.0)] },
	{ name="Bevel", curve=[MP.new(0.0, 0.0, 0.0, 2.38507), MP.new(0.292893, 0.707107, 2.34362, 0.428147), MP.new(1.0, 1.0, 0.410866, 0.0)] }
] 

func _enter_tree() -> void:
	var popup : PopupMenu = get_popup()
	popup.id_pressed.connect(self._menu_item_selected)
	var current_theme : Theme = mm_globals.main_window.theme
	var path = "res://material_maker/theme/"
	if "light" in current_theme.resource_path:
		path += "light/"
	else:
		path += "dark/"
	popup.clear()
	for p in presets:
		var icon_name : String = p.name.to_lower()
		popup.add_icon_item(load(path + "curve_preset_" + icon_name + ".tres"), p.name)

func _exit_tree() -> void:
	get_popup().disconnect("id_pressed",Callable(self,"_menu_item_selected"))

func _menu_item_selected(index : int) -> void:
	var curve = MMCurve.new()
	curve.points = presets[index].curve
	get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(curve)
