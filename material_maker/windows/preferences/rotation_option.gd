extends OptionButton

export var config_variable : String

func _ready() -> void:
	add_item("Stop rotating model")
	add_item("Keep rotating model")

func init_from_config(config : ConfigFile) -> void:
	if config.has_section_key("config", config_variable):
		selected = config.get_value("config", config_variable)

func update_config(config : ConfigFile) -> void:
	config.set_value("config", config_variable, selected)
