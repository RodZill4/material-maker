extends Button

@export var description_type : String
var short_description : String = ""
var long_description : String = ""

signal descriptions_changed(short_description, long_description)

func _ready() -> void:
	update_tooltip()

func update_tooltip() -> void:
	if short_description == "" and long_description == "":
		tooltip_text = "Define a description for this item"
	else:
		var sd = short_description if short_description else "<short_description>"
		var ld = long_description if long_description else "<long_description>"
		tooltip_text = sd+"\n"+ld

func _on_Button_pressed() -> void:
	var dialog = preload("res://material_maker/windows/desc_dialog/desc_dialog.tscn").instantiate()
	dialog.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	dialog.min_size = Vector2(350, 150) * dialog.content_scale_factor
	add_child(dialog)
	var result = await dialog.edit_descriptions(description_type, short_description, long_description)
	short_description = result[0]
	long_description = result[1]
	update_tooltip()
	emit_signal("descriptions_changed", short_description, long_description)
