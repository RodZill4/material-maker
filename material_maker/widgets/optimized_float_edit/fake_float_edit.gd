extends Control

# FloatEdit with fake controls

@onready var float_edit := get_parent().get_node("FloatEdit")

var normal_stylebox : StyleBoxFlat
var progress_fill : StyleBoxFlat

var label_settings : LabelSettings

var ci := get_canvas_item()


func _ready() -> void:
	label_settings = LabelSettings.new()
	update_theme()
	$Label.label_settings = label_settings
	$Label.text = float_edit.get_node("Edit").text


func _draw() -> void:
	normal_stylebox.draw(ci, Rect2(Vector2.ZERO, size))
	progress_fill.draw(ci, Rect2(Vector2.ZERO, Vector2(size.x * inverse_lerp(
			float_edit.get_node("Slider").min_value,
			float_edit.get_node("Slider").max_value,
			float_edit.get_node("Slider").value), size.y)))
	$Label.text = float_edit.get_node("Edit").text
	$Label.position.x = -3


func _notification(what: int) -> void:
	if not is_node_ready():
		await ready
	match what:
		NOTIFICATION_THEME_CHANGED:
			update_theme()


func update_theme() -> void:
	if "classic" in mm_globals.main_window.theme.resource_path:
		label_settings.font = preload("res://material_maker/theme/font_rubik/Rubik-Light.ttf")
		label_settings.shadow_size = 0
	else:
		label_settings.font = get_theme_font("default_font")
	label_settings.shadow_size = 1
	label_settings.font_size = get_theme_font_size("font_size")
	label_settings.font_color = get_theme_color("font_color")
	normal_stylebox = get_theme_stylebox("normal","MM_NodeFloatEdit")
	progress_fill = get_theme_stylebox("fill_normal") 
