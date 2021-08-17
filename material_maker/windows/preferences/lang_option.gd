extends OptionButton

export var config_variable : String

var locales : Array = []

func _ready() -> void:
	locales = TranslationServer.get_loaded_locales()
	locales.insert(0, "en")
	for l in locales:
		add_item(l+" - "+TranslationServer.get_locale_name(l))

func init_from_config(config : ConfigFile) -> void:
	if config.has_section_key("config", config_variable):
		selected = locales.find(config.get_value("config", config_variable))

func update_config(config : ConfigFile) -> void:
	config.set_value("config", config_variable, locales[selected])
