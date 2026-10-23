class_name FileOption
extends HBoxContainer

@export var config_variable : String
@export var file_picker_filters : PackedStringArray

func _ready() -> void:
	for f in file_picker_filters:
		$FilePickerButton.add_filter(f)
	$FilePickerButton.tooltip_text = tooltip_text

func init_from_config(config : ConfigFile) -> void:
	if config.has_section_key("config", config_variable):
		$FilePickerButton.path = config.get_value("config", config_variable)
		set_reset_button()

func update_config(config : ConfigFile) -> void:
	config.set_value("config", config_variable, $FilePickerButton.path)

func _on_reset_pressed() -> void:
	$FilePickerButton.path = ""
	set_reset_button()

func set_reset_button() -> void:
	$Reset.disabled = $FilePickerButton.path == ""
	if $FilePickerButton.path == "":
		$FilePickerButton.text = "Default"

func _on_file_picker_button_file_selected(_f : Variant) -> void:
	set_reset_button()
