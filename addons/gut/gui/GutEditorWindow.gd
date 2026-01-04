@tool
extends Window


var GutEditorGlobals = load('res://addons/gut/gui/editor_globals.gd')

@onready var _chk_always_on_top = $Layout/WinControls/OnTop

var _bottom_panel = null
var _ready_to_go = false
var _gut_shortcuts = []

var gut_plugin = null
var interface = null


func _unhandled_key_input(event: InputEvent) -> void:
	if(event is InputEventKey):
		if(_gut_shortcuts.has(event.as_text_keycode())):
			get_tree().root.push_input(event)


func _ready() -> void:
	var pref_size = GutEditorGlobals.user_prefs.gut_window_size.value
	if(pref_size.x < 0):
		size = Vector2(800, 800)
	else:
		size = pref_size
	always_on_top = GutEditorGlobals.user_prefs.gut_window_on_top.value
	_chk_always_on_top.button_pressed = always_on_top


# --------
# Events
# --------
func _on_on_top_toggled(toggled_on: bool) -> void:
	always_on_top = toggled_on
	GutEditorGlobals.user_prefs.gut_window_on_top.value = toggled_on


func _on_size_changed() -> void:
	if(_ready_to_go):
		GutEditorGlobals.user_prefs.gut_window_size.value = size


func _on_close_requested() -> void:
	gut_plugin.toggle_windowed()



func _on_vert_layout_pressed() -> void:
	_bottom_panel.results_vert_layout()


func _on_horiz_layout_pressed() -> void:
	_bottom_panel.results_horiz_layout()


# --------
# Public
# --------
func add_gut_panel(panel : Control):
	$Layout.add_child(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.visible = true
	_bottom_panel = panel
	_ready_to_go = true

	panel.owner = self

	# This stunk to figure out.
	theme = interface.get_editor_theme()
	var settings = interface.get_editor_settings()
	$ColorRect.color = settings.get_setting("interface/theme/base_color")

	set_gut_shortcuts(_bottom_panel._ctrls.shortcut_dialog)


func remove_panel():
	$Layout.remove_child(_bottom_panel)
	_bottom_panel.owner = null


func set_gut_shortcuts(shortcuts_dialog):
	_gut_shortcuts.clear()
	for btn in shortcuts_dialog.all_buttons:
		_gut_shortcuts.append(btn.get_input_event().as_text_keycode())
