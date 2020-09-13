extends Button

export var description_type : String
var short_description : String = ""
var long_description : String = ""

signal descriptions_changed(short_description, long_description)

func _ready() -> void:
	update_tooltip()

func update_tooltip() -> void:
	if short_description == "" and long_description == "":
		hint_tooltip = "Define a description for this item"
	else:
		var sd = short_description if short_description else "<short_description>"
		var ld = long_description if long_description else "<long_description>"
		hint_tooltip = sd+"\n"+ld

func _on_Button_pressed() -> void:
	var dialog = preload("res://material_maker/windows/desc_dialog/desc_dialog.tscn").instance()
	add_child(dialog)
	var result = dialog.edit_descriptions(description_type, short_description, long_description)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	short_description = result[0]
	long_description = result[1]
	update_tooltip()
	emit_signal("descriptions_changed", short_description, long_description)
