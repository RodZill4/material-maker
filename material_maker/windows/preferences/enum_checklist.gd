class_name EnumChecklist
extends MenuButton

@export var config_variable : String
@export var options : PackedStringArray

@export var popup_max_height : int = 150

## Text shown on the menu button. [code]#[/code] will be replaced with
## [code]item checked/item count[/code].
## When left empty, [code]Text[/code] will be used instead.
@export var button_name : String

func _ready() -> void:
	get_popup().clear() # options variable is used instead of Items
	get_popup().hide_on_checkable_item_selection = false
	get_popup().hide_on_item_selection = false
	get_popup().search_bar_enabled = true

	for i in get_popup().item_count:
		get_popup().set_item_as_checkable(i, true)

	for e in options:
		get_popup().add_check_item(e)
	get_popup().id_pressed.connect(_id_pressed)
	get_popup().about_to_popup.connect(_about_to_popup)

func init_from_config(config : ConfigFile) -> void:
	if config.has_section_key("config", config_variable):
		var list : PackedStringArray = config.get_value("config", config_variable)
		for i in get_popup().item_count:
			if get_popup().get_item_text(i) in list:
				get_popup().set_item_checked(i, true)
		_update_count()

func update_config(config : ConfigFile) -> void:
	var list : PackedStringArray
	for i in get_popup().item_count:
		if get_popup().is_item_checked(i):
			list.append(get_popup().get_item_text(i))
	config.set_value("config", config_variable, list)

func _id_pressed(idx : int) -> void:
	get_popup().toggle_item_checked(idx)
	_update_count()

func _about_to_popup() -> void:
	get_popup().max_size.y = popup_max_height
	get_popup().shrink_width = false

func _update_count() -> void:
	if button_name == "":
		return
	var checked : int = 0
	for i in get_popup().item_count:
		if get_popup().is_item_checked(i):
			checked += 1
	text = button_name.replace(
			"#", "%s/%s" % [ checked, get_popup().item_count ])
