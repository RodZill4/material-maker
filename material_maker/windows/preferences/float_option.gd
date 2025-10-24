extends "res://material_maker/widgets/float_edit/float_edit.gd"

class_name FloatOption

@export var config_variable : String

func _ready() -> void:
	pass

func init_from_config(config : ConfigFile) -> void:
	if config.has_section_key("config", config_variable):
		set_value(config.get_value("config", config_variable))

func update_config(config : ConfigFile) -> void:
	config.set_value("config", config_variable, get_value())
