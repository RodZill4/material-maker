class_name ColorOption
extends ColorPickerButton

@export var config_variable : String

func _ready() -> void:
	get_popup().about_to_popup.connect(_picker_about_to_popup)

func _picker_about_to_popup() -> void:
	get_popup().content_scale_factor = get_tree().root.content_scale_factor

func init_from_config(config : ConfigFile) -> void:
	if config.has_section_key("config", config_variable):
		color = config.get_value("config", config_variable)

func update_config(config : ConfigFile) -> void:
	config.set_value("config", config_variable, color)
