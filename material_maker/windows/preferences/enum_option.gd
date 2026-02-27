extends OptionButton

class_name EnumOption

@export var config_variable : String

func init_from_config(config : ConfigFile) -> void:
	if config.has_section_key("config", config_variable):
		selected = config.get_value("config", config_variable)
	if selected == -1:
		selected = 0

func update_config(config : ConfigFile) -> void:
	config.set_value("config", config_variable, selected)
