var PanelControls = load("res://addons/gut/gui/panel_controls.gd")

# All titles so we can free them when we want.
var _all_titles = []


var base_container = null
# All the various PanelControls indexed by thier keys.
var controls = {}


func _init(cont):
	base_container = cont


func add_title(text):
	var row = PanelControls.BaseGutPanelControl.new(text, text)
	base_container.add_child(row)
	row.connect('draw', _on_title_cell_draw.bind(row))
	_all_titles.append(row)
	return row


func add_ctrl(key, ctrl):
	controls[key] = ctrl
	base_container.add_child(ctrl)


func add_number(key, value, disp_text, v_min, v_max, hint=''):
	var ctrl = PanelControls.NumberControl.new(disp_text, value, v_min, v_max, hint)
	add_ctrl(key, ctrl)
	return ctrl


func add_float(key, value, disp_text, step, v_min, v_max, hint=''):
	var ctrl = PanelControls.FloatControl.new(disp_text, value, step, v_min, v_max, hint)
	add_ctrl(key, ctrl)
	return ctrl


func add_select(key, value, values, disp_text, hint=''):
	var ctrl = PanelControls.SelectControl.new(disp_text, value, values, hint)
	add_ctrl(key, ctrl)
	return ctrl


func add_value(key, value, disp_text, hint=''):
	var ctrl = PanelControls.StringControl.new(disp_text, value, hint)
	add_ctrl(key, ctrl)
	return ctrl

func add_multiline_text(key, value, disp_text, hint=''):
	var ctrl = PanelControls.MultiLineStringControl.new(disp_text, value, hint)
	add_ctrl(key, ctrl)
	return ctrl

func add_boolean(key, value, disp_text, hint=''):
	var ctrl = PanelControls.BooleanControl.new(disp_text, value, hint)
	add_ctrl(key, ctrl)
	return ctrl


func add_directory(key, value, disp_text, hint=''):
	var ctrl = PanelControls.DirectoryControl.new(disp_text, value, hint)
	add_ctrl(key, ctrl)
	ctrl.dialog.title = disp_text
	return ctrl


func add_file(key, value, disp_text, hint=''):
	var ctrl = PanelControls.DirectoryControl.new(disp_text, value, hint)
	add_ctrl(key, ctrl)
	ctrl.dialog.file_mode = ctrl.dialog.FILE_MODE_OPEN_FILE
	ctrl.dialog.title = disp_text
	return ctrl


func add_save_file_anywhere(key, value, disp_text, hint=''):
	var ctrl = PanelControls.DirectoryControl.new(disp_text, value, hint)
	add_ctrl(key, ctrl)
	ctrl.dialog.file_mode = ctrl.dialog.FILE_MODE_SAVE_FILE
	ctrl.dialog.access = ctrl.dialog.ACCESS_FILESYSTEM
	ctrl.dialog.title = disp_text
	return ctrl


func add_color(key, value, disp_text, hint=''):
	var ctrl = PanelControls.ColorControl.new(disp_text, value, hint)
	add_ctrl(key, ctrl)
	return ctrl


var _blurbs = 0
func add_blurb(text):
	var ctrl = RichTextLabel.new()
	ctrl.fit_content = true
	ctrl.bbcode_enabled = true
	ctrl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ctrl.text = text
	add_ctrl(str("blurb_", _blurbs), ctrl)
	return ctrl


# ------------------
# Events
# ------------------
func _on_title_cell_draw(which):
	which.draw_rect(Rect2(Vector2(0, 0), which.size), Color(0, 0, 0, .15))


# ------------------
# Public
# ------------------

func clear():
	for key in controls:
		controls[key].free()

	controls.clear()

	for entry in _all_titles:
		entry.free()

	_all_titles.clear()
